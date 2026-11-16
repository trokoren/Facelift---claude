// Facelift claim-web-purchase: ties a membership bought on the website to her account.
//
// The app calls this (Authorization: Bearer <her access token>) right after she signs in with
// Apple, and at launch while she's signed in without a membership. We look at the email on her
// account (as Apple shares it; a "Hide My Email" address won't match), find website purchases
// made with that email that haven't been moved yet, and move each one onto her account in RevenueCat
// with the v2 "transfer" action. Her RevenueCat app user ID is her Supabase account id (the
// app logs in to RevenueCat with it), so afterwards the membership follows her account.
//
// Secrets: REVENUECAT_SECRET_KEY (a v2 secret key with read/write on customers, subscriptions
// and purchases) and REVENUECAT_PROJECT_ID. SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY are
// built in. Deploy with verify_jwt true.

import { createClient } from "jsr:@supabase/supabase-js@2";

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), { status, headers: { "Content-Type": "application/json" } });
}

Deno.serve(async (req) => {
  if (req.method !== "POST") return json({ error: "method" }, 405);
  const token = (req.headers.get("Authorization") ?? "").replace(/^Bearer\s+/i, "");
  const db = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);
  const { data: who, error: whoError } = await db.auth.getUser(token);
  const user = who?.user;
  if (whoError || !user) return json({ error: "unauthorized" }, 401);

  const email = user.email?.trim().toLowerCase();
  if (!email || !user.email_confirmed_at) return json({ claimed: 0, reason: "no verified email" });

  const { data: rows, error } = await db.from("web_purchases").select("app_user_id")
    .eq("email", email).is("claimed_by", null);
  if (error) return json({ error: error.message }, 500);
  if (!rows?.length) return json({ claimed: 0 });

  const key = Deno.env.get("REVENUECAT_SECRET_KEY");
  const project = Deno.env.get("REVENUECAT_PROJECT_ID");
  if (!key || !project) {
    console.error("claim-web-purchase: REVENUECAT_SECRET_KEY or REVENUECAT_PROJECT_ID not set");
    return json({ claimed: 0, reason: "not set up" });
  }

  // The website customers we moved from: the app reads her web quiz answers from them.
  const from: string[] = [];
  for (const row of rows) {
    if (row.app_user_id === user.id) continue;
    const url = `https://api.revenuecat.com/v2/projects/${encodeURIComponent(project)}/customers/${encodeURIComponent(row.app_user_id)}/actions/transfer`;
    const res = await fetch(url, {
      method: "POST",
      headers: { Authorization: `Bearer ${key}`, "Content-Type": "application/json" },
      body: JSON.stringify({ target_customer_id: user.id }),
    });
    if (!res.ok) {
      console.error("transfer failed", row.app_user_id, res.status, await res.text());
      continue;
    }
    const now = new Date().toISOString();
    await db.from("web_purchases").update({ claimed_by: user.id, claimed_at: now, updated_at: now })
      .eq("app_user_id", row.app_user_id);
    // Later RevenueCat events for this trial arrive under her account id.
    await db.from("web_trials").update({ app_user_id: user.id, updated_at: now }).eq("app_user_id", row.app_user_id);
    from.push(row.app_user_id);
  }
  return json({ claimed: from.length, from });
});
