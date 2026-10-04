// FACELIFT progress review: a short, professional follow-up on how her skin is changing
// across scans, written in the background after a scan when the app decides one is due.
//
// Input: her scan history as numbers only (dates and 0-100 scores). No photos, ever.
// The server works out every difference itself so the writer never miscounts.
//
// Secrets (set in Supabase, never in the app or repo): ANTHROPIC_API_KEY

const CLAUDE_MODEL = "claude-sonnet-5";

const AREAS: Record<string, string> = {
  wrinkle: "fine lines",
  dark_circle: "dark circles",
  age_spot: "dark spots",
  redness: "redness",
  texture: "texture",
  pore: "pores",
  moisture: "hydration",
};

type ScanIn = { date: string; overall: number; measures: Record<string, number> };

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), { status, headers: { "Content-Type": "application/json" } });
}

const DAY = 86_400_000;
const round1 = (n: number) => Math.round(n * 10) / 10;

/// Every number the writer needs, worked out here.
function facts(scans: ScanIn[], anchorIndex: number) {
  const first = scans[0];
  const latest = scans[scans.length - 1];
  const anchor = scans[Math.min(Math.max(anchorIndex, 0), scans.length - 1)];
  const days = (a: ScanIn, b: ScanIn) => round1((Date.parse(b.date) - Date.parse(a.date)) / DAY);
  const gaps = scans.slice(1).map((s, i) => days(scans[i], s)).sort((a, b) => a - b);
  const medianGap = gaps.length ? gaps[Math.floor(gaps.length / 2)] : 0;
  const recentWeek = scans.filter((s) => Date.parse(latest.date) - Date.parse(s.date) <= 7 * DAY).length;

  const areaChanges = (from: ScanIn) =>
    Object.keys(AREAS)
      .filter((k) => typeof latest.measures[k] === "number" && typeof from.measures[k] === "number")
      .map((k) => ({ area: k, name: AREAS[k], from: from.measures[k], to: latest.measures[k], change: latest.measures[k] - from.measures[k] }))
      .sort((a, b) => Math.abs(b.change) - Math.abs(a.change));

  return {
    scan_count: scans.length,
    days_tracked: days(first, latest),
    typical_days_between_scans: medianGap,
    scans_in_last_7_days: recentWeek,
    overall: { first: first.overall, at_last_review: anchor.overall, latest: latest.overall },
    days_since_last_review_scan: days(anchor, latest),
    since_first_scan: areaChanges(first),
    since_last_review: anchor === first ? null : areaChanges(anchor),
    latest_scores: latest.measures,
  };
}

const SYSTEM = `You write FACELIFT's progress review: a short follow-up on how her skin is changing, the way a seasoned esthetician or dermatologist reviews a client's progress at a follow-up visit. Precise, composed, warm but never chatty. Speak to her as "you"; refer to FACELIFT as "we". No exclamation points, no slang, no em dashes. Never mention AI, models, algorithms or photos. Cosmetic guidance only: never diagnose or name medical conditions.

You get facts worked out from her scans (0-100, higher is healthier) and why this review is being written. Use only these numbers; never invent or recompute them.

How to read change honestly:
- A change of 2 points or less in an area is normal variation: call it steady.
- Skin changes over weeks. If scans are typically less than 3 days apart, or she scanned 3 or more times in the last 7 days, say plainly that readings this close together mostly reflect day-to-day variation (sleep, hydration, light), and that scanning every 3 to 4 days shows real progress more clearly.
- Credit real gains warmly but in proportion: 5 or more points over two weeks or longer is meaningful progress. A large jump over only a few days is encouraging but needs a few more scans to confirm.
- A dip is never a failure. Name the likely everyday causes and what to keep doing.
- Never claim a product caused a change. You may say a change lines up with consistent care.
- her_context lists her skin type, the products she uses and how they are going. Build on it quietly; mention it at most once. Do not introduce new actives here: never suggest retinoids, hydroquinone or strong acids. Keep the focus on consistency, habits and what she already uses.

Why this review is being written (reason):
- first: her first review, comparing her first scan with her latest. Set expectations: early changes around week 2, clearer ones around week 6.
- five_scans: a regular check-in after several scans. If little has changed, say so calmly, note what is holding well, and encourage consistency.
- meaningful_change: something moved enough to talk about. Lead with it.
- monthly: a monthly look back across everything so far.

Write:
- title: 3 to 6 words, a calm headline (e.g. "Hydration is trending up").
- summary: 2 sentences: the overall picture, with the overall score change and the time span.
- changes: 1 to 3 areas that moved most, each with one sentence that includes the numbers. Skip areas within 2 points unless nothing moved, then use one entry for her steadiest strength.
- steady: one sentence on what is holding well.
- focus: 1 to 2 sentences on what to keep doing or adjust, at ingredient or habit level, no brand names.
- next: one sentence on when to scan next and what to watch for.`;

const TOOL = {
  name: "review",
  description: "Record her progress review.",
  input_schema: {
    type: "object",
    properties: {
      title: { type: "string" },
      summary: { type: "string" },
      changes: {
        type: "array", minItems: 1, maxItems: 3,
        items: {
          type: "object",
          properties: { area: { type: "string", enum: Object.keys(AREAS) }, note: { type: "string" } },
          required: ["area", "note"],
        },
      },
      steady: { type: "string" },
      focus: { type: "string" },
      next: { type: "string" },
    },
    required: ["title", "summary", "changes", "steady", "focus", "next"],
  },
};

Deno.serve(async (req) => {
  if (req.method !== "POST") return json({ error: "Use POST" }, 405);
  const key = Deno.env.get("ANTHROPIC_API_KEY");
  if (!key) return json({ error: "Server is missing an API key" }, 500);

  let scans: ScanIn[], anchorIndex: number, reason: string, context: unknown;
  try {
    ({ scans, anchor_index: anchorIndex = 0, reason = "five_scans", context = {} } = await req.json());
    if (!Array.isArray(scans) || scans.length < 2) throw new Error("need 2+ scans");
  } catch {
    return json({ error: "Send { scans: [{date, overall, measures}] (oldest first, 2+), anchor_index, reason }" }, 400);
  }
  const dropped = Math.max(0, scans.length - 24);
  scans = scans.slice(dropped);
  anchorIndex = Math.min(Math.max(0, anchorIndex - dropped), scans.length - 1);
  const started = Date.now();

  const res = await fetch("https://api.anthropic.com/v1/messages", {
    method: "POST",
    headers: { "x-api-key": key, "anthropic-version": "2023-06-01", "content-type": "application/json" },
    body: JSON.stringify({
      model: CLAUDE_MODEL,
      max_tokens: 1200,
      system: SYSTEM,
      tools: [TOOL],
      tool_choice: { type: "tool", name: "review" },
      messages: [{ role: "user", content: JSON.stringify({ reason, facts: facts(scans, anchorIndex), her_context: context }) }],
    }),
  });
  const body = await res.json();
  if (!res.ok) {
    console.error("claude", res.status, JSON.stringify(body));
    return json({ error: "We couldn't write your review right now." }, 502);
  }
  const use = (body?.content ?? []).find((c: { type: string }) => c.type === "tool_use");
  if (!use?.input) return json({ error: "We couldn't write your review right now." }, 502);
  console.log("review", JSON.stringify({ reason, scans: scans.length, ms: Date.now() - started, usage: body.usage }));
  return json({ review: use.input });
});
