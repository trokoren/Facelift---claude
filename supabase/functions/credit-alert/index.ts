// YouCam credit alerts for Trevor, sent by email through Resend.
//
// Runs once a day from pg_cron (see migration 20261012_credit_alerts.sql). Checks the YouCam
// credit balance and emails trevor@faceliftai.app when it is running low, at most once every
// 12 hours. Send {"test": true} to get a test email with the current balance (at most one
// test every 10 minutes).
//
// Secrets (set in Supabase, never in the app or repo):
//   PERFECT_CORP_API_KEY, RESEND_API_KEY
// SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY are provided by Supabase automatically.

import { createClient } from "jsr:@supabase/supabase-js@2";

const CREDIT_URL = "https://yce-api-01.makeupar.com/s2s/v1.0/client/credit";
const FROM = "FACELIFT Alerts <alerts@faceliftai.app>";
const TO = "trevor@faceliftai.app";
/// A scan uses about 12 credits, so 240 is roughly 20 scans left.
const LOW = 240;
const CREDITS_PER_SCAN = 12;

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), { status, headers: { "Content-Type": "application/json" } });
}

/// YouCam replies with a list of credit packs: {"results":[{"amount":923,"expiry":ms}, ...]}.
/// The balance is the sum of packs that haven't expired.
function totalCredits(value: unknown): number | null {
  const packs = (value as { results?: unknown })?.results;
  if (Array.isArray(packs)) {
    const now = Date.now();
    return packs.reduce<number>((sum, pack) => {
      const p = pack as { amount?: number; expiry?: number };
      const live = typeof p.expiry !== "number" || p.expiry > now;
      return sum + (live && typeof p.amount === "number" ? p.amount : 0);
    }, 0);
  }
  return findBalance(value);
}

/// Fallback if the reply shape changes: the first number under a key that mentions credit,
/// balance or amount.
function findBalance(value: unknown): number | null {
  if (value && typeof value === "object") {
    for (const [key, inner] of Object.entries(value as Record<string, unknown>)) {
      if (/credit|balance|amount|remain/i.test(key)) {
        if (typeof inner === "number") return inner;
        if (typeof inner === "string" && inner.trim() !== "" && !isNaN(Number(inner))) return Number(inner);
      }
    }
    for (const inner of Object.values(value as Record<string, unknown>)) {
      const found = findBalance(inner);
      if (found !== null) return found;
    }
  }
  return null;
}

async function sendEmail(key: string, subject: string, text: string) {
  const res = await fetch("https://api.resend.com/emails", {
    method: "POST",
    headers: { Authorization: `Bearer ${key}`, "Content-Type": "application/json" },
    body: JSON.stringify({ from: FROM, to: [TO], subject, text }),
  });
  const body = await res.text();
  if (!res.ok) throw new Error(`Resend ${res.status}: ${body}`);
  return body;
}

Deno.serve(async (req) => {
  const youcamKey = Deno.env.get("PERFECT_CORP_API_KEY");
  const resendKey = Deno.env.get("RESEND_API_KEY");
  if (!youcamKey || !resendKey) return json({ error: "missing secrets", youcam: !!youcamKey, resend: !!resendKey }, 500);

  let test = false;
  try { test = (await req.json())?.test === true; } catch { /* no body: the daily check */ }

  const db = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);
  const kind = test ? "test" : "credits_low";
  const quiet = test ? 10 * 60 * 1000 : 12 * 60 * 60 * 1000;
  const { data: last } = await db.from("ops_alerts").select("sent_at").eq("kind", kind)
    .order("sent_at", { ascending: false }).limit(1).maybeSingle();
  const recentlySent = last && Date.now() - new Date(last.sent_at).getTime() < quiet;

  const creditRes = await fetch(CREDIT_URL, { headers: { Authorization: `Bearer ${youcamKey}` } });
  const raw = await creditRes.text();
  console.log("YouCam credit reply", creditRes.status, raw);
  let parsed: unknown = null;
  try { parsed = JSON.parse(raw); } catch { /* keep raw */ }
  const balance = totalCredits(parsed);
  const scansLeft = balance === null ? null : Math.floor(balance / CREDITS_PER_SCAN);

  const summary = balance === null
    ? `We couldn't read the balance. YouCam replied (${creditRes.status}): ${raw.slice(0, 500)}`
    : `YouCam credits: ${balance} (about ${scansLeft} scans).`;

  if (test) {
    if (recentlySent) return json({ sent: false, reason: "a test was sent in the last 10 minutes", balance });
    await sendEmail(resendKey, "FACELIFT alerts are working", `${summary}\n\nYou'll get an email here when credits drop below ${LOW} (about ${LOW / CREDITS_PER_SCAN} scans).`);
    await db.from("ops_alerts").insert({ kind, detail: summary });
    return json({ sent: true, balance });
  }

  const low = balance === null || balance < LOW;
  if (!low) return json({ sent: false, balance });
  if (recentlySent) return json({ sent: false, reason: "already alerted in the last 12 hours", balance });

  await sendEmail(
    resendKey,
    balance === null ? "FACELIFT: check YouCam credits" : `FACELIFT: YouCam credits low (${balance} left)`,
    `${summary}\n\nTop up at Perfect Corp before scans start failing.`,
  );
  await db.from("ops_alerts").insert({ kind, detail: summary });
  return json({ sent: true, balance });
});
