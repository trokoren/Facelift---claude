// FACELIFT web quiz answers: after she pays on the website (RevenueCat Funnel) and opens her
// redemption link in the app, the app asks for the answers she gave in the web quiz so it
// can skip those questions in onboarding.
//
// The funnel saves each answer on her RevenueCat profile as a customer attribute. This reads
// only the quiz attributes below and returns them; nothing is stored here.
//
// Input: { "app_user_id": "<RevenueCat app user id after redemption>" }
// Output: { "answers": { "age_range": "...", "concerns": ["...", ...], ... } }
//
// Secrets (set in Supabase, never in the app or repo):
//   REVENUECAT_SECRET_KEY  RevenueCat v2 secret key, read-only "customer information" permission
//   REVENUECAT_PROJECT_ID  RevenueCat project id (Project settings, starts with "proj")

const SINGLE = ["age_range", "skin_type", "sensitivity", "budget", "approach"];
const MULTI = ["concerns", "feelings", "health_context"];

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), { status, headers: { "Content-Type": "application/json" } });
}

/// A multiple-choice answer may arrive as a JSON array or as comma-separated text.
function list(value: string): string[] {
  const trimmed = value.trim();
  if (trimmed.startsWith("[")) {
    try {
      const parsed = JSON.parse(trimmed);
      if (Array.isArray(parsed)) return parsed.map(String).map((s) => s.trim()).filter(Boolean);
    } catch { /* fall through */ }
  }
  return trimmed.split(",").map((s) => s.trim()).filter(Boolean);
}

Deno.serve(async (req) => {
  if (req.method !== "POST") return json({ error: "method" }, 405);
  const key = Deno.env.get("REVENUECAT_SECRET_KEY");
  const project = Deno.env.get("REVENUECAT_PROJECT_ID");
  if (!key || !project) return json({ answers: {} });

  let appUserID = "";
  try {
    appUserID = String((await req.json()).app_user_id ?? "").trim();
  } catch {
    return json({ error: "body" }, 400);
  }
  if (!appUserID || appUserID.length > 200) return json({ error: "app_user_id" }, 400);

  const url = `https://api.revenuecat.com/v2/projects/${encodeURIComponent(project)}/customers/${encodeURIComponent(appUserID)}/attributes?limit=100`;
  const res = await fetch(url, { headers: { Authorization: `Bearer ${key}` } });
  if (res.status === 404) return json({ answers: {} });
  if (!res.ok) {
    console.error("revenuecat attributes", res.status, await res.text());
    return json({ answers: {} });
  }
  const body = await res.json();
  const items: { name: string; value: string }[] = body.items ?? [];

  const answers: Record<string, string | string[]> = {};
  for (const item of items) {
    if (typeof item.value !== "string" || !item.value.trim()) continue;
    if (SINGLE.includes(item.name)) answers[item.name] = item.value.trim();
    if (MULTI.includes(item.name)) answers[item.name] = list(item.value);
  }
  return json({ answers });
});
