// FACELIFT skin analysis, written as a consultation.
//
// The app sends one straight-on photo (cropped around the face) plus her onboarding answers.
// YouCam measures skin type and 7 concerns; every number she sees comes from YouCam.
// Claude reads the photo and those numbers and writes the consult: her skin type, what's
// working, what we're seeing, what to keep an eye on, and her plan. Claude writes words only.
// The photo is never written anywhere by this function.
//
// Secrets (set in Supabase, never in the app or repo):
//   PERFECT_CORP_API_KEY, ANTHROPIC_API_KEY

const YOUCAM = "https://yce-api-01.makeupar.com/s2s/v2.0";
const CLAUDE_MODEL = "claude-sonnet-5";

/// What YouCam measures (SD action names), and what each one is about.
const MEASURES: Record<string, string> = {
  wrinkle: "fine lines and wrinkles",
  dark_circle: "dark circles",
  age_spot: "dark spots and uneven pigment",
  redness: "redness",
  texture: "skin texture",
  pore: "pores",
  moisture: "hydration",
};
const ACTIONS = ["skin_type", ...Object.keys(MEASURES)];

type Concern = { ui: number; raw: number };

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), { status, headers: { "Content-Type": "application/json" } });
}

function friendlyError(code: string): string | null {
  if (code.includes("face_too_small")) return "Hold your phone a little closer so your face fills the oval.";
  if (code.includes("lighting_dark")) return "It's too dark to read your skin. Face a window or lamp and try again.";
  if (code.includes("face")) return "We couldn't see your face clearly. Take glasses off, face the camera and try again.";
  return null;
}

function normalize(type: string): string {
  return type.replace(/^hd_/, "").replace(/_v2$/, "");
}

class FaceError extends Error {}

/// Measures `actions` with YouCam. Returns scores keyed by marker.
async function youcam(key: string, bytes: Uint8Array<ArrayBuffer>, hd: boolean, actions: string[]): Promise<{ scores: Record<string, Concern>; skinType: unknown }> {
  const auth = { Authorization: `Bearer ${key}` };
  const fileRes = await fetch(`${YOUCAM}/file`, {
    method: "POST",
    headers: { ...auth, "Content-Type": "application/json" },
    body: JSON.stringify({ files: [{ content_type: "image/jpeg", file_name: "scan.jpg", file_size: bytes.length }] }),
  });
  const fileJson = await fileRes.json();
  const file = fileJson?.data?.files?.[0];
  const upload = file?.requests?.[0];
  if (!file?.file_id || !upload?.url) throw new Error(`upload slot: ${JSON.stringify(fileJson)}`);

  const put = await fetch(upload.url, {
    method: upload.method ?? "PUT",
    headers: upload.headers ?? { "Content-Type": "image/jpeg" },
    body: bytes,
  });
  if (!put.ok) throw new Error(`upload: ${put.status}`);

  const dst = actions.map((a) => (hd ? (a === "dark_circle" ? "hd_dark_circle" : `hd_${a}`) : (a === "dark_circle" ? "dark_circle_v2" : a)));
  const taskRes = await fetch(`${YOUCAM}/task/skin-analysis`, {
    method: "POST",
    headers: { ...auth, "Content-Type": "application/json" },
    body: JSON.stringify({ src_file_id: file.file_id, dst_actions: dst, format: "json" }),
  });
  const taskJson = await taskRes.json();
  const taskId = taskJson?.data?.task_id;
  if (!taskId) {
    const code = String(taskJson?.error_code ?? taskJson?.error ?? taskJson?.message ?? "");
    if (friendlyError(code)) throw new FaceError(`${code} ${JSON.stringify(taskJson)}`);
    throw new Error(`task rejected: ${JSON.stringify(taskJson)}`);
  }

  for (let attempt = 0; attempt < 45; attempt++) {
    await new Promise((r) => setTimeout(r, 1000));
    const poll = await (await fetch(`${YOUCAM}/task/skin-analysis/${encodeURIComponent(taskId)}`, { headers: auth })).json();
    const status = poll?.data?.task_status;
    if (status === "success") {
      const scores: Record<string, Concern> = {};
      let skinType: unknown = null;
      for (const item of poll?.data?.results?.output ?? []) {
        const type = normalize(String(item.type ?? ""));
        if (type === "skin_type") skinType = item;
        else if (typeof item.ui_score === "number") scores[type] = { ui: item.ui_score, raw: Number(item.raw_score ?? item.ui_score) };
      }
      return { scores, skinType };
    }
    if (status === "error") {
      const code = String(poll?.data?.error ?? poll?.data?.error_message ?? poll?.error_code ?? "");
      if (friendlyError(code)) throw new FaceError(`${code} ${JSON.stringify(poll)}`);
      throw new Error(`task failed: ${JSON.stringify(poll)}`);
    }
  }
  throw new Error("youcam timeout");
}

const SYSTEM = `You are the skin expert behind FACELIFT, a skincare app for women. It sits between makeup and dermatology: cosmetic care, never medical. Write like a warm, honest esthetician giving a five-minute consult: specific, encouraging, never alarming. Speak to her as "you"; refer to FACELIFT as "we".

You get her straight-on photo, measured scores from our skin-measurement system (0-100, higher is healthier), the system's skin-type reading, and her onboarding answers. All numbers come from the measurements; you never invent scores.

Write the consult:
- intro: 2 sentences summing up her skin today: one genuine positive, then the main focus.
- skinType: her skin type (normal, dry, oily, combination or sensitive), using the measured reading and her answers, plus 2-3 sentences on what it means for her day to day.
- strengths: 2 or 3 things that are genuinely good, based on her highest measured scores and what you see. Specific, never generic flattery.
- concerns: her 2 or 3 lowest measured areas, ranked. Each uses a measured key and gets a severity (mild, moderate or notable), a 1-2 sentence summary, and a deeper read: what we see on her face, why it happens, what to do (ingredients and how often), and what to expect over 3-6 weeks.
- watch: one gentle prevention note about something fine now that her skin type is prone to.
- plan: the one focus, then a short morning and evening routine (3-4 steps each, ingredient level, no brand names).

How to use her answers (her_answers): they shape what you recommend; you almost never talk about them. The measurements lead, like the expert in the room.
- Her stated concerns and goal are a light tiebreaker only. Never let them override what the measurements show.
- Age range: quietly calibrate what counts as good for her and which ingredients fit. Never frame age negatively and never say "your age range".
- Health context (pregnant, breastfeeding, menopause and so on): apply it invisibly. If pregnant or breastfeeding, simply leave out retinoids, retinol, high-strength salicylic acid and hydroquinone, and recommend gentle alternatives (azelaic acid, niacinamide, vitamin C, lactic acid, peptides) as if they were your first choice anyway. Never name these ingredients as avoided, never say something "isn't right for you right now" or "at the moment", never mention pregnancy, nursing, hormones, menopause or any phase of life, and never explain why an ingredient was chosen in a way that hints at it. A reader should not be able to guess her health context from the consult.
- Location: if first_consult is not true, do not mention her city, the weather, altitude, humidity, dry air or climate anywhere. Just let it shape your picks. If first_consult is true, you may name it once.
- Sun protection: never refer to her SPF habits. Check your own concerns list: if it does NOT include the age_spot key, the words sunscreen, SPF and sun protection must not appear anywhere in the consult, including the plan's morning routine, strengths and watch. If it does include age_spot, you may mention sun protection once, inside that concern's todo, as one option among several, and the morning routine may end with it.
- Her routine and products: build on them silently; don't recommend something she already uses.
- Hard limit: across the whole consult, at most ONE sentence may refer to anything she told us (age, routine, products, habits, location, goals). Everything else should simply fit her without saying why.

Rules: never diagnose or name medical conditions (no rosacea, eczema, melasma, acne vulgaris and so on; describe what's visible). Never mention AI, models, algorithms, scans being analyzed or photos. No em dashes. Plain, warm language a friend would use.`;

const TOOL = {
  name: "consult",
  description: "Record her skin consultation.",
  input_schema: {
    type: "object",
    properties: {
      face_visible: { type: "boolean", description: "False if no face is clearly visible." },
      intro: { type: "string" },
      skinType: {
        type: "object",
        properties: { label: { type: "string" }, explanation: { type: "string" } },
        required: ["label", "explanation"],
      },
      strengths: {
        type: "array", minItems: 2, maxItems: 3,
        items: {
          type: "object",
          properties: { title: { type: "string" }, detail: { type: "string" } },
          required: ["title", "detail"],
        },
      },
      concerns: {
        type: "array", minItems: 2, maxItems: 3,
        items: {
          type: "object",
          properties: {
            key: { type: "string", enum: Object.keys(MEASURES) },
            title: { type: "string" },
            severity: { type: "string", enum: ["mild", "moderate", "notable"] },
            summary: { type: "string" },
            seen: { type: "string", description: "What we see on her face." },
            why: { type: "string", description: "Why it happens." },
            todo: { type: "string", description: "What to do: ingredients and how often." },
            expect: { type: "string", description: "What to expect over 3-6 weeks." },
          },
          required: ["key", "title", "severity", "summary", "seen", "why", "todo", "expect"],
        },
      },
      watch: {
        type: "object",
        description: "An object with a short title (2-5 words) and a detail sentence or two. Not a plain string.",
        properties: { title: { type: "string" }, detail: { type: "string" } },
        required: ["title", "detail"],
      },
      plan: {
        type: "object",
        properties: {
          focus: { type: "string" },
          morning: { type: "array", items: { type: "string" } },
          evening: { type: "array", items: { type: "string" } },
        },
        required: ["focus", "morning", "evening"],
      },
    },
    required: ["face_visible", "intro", "skinType", "strengths", "concerns", "watch", "plan"],
  },
};

async function consult(key: string, image: string, scores: Record<string, Concern>, skinType: unknown, context: unknown) {
  const res = await fetch("https://api.anthropic.com/v1/messages", {
    method: "POST",
    headers: { "x-api-key": key, "anthropic-version": "2023-06-01", "content-type": "application/json" },
    body: JSON.stringify({
      model: CLAUDE_MODEL,
      max_tokens: 3000,
      system: SYSTEM,
      tools: [TOOL],
      tool_choice: { type: "tool", name: "consult" },
      messages: [{
        role: "user",
        content: [
          { type: "image", source: { type: "base64", media_type: "image/jpeg", data: image } },
          {
            type: "text",
            text: JSON.stringify({
              measured_scores: Object.fromEntries(Object.entries(scores).map(([k, v]) => [k, { area: MEASURES[k] ?? k, score: Math.round(v.ui) }])),
              measured_skin_type: skinType,
              her_answers: context,
            }),
          },
        ],
      }],
    }),
  });
  const body = await res.json();
  if (!res.ok) throw new Error(`claude ${res.status}: ${JSON.stringify(body)}`);
  const use = (body?.content ?? []).find((c: { type: string }) => c.type === "tool_use");
  if (!use?.input) throw new Error(`claude: no consult ${JSON.stringify(body)}`);
  console.log("claude usage", JSON.stringify(body.usage));
  return use.input;
}

Deno.serve(async (req) => {
  if (req.method !== "POST") return json({ error: "Use POST" }, 405);

  const youcamKey = Deno.env.get("PERFECT_CORP_API_KEY");
  const claudeKey = Deno.env.get("ANTHROPIC_API_KEY");
  if (!youcamKey || !claudeKey) return json({ error: "Server is missing an API key" }, 500);

  let image: string, width: number, height: number, context: unknown;
  try {
    ({ image, width, height, context = {} } = await req.json());
    if (!image) throw new Error("missing image");
  } catch {
    return json({ error: "Send { image: base64 JPEG, width, height, context? }" }, 400);
  }

  const bytes = Uint8Array.from(atob(image), (c) => c.charCodeAt(0));
  const hd = Math.min(width ?? 0, height ?? 0) >= 1080;
  const started = Date.now();
  console.log("request", JSON.stringify({ width, height, bytes: bytes.length }));

  // 1. YouCam measures. Every score comes from here, so if it can't read the photo we ask
  //    her to scan again instead of guessing.
  let measured: { scores: Record<string, Concern>; skinType: unknown };
  try {
    measured = await youcam(youcamKey, bytes, hd, ACTIONS);
  } catch (error) {
    console.error("YouCam failed:", String(error));
    if (error instanceof FaceError) {
      return json({ error: friendlyError(error.message) ?? "Please scan again in bright, even light." }, 422);
    }
    return json({ error: "We couldn't finish reading your scan. Please try again in a moment." }, 502);
  }
  console.log("skin type", JSON.stringify(measured.skinType));

  // 2. Claude writes the consult from the measurements, the photo and her answers.
  let written: Record<string, unknown>;
  try {
    written = await consult(claudeKey, image, measured.scores, measured.skinType, context);
  } catch (error) {
    console.error("Claude failed:", String(error));
    return json({ error: "We couldn't finish reading your scan. Please try again." }, 502);
  }
  if (written.face_visible === false) {
    return json({ error: "We couldn't see your face clearly. Face the camera in bright, even light and try again." }, 422);
  }
  delete written.face_visible;

  // Shape only (no text), to spot missing or odd fields from the writer.
  const shape = (v: unknown): unknown =>
    Array.isArray(v) ? v.map(shape) : v && typeof v === "object"
      ? Object.fromEntries(Object.entries(v as Record<string, unknown>).map(([k, x]) => [k, shape(x)]))
      : typeof v;
  console.log("consult shape", JSON.stringify(shape(written)));

  console.log("scan", JSON.stringify({ hd, width, height, ms: Date.now() - started, measured: Object.keys(measured.scores).length }));

  return json({
    mode: "consult",
    resolution: hd ? "hd" : "sd",
    concerns: measured.scores,
    sources: Object.fromEntries(Object.keys(measured.scores).map((k) => [k, "youcam"])),
    consult: written,
  });
});
