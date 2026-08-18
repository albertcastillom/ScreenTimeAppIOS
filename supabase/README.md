# Supabase database changes

The SQL files in `migrations/` are the source of truth for database changes. Avoid
making a lasting change only in the Supabase Dashboard: create a migration in the
same pull request as the app code that depends on it.

## Workflow

1. Scaffold a migration with `supabase migration new <descriptive_name>`.
2. Add forward-only SQL to the generated file. Prefer safe `drop ... if exists`
   followed by the desired definition when reconciling an object first created in
   the Dashboard.
3. Review RLS, grants, and every `security definer` function explicitly.
4. Test locally with `supabase db reset` when the local stack is available.
5. Link the CLI to the intended project, inspect `supabase migration list`, and run
   `supabase db push` only after reviewing the target and pending SQL.
6. Run the database advisors and verify the affected query or policy after applying.

Never commit access tokens, database passwords, service-role keys, or generated
local Supabase state.

## Focus-request lifecycle

`20260818215044_focus_request_broadcast.sql` documents the production behavior:

- Accepting a pending request sets `status = accepted` and `responded_at` through
  the approver RPC. It does not set activation timestamps.
- The acceptance transition broadcasts `UPDATE` on the private topic
  `focus_requests:<requester UUID>`.
- `realtime.messages` RLS lets an authenticated user read only the topic derived
  from their own `auth.uid()`.
- After the sender starts Screen Time restrictions locally, the activation RPC sets
  `status = activated`, `activated_at`, and `ends_at`.
- The iOS coordinator also queries accepted outgoing requests on launch and whenever
  the app returns to the foreground, so Broadcast is the fast path rather than the
  only delivery mechanism.
