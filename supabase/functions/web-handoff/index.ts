// Facelift web-handoff: unlocks the app automatically for someone who just paid on the website.
//
// 1. GET  ?u=<website customer id>  (the "Get Facelift" button on the funnel's thank-you page,
//    URL token {{app_user_id}}). Notes that customer id with her connection (IP) and iOS
//    version, then sends her to the App Store.
// 2. POST {"app_user_id": "...", "ios_version": "18.1"}  (the app, on first open while she
//    isn't a member). Looks for a handoff from the same connection in the last 2 hours whose
//    customer really bought on the website and hasn't been moved yet. If exactly one fits, it
//    moves that purchase onto the app's RevenueCat customer (v2 "transfer" action) and answers
//    {"matched": true, "from": "<website customer id>"}. Anything less certain: no match, and
//    she uses Sign in with Apple or the link in her purchase email instead.
//
// Why it can miss: she changed networks between paying and opening the app, or Safari's
// iCloud Private Relay hid her connection. Then nothing happens and the backups apply.
//
// Secrets: REVENUECAT_SECRET_KEY (v2, read/write on customers, subscriptions, purchases) and
// REVENUECAT_PROJECT_ID. SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY are built in.
// Deploy with verify_jwt FALSE: the browser link carries no login token.

import { createClient } from "jsr:@supabase/supabase-js@2";

// Until the App Store listing is live (FAC-196), the website.
const APP_STORE_URL = "https://faceliftai.app";
const WINDOW_MS = 2 * 60 * 60 * 1000;

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), { status, headers: { "Content-Type": "application/json" } });
}

function clientIP(req: Request): string | null {
  const forwarded = req.headers.get("x-forwarded-for")?.split(",")[0]?.trim();
  return forwarded || req.headers.get("cf-connecting-ip") || req.headers.get("x-real-ip") || null;
}

/// "Mozilla/5.0 (iPhone; CPU iPhone OS 18_1 like Mac OS X) ..." -> "18.1"
function iosVersion(userAgent: string | null): string | null {
  const match = userAgent?.match(/OS (\d+)[_.](\d+)/);
  return match ? `${match[1]}.${match[2]}` : null;
}

Deno.serve(async (req) => {
  const db = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);
  const ip = clientIP(req);

  // 1. Thank-you page button.
  if (req.method === "GET") {
    const u = new URL(req.url).searchParams.get("u")?.trim() ?? "";
    // Unfilled token or junk: still send her to the App Store.
    if (ip && u && !u.includes("{{") && u.length < 200) {
      const { error } = await db.from("web_handoffs").insert({
        web_app_user_id: u, ip, ios_version: iosVersion(req.headers.get("user-agent")),
      });
      if (error) console.error("handoff insert", error.message);
    }
    return new Response(null, { status: 302, headers: { Location: APP_STORE_URL } });
  }
  if (req.method !== "POST") return json({ error: "method" }, 405);

  // 2. The app's first open.
  let appUserID = "";
  let appIOS: string | null = null;
  try {
    const body = await req.json();
    appUserID = String(body.app_user_id ?? "").trim();
    appIOS = typeof body.ios_version === "string" ? body.ios_version : null;
  } catch { /* handled below */ }
  if (!appUserID || !ip) return json({ matched: false });

  const since = new Date(Date.now() - WINDOW_MS).toISOString();
  const { data: handoffs } = await db.from("web_handoffs").select("id, web_app_user_id, ios_version")
    .eq("ip", ip).is("matched_at", null).gt("created_at", since).order("created_at", { ascending: false });
  const ids = [...new Set((handoffs ?? [])
    .filter((h) => !appIOS || !h.ios_version || h.ios_version === appIOS)
    .map((h) => h.web_app_user_id))];
  if (!ids.length) return json({ matched: false });

  // Only real, unmoved website purchases.
  const { data: purchases } = await db.from("web_purchases").select("app_user_id")
    .in("app_user_id", ids).is("claimed_by", null);
  if (purchases?.length !== 1) {
    if ((purchases?.length ?? 0) > 1) console.warn("handoff: more than one purchase on one connection, not guessing", ip);
    return json({ matched: false });
  }
  const from = purchases[0].app_user_id;
  if (from === appUserID) return json({ matched: false });

  const key = Deno.env.get("REVENUECAT_SECRET_KEY");
  const project = Deno.env.get("REVENUECAT_PROJECT_ID");
  if (!key || !project) {
    console.error("web-handoff: REVENUECAT_SECRET_KEY or REVENUECAT_PROJECT_ID not set");
    return json({ matched: false });
  }
  const res = await fetch(
    `https://api.revenuecat.com/v2/projects/${encodeURIComponent(project)}/customers/${encodeURIComponent(from)}/actions/transfer`,
    {
      method: "POST",
      headers: { Authorization: `Bearer ${key}`, "Content-Type": "application/json" },
      body: JSON.stringify({ target_customer_id: appUserID }),
    },
  );
  if (!res.ok) {
    console.error("handoff transfer failed", from, res.status, await res.text());
    return json({ matched: false });
  }

  const now = new Date().toISOString();
  await db.from("web_purchases").update({ claimed_by: appUserID, claimed_at: now, updated_at: now }).eq("app_user_id", from);
  await db.from("web_handoffs").update({ matched_at: now, matched_to: appUserID }).eq("web_app_user_id", from);
  // Later RevenueCat events for this trial arrive under the app's customer id.
  await db.from("web_trials").update({ app_user_id: appUserID, updated_at: now }).eq("app_user_id", from);
  return json({ matched: true, from });
});
