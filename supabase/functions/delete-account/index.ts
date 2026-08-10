import { createClient } from "npm:@supabase/supabase-js@2";

const jsonHeaders = {
  "Content-Type": "application/json",
};

Deno.serve(async (request) => {
  if (request.method !== "POST") {
    return Response.json(
      { error: "Method not allowed" },
      { status: 405, headers: { Allow: "POST", ...jsonHeaders } },
    );
  }

  const authorization = request.headers.get("Authorization");
  if (!authorization?.startsWith("Bearer ")) {
    return Response.json(
      { error: "Authentication required" },
      { status: 401, headers: jsonHeaders },
    );
  }

  const supabaseURL = Deno.env.get("SUPABASE_URL");
  const publishableKey =
    Deno.env.get("SUPABASE_PUBLISHABLE_KEY") ??
    Deno.env.get("SUPABASE_ANON_KEY");
  const secretKey =
    Deno.env.get("SUPABASE_SECRET_KEY") ??
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

  if (!supabaseURL || !publishableKey || !secretKey) {
    console.error("Missing required Supabase environment variables");
    return Response.json(
      { error: "Server configuration error" },
      { status: 500, headers: jsonHeaders },
    );
  }

  const callerClient = createClient(supabaseURL, publishableKey, {
    global: { headers: { Authorization: authorization } },
    auth: { persistSession: false },
  });

  const { data: { user }, error: userError } =
    await callerClient.auth.getUser();

  if (userError || !user) {
    return Response.json(
      { error: "Invalid or expired session" },
      { status: 401, headers: jsonHeaders },
    );
  }

  const adminClient = createClient(supabaseURL, secretKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  const { error: deleteError } =
    await adminClient.auth.admin.deleteUser(user.id);

  if (deleteError) {
    console.error("Failed to delete account", deleteError);
    return Response.json(
      { error: "Unable to delete account" },
      { status: 500, headers: jsonHeaders },
    );
  }

  return Response.json({ success: true }, { headers: jsonHeaders });
});
