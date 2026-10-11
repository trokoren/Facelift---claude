// FACELIFT delete-account: permanently deletes the signed-in member's account
// (App Store guideline 5.1.1(v): apps that offer sign-in must offer account deletion).
//
// The caller must send her own access token (Authorization: Bearer ...). The function looks
// up who that token belongs to and deletes only that user.
//
// Uses the project's built-in SUPABASE_URL, SUPABASE_ANON_KEY and SUPABASE_SERVICE_ROLE_KEY.

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), { status, headers: { "Content-Type": "application/json" } });
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

  const del = await fetch(`${url}/auth/v1/admin/users/${user.id}`, {
    method: "DELETE",
    headers: { Authorization: `Bearer ${service}`, apikey: service },
  });
  if (!del.ok) {
    console.error("delete failed", del.status, await del.text());
    return json({ error: "We couldn't delete your account right now." }, 502);
  }
  console.log("account deleted", user.id);
  return json({ deleted: true });
});
