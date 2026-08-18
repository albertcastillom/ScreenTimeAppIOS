-- Focus requests have two distinct server-side transitions:
--   pending -> accepted: the approver's RPC owns responded_at and emits a private
--                        Broadcast notification to the requester.
--   accepted -> activated: the requester starts blocking locally, then its RPC owns
--                          activated_at and ends_at.

-- Remove the former trigger that incorrectly treated acceptance as activation.
drop trigger if exists focus_requests_accept_timestamps_trg
on public.focus_requests;

drop function if exists public.set_focus_request_accept_timestamps();

-- Emit only the transition the requester needs. The topic is intentionally derived
-- from requester_id, and the matching realtime.messages policy below ensures that
-- only that authenticated requester can subscribe.
create or replace function public.focus_requests_broadcast_accepted()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform realtime.broadcast_changes(
    'focus_requests:' || new.requester_id::text,
    tg_op,
    tg_op,
    tg_table_name,
    tg_table_schema,
    new,
    old
  );

  return new;
end;
$$;

drop trigger if exists focus_requests_broadcast_accepted_trg
on public.focus_requests;

create trigger focus_requests_broadcast_accepted_trg
after update of status on public.focus_requests
for each row
when (old.status = 'pending' and new.status = 'accepted')
execute function public.focus_requests_broadcast_accepted();

-- The trigger invokes this function internally; clients must not call the
-- SECURITY DEFINER function directly.
revoke execute on function public.focus_requests_broadcast_accepted()
from public, anon, authenticated, service_role;

drop policy if exists requesters_can_receive_focus_request_events
on realtime.messages;

create policy requesters_can_receive_focus_request_events
on realtime.messages
for select
to authenticated
using (
  extension = 'broadcast'
  and realtime.topic() = 'focus_requests:' || (select auth.uid())::text
);

-- Preserve the RPC permission hardening applied while debugging the lifecycle.
revoke execute on function public.cancel_focus_request(uuid)
from public, anon;

grant execute on function public.cancel_focus_request(uuid)
to authenticated, service_role;
