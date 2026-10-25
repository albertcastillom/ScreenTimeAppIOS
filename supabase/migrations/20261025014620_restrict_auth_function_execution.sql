-- Trigger-only: PostgreSQL checks EXECUTE when the trigger is created, not each
-- time it fires, so client roles do not need direct access to this function.
revoke execute on function public.handle_new_user()
from public, anon, authenticated, service_role;

-- This remains an authenticated RPC, but anonymous callers must not inherit the
-- SECURITY DEFINER function through PUBLIC or retain a direct grant.
revoke execute on function public.respond_to_friend_request(
  uuid,
  public.friendship_status
)
from public, anon;
