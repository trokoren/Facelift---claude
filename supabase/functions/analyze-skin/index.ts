// FACELIFT skin analysis.
//
// The app sends one front-facing photo (already cropped around the face). This function
// uploads it to Perfect Corp's YouCam Skin Analysis API, waits for the result, and returns
// the per-concern scores. The photo is never written anywhere by this function.
//
// Secrets (set in Supabase, never in the app or repo):
//   PERFECT_CORP_API_KEY
//
// Docs: https://docs.perfectcorp.com/reference/ai_skin_analysis

const API = "https://yce-api-01.makeupar.com/s2s/v2.0";

const SD_ACTIONS = [
  "wrinkle", "firmness", "droopy_upper_eyelid", "droopy_lower_eyelid", "tear_trough",
  "age_spot", "radiance", "redness", "dark_circle_v2", "eye_bag",
  "moisture", "oiliness", "pore", "texture", "acne", "skin_type",
];
const HD_ACTIONS = SD_ACTIONS.map((action) =>
  action === "dark_circle_v2" ? "hd_dark_circle" : `hd_${action}`
);

type Concern = { ui: number; raw: number };

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

/// Friendly messages for the errors she can fix herself.
function friendlyError(code: string): string {
  if (code.includes("face_too_small")) return "Hold your phone a little closer so your face fills the oval.";
  if (code.includes("lighting_dark")) return "It's too dark to read your skin. Face a window or lamp and try again.";
  if (code.includes("face")) return "We couldn't see your face clearly. Take glasses off, face the camera and try again.";
  return "We couldn't read that scan. Please try again in brighter, even light.";
}

/// "hd_wrinkle" -> "wrinkle", "dark_circle_v2" -> "dark_circle"
function normalize(type: string): string {
  return type.replace(/^hd_/, "").replace(/_v2$/, "");
}

Deno.serve(async (req) => {
  if (req.method !== "POST") return json({ error: "Use POST" }, 405);

  const key = Deno.env.get("PERFECT_CORP_API_KEY");
  if (!key) return json({ error: "Server is missing PERFECT_CORP_API_KEY" }, 500);
  const auth = { Authorization: `Bearer ${key}` };

  let image: string, width: number, height: number;
  try {
    ({ image, width, height } = await req.json());
    if (!image) throw new Error("missing image");
  } catch {
    return json({ error: "Send { image: base64 JPEG, width, height }" }, 400);
  }

  const bytes = Uint8Array.from(atob(image), (c) => c.charCodeAt(0));
  const hd = Math.min(width ?? 0, height ?? 0) >= 1080;

  try {
    // 1. Ask for an upload slot.
    const fileRes = await fetch(`${API}/file`, {
      method: "POST",
      headers: { ...auth, "Content-Type": "application/json" },
      body: JSON.stringify({
        files: [{ content_type: "image/jpeg", file_name: "scan.jpg", file_size: bytes.length }],
      }),
    });
    const fileJson = await fileRes.json();
    const file = fileJson?.data?.files?.[0];
    const upload = file?.requests?.[0];
    if (!file?.file_id || !upload?.url) {
      console.error("YouCam upload slot failed", JSON.stringify(fileJson));
      return json({ error: "Upload slot failed", detail: fileJson }, 502);
    }

    // 2. Upload the photo to the pre-signed URL.
    const put = await fetch(upload.url, {
      method: upload.method ?? "PUT",
      headers: upload.headers ?? { "Content-Type": "image/jpeg" },
      body: bytes,
    });
    if (!put.ok) return json({ error: "Photo upload failed", status: put.status }, 502);

    // 3. Start the analysis.
    const taskRes = await fetch(`${API}/task/skin-analysis`, {
      method: "POST",
      headers: { ...auth, "Content-Type": "application/json" },
      body: JSON.stringify({
        src_file_id: file.file_id,
        dst_actions: hd ? HD_ACTIONS : SD_ACTIONS,
        format: "json",
      }),
    });
    const taskJson = await taskRes.json();
    const taskId = taskJson?.data?.task_id;
    if (!taskId) {
      console.error("YouCam rejected task", JSON.stringify({ hd, bytes: bytes.length, width, height, response: taskJson }));
      const code = String(taskJson?.error_code ?? taskJson?.error ?? taskJson?.message ?? "");
      return json({ error: friendlyError(code), code, detail: taskJson }, 422);
    }

    // 4. Wait for the result (usually a few seconds).
    for (let attempt = 0; attempt < 45; attempt++) {
      await new Promise((r) => setTimeout(r, 1000));
      const pollRes = await fetch(`${API}/task/skin-analysis/${encodeURIComponent(taskId)}`, { headers: auth });
      const poll = await pollRes.json();
      const status = poll?.data?.task_status;

      if (status === "success") {
        const concerns: Record<string, Concern> = {};
        let overall: number | null = null;
        let skinAge: number | null = null;
        let skinType: unknown = null;

        for (const item of poll?.data?.results?.output ?? []) {
          const type = normalize(String(item.type ?? ""));
          if (type === "all") overall = Number(item.score ?? item.ui_score ?? null);
          else if (type === "skin_age") skinAge = Number(item.score ?? item.value ?? null);
          else if (type === "skin_type") skinType = item;
          else if (typeof item.ui_score === "number") {
            concerns[type] = { ui: item.ui_score, raw: Number(item.raw_score ?? item.ui_score) };
          }
        }
        return json({ mode: hd ? "hd" : "sd", overall, skinAge, skinType, concerns });
      }

      if (status === "error") {
        console.error("YouCam task failed", JSON.stringify({ hd, width, height, response: poll }));
        const code = String(poll?.data?.error ?? poll?.data?.error_message ?? poll?.error_code ?? "");
        return json({ error: friendlyError(code), code }, 422);
      }
    }
    return json({ error: "The analysis took too long. Please try again." }, 504);
  } catch (error) {
    return json({ error: "Analysis service unavailable", detail: String(error) }, 502);
  }
});
