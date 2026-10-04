// FACELIFT deep reads: the longer "Dive in" read for each concern in a consultation.
//
// Written right after her results appear, in the background, so the scan itself stays fast.
// No photo is sent here (we never keep it): it works from her measurements, the short
// "what we see" written while the photo was available, and her answers.
//
// Secret (set in Supabase): ANTHROPIC_API_KEY

const CLAUDE_MODEL = "claude-sonnet-5";

const SYSTEM = `You are the skin expert behind FACELIFT, a skincare app for women. It sits between makeup and dermatology: cosmetic care, never medical. Write like a warm, honest esthetician: specific, encouraging, never alarming. Speak to her as "you"; refer to FACELIFT as "we". Always "we" and "us", never "I" or "me".

You get one consultation's concerns (each with its measured score, 0-100 where higher is healthier, a short summary, and what we saw on her face), her skin type, all her measured scores, and her onboarding answers. Write the deeper read she opens when she taps "Dive in" on each concern. Give it real substance:
- why: 3-4 sentences on why it happens, in plain words, including the everyday habits and conditions that make it better or worse.
- todo: 3-5 sentences: the key ingredients and why each helps, when and how often to use them, the order to layer them, and one simple habit that helps.
- expect: 2-3 sentences with a realistic timeline (what she may notice around week 2, week 4 and week 6) and when to check in with a new scan.
Stay consistent with the summary and what we saw. Never invent scores or describe things on her face beyond what we saw.

How to use her answers (her_answers): they shape what you recommend; you almost never talk about them.
- Age range: quietly calibrate which ingredients fit. Never frame age negatively.
- Health context (pregnant, trying to conceive, breastfeeding, menopause and so on): apply it invisibly. If pregnant, trying to conceive or breastfeeding, simply leave out retinoids, retinol, high-strength salicylic acid and hydroquinone, and recommend gentle alternatives (azelaic acid, niacinamide, vitamin C, lactic acid, peptides) as if they were your first choice anyway. Never name these ingredients as avoided, never mention pregnancy, nursing, hormones, menopause or any phase of life, and never hint at it.
- Location: never mention her city, the weather, altitude, humidity or climate. Just let it shape your picks.
- Sun protection: never refer to her SPF habits. Mention sun protection only inside the age_spot concern, once, as one option among several. Nowhere else.
- Retinoids for everyone else: whenever you recommend retinol or any retinoid, add right after it: "Skip retinol if you're pregnant, trying to conceive or nursing." Say it as standard product guidance, never as if it's about her.
- Her routine and products: build on them silently; don't recommend something she already uses. Never recommend a product she marked irritating or stopped (product_feedback).
- Across all the reads together, at most ONE sentence may refer to anything she told us.

Rules: never diagnose or name medical conditions (no rosacea, eczema, melasma, acne vulgaris and so on). Never mention AI, models, algorithms, scans being analyzed or photos. No em dashes. Plain, warm language a friend would use.`;

const TOOL = {
  name: "deep_reads",
  description: "Record the deeper read for each concern.",
  input_schema: {
    type: "object",
    properties: {
      reads: {
        type: "array",
        items: {
          type: "object",
          properties: {
            key: { type: "string", description: "The concern's key, exactly as given." },
            why: { type: "string" },
            todo: { type: "string" },
            expect: { type: "string" },
          },
          required: ["key", "why", "todo", "expect"],
        },
      },
    },
    required: ["reads"],
  },
};

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), { status, headers: { "Content-Type": "application/json" } });
}

Deno.serve(async (req) => {
  if (req.method !== "POST") return json({ error: "Use POST" }, 405);
  const key = Deno.env.get("ANTHROPIC_API_KEY");
  if (!key) return json({ error: "Server is missing an API key" }, 500);

  let body: { concerns?: unknown[]; skinType?: string; scores?: Record<string, number>; context?: unknown };
  try {
    body = await req.json();
    if (!Array.isArray(body.concerns) || body.concerns.length === 0) throw new Error("no concerns");
  } catch {
    return json({ error: "Send { concerns, skinType, scores, context }" }, 400);
  }

  const started = Date.now();
  const res = await fetch("https://api.anthropic.com/v1/messages", {
    method: "POST",
    headers: { "x-api-key": key, "anthropic-version": "2023-06-01", "content-type": "application/json" },
    body: JSON.stringify({
      model: CLAUDE_MODEL,
      max_tokens: 3000,
      system: SYSTEM,
      tools: [TOOL],
      tool_choice: { type: "tool", name: "deep_reads" },
      messages: [{
        role: "user",
        content: JSON.stringify({
          concerns: body.concerns,
          skin_type: body.skinType ?? "",
          measured_scores: body.scores ?? {},
          her_answers: body.context ?? {},
        }),
      }],
    }),
  });
  const out = await res.json();
  if (!res.ok) {
    console.error("claude failed", res.status, JSON.stringify(out).slice(0, 500));
    return json({ error: "We couldn't write this right now." }, 502);
  }
  const use = (out?.content ?? []).find((c: { type: string }) => c.type === "tool_use");
  const reads = use?.input?.reads;
  if (!Array.isArray(reads)) return json({ error: "We couldn't write this right now." }, 502);
  console.log("deep read", JSON.stringify({ ms: Date.now() - started, usage: out.usage, count: reads.length }));
  return json({ reads });
});
