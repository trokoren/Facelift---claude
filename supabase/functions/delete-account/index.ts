// FACELIFT delete-account: permanently deletes the signed-in member's account
// (App Store guideline 5.1.1(v): apps that offer sign-in must offer account deletion).
//
// The caller must send her own access token (Authorization: Bearer ...). The function looks
// up who that token belongs to and deletes only that user.
//
// Apple also requires revoking her Sign in with Apple token. The app asks her to confirm with
// Apple first and sends the fresh authorization code as {"apple_authorization_code": "..."}.
// We trade it for a refresh token and revoke that. Revoking never blocks the delete: if the
// code is missing, the Apple key isn't set yet, or Apple says no, the account is still deleted.
//
// Uses the project's built-in SUPABASE_URL, SUPABASE_ANON_KEY and SUPABASE_SERVICE_ROLE_KEY,
// plus (for revoking) the Sign in with Apple key from the Ocean Park developer account:
// APPLE_TEAM_ID, APPLE_SIGNIN_KEY_ID and APPLE_SIGNIN_PRIVATE_KEY (the .p8 file's contents).

const APPLE_CLIENT_ID = "app.faceliftai.facelift";

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), { status, headers: { "Content-Type": "application/json" } });
}

function base64url(bytes: Uint8Array | string) {
  const raw = typeof bytes === "string" ? new TextEncoder().encode(bytes) : bytes;
  let text = "";
  for (const b of raw) text += String.fromCharCode(b);
  return btoa(text).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

/// Apple's "client secret": a short-lived token signed with our Sign in with Apple key (ES256).
async function appleClientSecret(teamId: string, keyId: string, privateKey: string) {
  const pem = privateKey.replace(/-----[^-]+-----/g, "").replace(/\s+/g, "");
  const der = Uint8Array.from(atob(pem), (c) => c.charCodeAt(0));
  const key = await crypto.subtle.importKey("pkcs8", der, { name: "ECDSA", namedCurve: "P-256" }, false, ["sign"]);
  const now = Math.floor(Date.now() / 1000);
  const header = base64url(JSON.stringify({ alg: "ES256", kid: keyId }));
  const claims = base64url(JSON.stringify({
    iss: teamId, iat: now, exp: now + 300, aud: "https://appleid.apple.com", sub: APPLE_CLIENT_ID,
  }));
  const signature = await crypto.subtle.sign(
    { name: "ECDSA", hash: "SHA-256" }, key, new TextEncoder().encode(`${header}.${claims}`),
  );
  return `${header}.${claims}.${base64url(new Uint8Array(signature))}`;
}

/// Trades her authorization code for a refresh token, then revokes it. Returns what happened,
/// for the logs only.
async function revokeApple(code: string): Promise<string> {
  const teamId = Deno.env.get("APPLE_TEAM_ID");
  const keyId = Deno.env.get("APPLE_SIGNIN_KEY_ID");
  const privateKey = Deno.env.get("APPLE_SIGNIN_PRIVATE_KEY");
  if (!teamId || !keyId || !privateKey) return "skipped: Apple key not set";

  try {
    const secret = await appleClientSecret(teamId, keyId, privateKey);
    const form = (fields: Record<string, string>) => ({
      method: "POST",
      headers: { "Content-Type": "application/x-www-form-urlencoded" },
      body: new URLSearchParams({ client_id: APPLE_CLIENT_ID, client_secret: secret, ...fields }),
    });

    const tokenRes = await fetch("https://appleid.apple.com/auth/token", form({ grant_type: "authorization_code", code }));
    const tokens = await tokenRes.json().catch(() => ({}));
    const token = tokens.refresh_token ?? tokens.access_token;
    const hint = tokens.refresh_token ? "refresh_token" : "access_token";
    if (!tokenRes.ok || !token) return `failed: token exchange ${tokenRes.status} ${tokens.error ?? ""}`;

    const revokeRes = await fetch("https://appleid.apple.com/auth/revoke", form({ token, token_type_hint: hint }));
    return revokeRes.ok ? "revoked" : `failed: revoke ${revokeRes.status}`;
  } catch (error) {
    return `failed: ${error instanceof Error ? error.message : String(error)}`;
  }
}

Deno.serve(async (req) => {
  if (req.method !== "POST") return json({ error: "Use POST" }, 405);

  const url = Deno.env.get("SUPABASE_URL");
  const anon = Deno.env.get("SUPABASE_ANON_KEY");
  const service = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!url || !anon || !service) return json({ error: "Server is not configured" }, 500);

  const auth = req.headers.get("Authorization") ?? "";
  if (!auth.startsWith("Bearer ")) return json({ error: "Not signed in" }, 401);

  // Who is asking? (Only a real signed-in user's token resolves to a user.)
  const me = await fetch(`${url}/auth/v1/user`, { headers: { Authorization: auth, apikey: anon } });
  if (!me.ok) return json({ error: "Not signed in" }, 401);
  const user = await me.json();
  if (!user?.id) return json({ error: "Not signed in" }, 401);

  // Older app versions send no body; that's fine.
  const body = await req.json().catch(() => ({}));
  const appleCode = typeof body?.apple_authorization_code === "string" ? body.apple_authorization_code : "";
  const apple = appleCode ? await revokeApple(appleCode) : "skipped: no code from the app";
  console.log("apple sign-in revoke", user.id, apple);

  const del = await fetch(`${url}/auth/v1/admin/users/${user.id}`, {
    method: "DELETE",
    headers: { Authorization: `Bearer ${service}`, apikey: service },
  });
  if (!del.ok) {
    console.error("delete failed", del.status, await del.text());
    return json({ error: "We couldn't delete your account right now." }, 502);
  }
  console.log("account deleted", user.id);
  return json({ deleted: true, apple_revoked: apple === "revoked" });
});
