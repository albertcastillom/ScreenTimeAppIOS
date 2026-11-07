create or replace function public.mark_focus_request_activated(request_id uuid)
returns public.focus_requests
language plpgsql
security definer
set search_path = ''
as $function$
declare
    current_user_id uuid := auth.uid();
    v_activated_at timestamp with time zone := clock_timestamp();
    updated_request public.focus_requests;
begin
if current_user_id is null then
    raise exception 'Authentication required';
  end if;

  update public.focus_requests
  set
    status = 'activated'::public.focus_request_status,
    activated_at = v_activated_at,
    ends_at = v_activated_at + make_interval(mins => duration_minutes)
  where id = request_id
    and requester_id = current_user_id
    and status = 'accepted'::public.focus_request_status
  returning *
  into updated_request;

  if updated_request.id is null then
    raise exception
      'Request not found, unauthorized, or request is not accepted';
  end if;

  insert into public.focus_sessions (
    user_id,
    focus_request_id,
    source,
    status,
    activated_at,
    scheduled_ends_at
  )
  values (
    updated_request.requester_id,
    updated_request.id,
    'friend_request'::public.focus_session_source,
    'active'::public.focus_session_status,
    updated_request.activated_at,
    updated_request.ends_at
  );

  return updated_request;
end;
$function$;

revoke all
on function public.mark_focus_request_activated(uuid)
from public, anon;

grant execute
on function public.mark_focus_request_activated(uuid)
to authenticated;

comment on function public.mark_focus_request_activated(uuid)
is 'Activates an accepted focus request and creates its corresponding friend-request focus session atomically.';

insert into public.focus_sessions (
  user_id,
  focus_request_id,
  source,
  status,
  activated_at,
  scheduled_ends_at,
  ended_at
)
select
  request.requester_id,
  request.id,
  'friend_request'::public.focus_session_source,
  case
    when request.ends_at <= statement_timestamp()
      then 'completed'::public.focus_session_status
    else 'active'::public.focus_session_status
  end,
  request.activated_at,
  request.ends_at,
  case
    when request.ends_at <= statement_timestamp()
      then request.ends_at
    else null
  end
from public.focus_requests as request
where request.activated_at is not null
  and request.ends_at is not null
on conflict (focus_request_id) do nothing;