// FACELIFT skin analysis: YouCam measures, Claude explains.
//
// The app sends one straight-on photo (cropped around the face) plus a little context from
// onboarding. Depending on `mode`:
//   "claude"  - Claude rates all 14 markers and writes the insights.
//   "hybrid4" - YouCam measures 4 markers, Claude rates the rest and writes the insights.
//   "hybrid6" - YouCam measures 6 markers, Claude rates the rest and writes the insights.
// The photo is never written anywhere by this function.
//
// Secrets (set in Supabase, never in the app or repo):
//   PERFECT_CORP_API_KEY, ANTHROPIC_API_KEY

const YOUCAM = "https://yce-api-01.makeupar.com/s2s/v2.0";
const CLAUDE_MODEL = "claude-sonnet-5";

/// Every marker the app shows, and what "worse" looks like for each one.
const MARKERS: Record<string, string> = {
  wrinkle: "fine lines and wrinkles (forehead, crow's feet, smile lines)",
  firmness: "loss of firmness or elasticity (sagging along the jaw and cheeks)",
  eye_lift: "drooping of the upper or lower eyelids",
  tear_trough: "under-eye hollows (tear trough depth and shadowing)",
  age_spot: "dark spots (sun spots, post-acne marks, uneven pigment)",
  radiance: "dullness (lack of glow, tired-looking skin)",
  redness: "redness (flushing, irritation, visible capillaries)",
  dark_circle: "dark circles under the eyes",
  eye_bag: "puffiness or bags under the eyes",
  moisture: "dehydration (tight, flaky or dull-dry looking skin)",
  oiliness: "excess oil or shine (T-zone, visible sebum)",
  pore: "visible or enlarged pores and congestion",
  texture: "uneven texture (roughness, bumps)",
  acne: "active breakouts or blemishes",
};

/// Which markers YouCam measures in each mode. SD action names.
const YOUCAM_SETS: Record<string, string[]> = {
  claude: [],
  hybrid4: ["wrinkle", "pore", "texture", "age_spot"],
  hybrid6: ["wrinkle", "pore", "texture", "age_spot", "redness", "acne"],
};

/// Claude's 4 levels -> score (higher is healthier). Levels are far more repeatable than 0-100.
const LEVEL_SCORE: Record<string, number> = { none: 92, mild: 80, moderate: 66, noticeable: 52 };

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
async function youcam(key: string, bytes: Uint8Array, hd: boolean, actions: string[]): Promise<Record<string, Concern>> {
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
      const out: Record<string, Concern> = {};
      for (const item of poll?.data?.results?.output ?? []) {
        const type = normalize(String(item.type ?? ""));
        if (typeof item.ui_score === "number") out[type] = { ui: item.ui_score, raw: Number(item.raw_score ?? item.ui_score) };
      }
      return out;
    }
    if (status === "error") {
      const code = String(poll?.data?.error ?? poll?.data?.error_message ?? poll?.error_code ?? "");
      if (friendlyError(code)) throw new FaceError(`${code} ${JSON.stringify(poll)}`);
      throw new Error(`task failed: ${JSON.stringify(poll)}`);
    }
  }
  throw new Error("youcam timeout");
}

type ClaudeResult = {
  ratings: Record<string, string>;
  insights: { aging: string; tone: string; health: string };
  face_visible: boolean;
};

async function claude(
  key: string,
  image: string,
  toRate: string[],
  measured: Record<string, Concern>,
  context: Record<string, unknown>,
): Promise<ClaudeResult> {
  const ratingProps: Record<string, unknown> = {};
  for (const marker of toRate) {
    ratingProps[marker] = {
      type: "string",
      enum: ["none", "mild", "moderate", "noticeable"],
      description: `How much ${MARKERS[marker]} is visible.`,
    };
  }

  const tool = {
    name: "skin_report",
    description: "Record the skin read for this photo.",
    input_schema: {
      type: "object",
      properties: {
        face_visible: {
          type: "boolean",
          description: "False if no face is clearly visible (too dark, blurry, covered, turned away).",
        },
        ratings: { type: "object", properties: ratingProps, required: toRate },
        insights: {
          type: "object",
          properties: {
            aging: { type: "string", description: "Aging & Structure card: wrinkles, firmness, eye lift, under-eye hollows." },
            tone: { type: "string", description: "Tone & Clarity card: dark spots, radiance, redness, dark circles, puffiness." },
            health: { type: "string", description: "Skin Health card: hydration, oil, pores, texture, breakouts." },
          },
          required: ["aging", "tone", "health"],
        },
      },
      required: ["face_visible", "ratings", "insights"],
    },
  };

  const system = `You are the skin expert inside FACELIFT, a skincare app for women. It sits between makeup and dermatology: cosmetic care, never medical.

You get one straight-on face photo, any scores already measured by our skin-measurement system (0-100, higher is healthier), and a few answers from her onboarding.

1. Rate each requested marker by how visible that concern is in the photo: none, mild, moderate or noticeable. Judge only what you can see. Be consistent and conservative: when between two levels, pick the milder one unless it's clearly visible. Ignore makeup, lighting color casts and camera noise where you can.
2. Write one insight per card, 3 to 4 sentences, speaking to her as "you". Warm, honest and specific, like a knowledgeable friend. Name her strongest area and the one to focus on, and give one or two concrete, ingredient-level steps (for example retinol, vitamin C, SPF, niacinamide, hyaluronic acid, BHA). Use the measured scores and your ratings together.

Rules: never diagnose or name medical conditions (no rosacea, eczema, melasma, etc.; describe what's visible instead). Never mention AI, models, algorithms or photos being analyzed. No em dashes. Hydration can't be seen directly: combine what the skin looks like with her answers. If no face is clearly visible, set face_visible to false.`;

  const res = await fetch("https://api.anthropic.com/v1/messages", {
    method: "POST",
    headers: {
      "x-api-key": key,
      "anthropic-version": "2023-06-01",
      "content-type": "application/json",
    },
    body: JSON.stringify({
      model: CLAUDE_MODEL,
      max_tokens: 1500,
      temperature: 0,
      system,
      tools: [tool],
      tool_choice: { type: "tool", name: "skin_report" },
      messages: [{
        role: "user",
        content: [
          { type: "image", source: { type: "base64", media_type: "image/jpeg", data: image } },
          {
            type: "text",
            text: JSON.stringify({
              markers_to_rate: Object.fromEntries(toRate.map((m) => [m, MARKERS[m]])),
              measured_scores: Object.fromEntries(Object.entries(measured).map(([k, v]) => [k, Math.round(v.ui)])),
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
  if (!use?.input) throw new Error(`claude: no report ${JSON.stringify(body)}`);
  console.log("claude usage", JSON.stringify(body.usage));
  return use.input as ClaudeResult;
}

Deno.serve(async (req) => {
  if (req.method !== "POST") return json({ error: "Use POST" }, 405);

  const youcamKey = Deno.env.get("PERFECT_CORP_API_KEY") ?? "";
  const claudeKey = Deno.env.get("ANTHROPIC_API_KEY");
  if (!claudeKey) return json({ error: "Server is missing ANTHROPIC_API_KEY" }, 500);

  let image: string, width: number, height: number, mode: string, context: Record<string, unknown>;
  try {
    ({ image, width, height, mode = "hybrid6", context = {} } = await req.json());
    if (!image) throw new Error("missing image");
  } catch {
    return json({ error: "Send { image: base64 JPEG, width, height, mode?, context? }" }, 400);
  }
  if (!(mode in YOUCAM_SETS)) mode = "hybrid6";

  const bytes = Uint8Array.from(atob(image), (c) => c.charCodeAt(0));
  const hd = Math.min(width ?? 0, height ?? 0) >= 1080;
  const started = Date.now();
  console.log("request", JSON.stringify({ mode, width, height, bytes: bytes.length }));

  // 1. YouCam measures its markers. If it can't run (for example out of units), Claude
  //    covers everything so the scan still works.
  let measured: Record<string, Concern> = {};
  let youcamError: string | undefined;
  const wanted = YOUCAM_SETS[mode];
  if (wanted.length > 0) {
    try {
      if (!youcamKey) throw new Error("missing PERFECT_CORP_API_KEY");
      measured = await youcam(youcamKey, bytes, hd, wanted);
    } catch (error) {
      // Whatever YouCam's reason (out of units, or a photo it won't accept), Claude still
      // reads the scan. Claude reports back if there's truly no usable face.
      youcamError = error instanceof FaceError ? `photo rejected: ${error.message}` : String(error);
      console.error("YouCam unavailable, Claude covers all markers:", youcamError);
    }
  }

  // 2. Claude rates everything YouCam didn't measure and writes the insights.
  const toRate = Object.keys(MARKERS).filter((m) => !(m in measured));
  let read: ClaudeResult;
  try {
    read = await claude(claudeKey, image, toRate, measured, context);
  } catch (error) {
    console.error("Claude failed:", String(error));
    return json({ error: "We couldn't finish reading your scan. Please try again." }, 502);
  }
  if (read.face_visible === false) {
    console.error("Claude: no clear face");
    return json({ error: "We couldn't see your face clearly. Face the camera in bright, even light and try again." }, 422);
  }

  const concerns: Record<string, Concern> = { ...measured };
  const sources: Record<string, string> = Object.fromEntries(Object.keys(measured).map((k) => [k, "youcam"]));
  for (const marker of toRate) {
    const level = read.ratings?.[marker];
    const score = LEVEL_SCORE[level ?? ""];
    if (score !== undefined) {
      concerns[marker] = { ui: score, raw: score };
      sources[marker] = "claude";
    }
  }

  console.log("scan", JSON.stringify({
    mode, hd, width, height, ms: Date.now() - started,
    youcam: Object.keys(measured).length, claude: toRate.length, youcamError: youcamError ? "yes" : "no",
  }));

  return json({
    mode,
    resolution: hd ? "hd" : "sd",
    youcamError,
    concerns,
    sources,
    insights: read.insights,
  });
});
