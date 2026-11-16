// FACELIFT trial-ending reminder for members who started the free trial on the website.
//
// RevenueCat only emails "your trial is ending" for trials longer than a month, and our trial
// is 3 days. The web paywall promises "We'll remind you before it ends", so this sends that
// reminder by email through Resend, about 24 hours before the trial turns into a paid year.
// (Members who install the app also get the app's own reminder.)
//
// Two ways in:
//  1. RevenueCat webhook (POST, Authorization header = REVENUECAT_WEBHOOK_AUTH). Saves every
//     web purchase in public.web_purchases (for claim-web-purchase), and each
//     web trial (store RC_BILLING, period_type TRIAL) in public.web_trials, and marks it
//     canceled / converted / expired as later events arrive.
//  2. Hourly pg_cron call with {"send": true} (see migration 20261115_web_trial_reminders.sql).
//     Emails every saved trial that ends within the next 26 hours, isn't canceled, and
//     hasn't been reminded yet.
//
// Her email: RevenueCat's checkout asks for it. We read the $email attribute from the
// webhook, or from RevenueCat's API if the webhook doesn't carry it. Not yet confirmed with a
// real sandbox purchase: if neither has it, the trial is saved without an email and logged.
//
// Secrets (set in Supabase, never in the app or repo):
//   RESEND_API_KEY, REVENUECAT_WEBHOOK_AUTH (the same value typed into RevenueCat's webhook
//   "Authorization header" box), REVENUECAT_SECRET_KEY, REVENUECAT_PROJECT_ID.
// SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY are provided by Supabase automatically.
//
// Deploy with verify_jwt FALSE (unlike our other functions): RevenueCat can't send a Supabase
// login token, so the webhook is checked against REVENUECAT_WEBHOOK_AUTH instead. The hourly
// "send" call needs no secret because it can only send reminders that are due and unsent.

import { createClient } from "jsr:@supabase/supabase-js@2";

const FROM = "Facelift <hello@faceliftai.app>";
const REPLY_TO = "trevor@faceliftai.app";
const WINDOW_MS = 26 * 60 * 60 * 1000;

type Attr = { value?: string };
type RCEvent = {
  type?: string;
  id?: string;
  app_user_id?: string;
  original_app_user_id?: string;
  store?: string;
  period_type?: string;
  environment?: string;
  product_id?: string;
  expiration_at_ms?: number | null;
  price?: number | null;
  currency?: string | null;
  subscriber_attributes?: Record<string, Attr>;
};

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), { status, headers: { "Content-Type": "application/json" } });
}

/// $email from RevenueCat's customer attributes, when the webhook didn't include it.
async function lookupEmail(appUserID: string): Promise<string | null> {
  const key = Deno.env.get("REVENUECAT_SECRET_KEY");
  const project = Deno.env.get("REVENUECAT_PROJECT_ID");
  if (!key || !project) return null;
  const url = `https://api.revenuecat.com/v2/projects/${encodeURIComponent(project)}/customers/${encodeURIComponent(appUserID)}/attributes?limit=100`;
  const res = await fetch(url, { headers: { Authorization: `Bearer ${key}` } });
  if (!res.ok) {
    console.error("revenuecat attributes", res.status, await res.text());
    return null;
  }
  const body = await res.json();
  const item = (body.items ?? []).find((i: { name?: string }) => i.name === "$email");
  return typeof item?.value === "string" && item.value.includes("@") ? item.value.trim() : null;
}

function price(amount: number | null, currency: string | null): string {
  if (typeof amount !== "number" || amount <= 0) return "$49.99";
  try {
    return new Intl.NumberFormat("en-US", { style: "currency", currency: currency || "USD" }).format(amount);
  } catch {
    return `$${amount.toFixed(2)}`;
  }
}

function reminderText(ends: Date, amount: string): string {
  const day = ends.toLocaleDateString("en-US", { weekday: "long", month: "long", day: "numeric", timeZone: "America/Denver" });
  return [
    "Hello,",
    "",
    `Your free Facelift trial ends tomorrow, ${day}. Your membership will then continue at ${amount} for the year, billed to the card you added.`,
    "",
    "If you would like to keep going, there is nothing to do. If not, you can cancel any time before then from the \"Manage subscription\" link in your Facelift purchase email. You will not be charged.",
    "",
    "Trevor, Founder of Facelift",
  ].join("\n");
}

async function sendEmail(key: string, to: string, subject: string, text: string) {
  const res = await fetch("https://api.resend.com/emails", {
    method: "POST",
    headers: { Authorization: `Bearer ${key}`, "Content-Type": "application/json" },
    body: JSON.stringify({ from: FROM, to: [to], reply_to: REPLY_TO, subject, text }),
  });
  const body = await res.text();
  if (!res.ok) throw new Error(`Resend ${res.status}: ${body}`);
}

Deno.serve(async (req) => {
  if (req.method !== "POST") return json({ error: "method" }, 405);
  const db = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);

  let body: { send?: boolean; event?: RCEvent } = {};
  try { body = await req.json(); } catch { return json({ error: "body" }, 400); }

  // Hourly job: send due reminders.
  if (body.send === true) {
    const resendKey = Deno.env.get("RESEND_API_KEY");
    if (!resendKey) return json({ error: "missing RESEND_API_KEY" }, 500);
    const now = Date.now();
    const { data: due, error } = await db.from("web_trials")
      .select("app_user_id, email, trial_ends_at, price, currency")
      .eq("status", "trial").is("reminded_at", null).not("email", "is", null)
      .gt("trial_ends_at", new Date(now).toISOString())
      .lte("trial_ends_at", new Date(now + WINDOW_MS).toISOString());
    if (error) return json({ error: error.message }, 500);
    let sent = 0;
    for (const row of due ?? []) {
      try {
        await sendEmail(resendKey, row.email, "Your Facelift trial ends tomorrow",
          reminderText(new Date(row.trial_ends_at), price(row.price, row.currency)));
        await db.from("web_trials").update({ reminded_at: new Date().toISOString() }).eq("app_user_id", row.app_user_id);
        sent++;
      } catch (e) {
        console.error("reminder failed", row.app_user_id, String(e));
      }
    }
    return json({ due: due?.length ?? 0, sent });
  }

  // RevenueCat webhook.
  const auth = Deno.env.get("REVENUECAT_WEBHOOK_AUTH");
  if (!auth || req.headers.get("Authorization") !== auth) return json({ error: "unauthorized" }, 401);
  const event = body.event;
  if (!event?.type || !event.app_user_id) return json({ ok: true, ignored: "no event" });
  if (event.store !== "RC_BILLING") return json({ ok: true, ignored: "not a web purchase" });
  const id = event.original_app_user_id || event.app_user_id;

  switch (event.type) {
    case "INITIAL_PURCHASE": {
      let email = event.subscriber_attributes?.["$email"]?.value?.trim() || null;
      if (!email) email = await lookupEmail(event.app_user_id);
      if (!email) console.warn("web purchase without an email", id);
      // Every web purchase, so claim-web-purchase can move it onto her account when she
      // signs in to the app with the same email.
      const saved = await db.from("web_purchases").upsert({
        app_user_id: id,
        email: email?.toLowerCase() ?? null,
        product_id: event.product_id ?? null,
        period_type: event.period_type ?? null,
        environment: event.environment ?? null,
        updated_at: new Date().toISOString(),
      });
      if (saved.error) console.error("web_purchases", saved.error.message);
      if (event.period_type !== "TRIAL" || !event.expiration_at_ms) return json({ ok: true, ignored: "not a trial" });
      const { error } = await db.from("web_trials").upsert({
        app_user_id: id,
        email,
        product_id: event.product_id ?? null,
        environment: event.environment ?? null,
        trial_ends_at: new Date(event.expiration_at_ms).toISOString(),
        price: event.price ?? null,
        currency: event.currency ?? null,
        status: "trial",
        reminded_at: null,
        updated_at: new Date().toISOString(),
      });
      if (error) return json({ error: error.message }, 500);
      return json({ ok: true, saved: true, email: !!email });
    }
    case "CANCELLATION":
    case "EXPIRATION":
    case "RENEWAL":
    case "UNCANCELLATION": {
      const status = event.type === "CANCELLATION" ? "canceled"
        : event.type === "EXPIRATION" ? "expired"
        : event.type === "RENEWAL" ? "converted" : "trial";
      await db.from("web_trials").update({ status, updated_at: new Date().toISOString() }).eq("app_user_id", id);
      return json({ ok: true, status });
    }
    default:
      return json({ ok: true, ignored: event.type });
  }
});
