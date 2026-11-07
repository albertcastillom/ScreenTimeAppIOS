create or replace function public.reconcile_elapsed_focus_sessions()
returns integer
language plpgsql
security definer
set search_path = ''
as $function$
declare
  current_user_id uuid := auth.uid();
  v_reconciled_at timestamp with time zone := clock_timestamp();
  v_focus_request_ids uuid[];
  v_completed_count integer;
begin
  if current_user_id is null then
    raise exception 'Authentication required';
  end if;

  with completed_sessions as (
    update public.focus_sessions as session
    set
      ended_at = session.scheduled_ends_at,
      status = 'completed'::public.focus_session_status
    where session.user_id = current_user_id
      and session.status = 'active'::public.focus_session_status
      and session.scheduled_ends_at <= v_reconciled_at
    returning session.focus_request_id
  )
  select
    coalesce(
      array_agg(completed_sessions.focus_request_id)
        filter (where completed_sessions.focus_request_id is not null),
      array[]::uuid[]
    ),
    count(*)::integer
  into v_focus_request_ids, v_completed_count
  from completed_sessions;

  update public.focus_requests as request
  set status = 'completed'::public.focus_request_status
  where request.id = any(v_focus_request_ids)
    and request.requester_id = current_user_id
    and request.status = 'activated'::public.focus_request_status;

  return v_completed_count;
end;
$function$;

revoke all
on function public.reconcile_elapsed_focus_sessions()
from public, anon;

grant execute
on function public.reconcile_elapsed_focus_sessions()
to authenticated;

comment on function public.reconcile_elapsed_focus_sessions()
is 'Completes all naturally elapsed focus sessions owned by the caller and marks linked activated focus requests completed.';

create or replace function public.reconcile_elapsed_focus_session(
  session_id uuid
)
returns public.focus_sessions
language plpgsql
security definer
set search_path = ''
as $function$
declare
  current_user_id uuid := auth.uid();
  reconciled_session public.focus_sessions;
begin
  if current_user_id is null then
    raise exception 'Authentication required';
  end if;

  update public.focus_sessions as session
  set
    ended_at = session.scheduled_ends_at,
    status = 'completed'::public.focus_session_status
  where session.id = session_id
    and session.user_id = current_user_id
    and session.status = 'active'::public.focus_session_status
    and session.scheduled_ends_at <= clock_timestamp()
  returning * into reconciled_session;

  if reconciled_session.id is null then
    select session.*
    into reconciled_session
    from public.focus_sessions as session
    where session.id = session_id
      and session.user_id = current_user_id;
  end if;

  if reconciled_session.id is null then
    raise exception 'Session not found or unauthorized';
  end if;

  if reconciled_session.status = 'completed'::public.focus_session_status
    and reconciled_session.focus_request_id is not null
  then
    update public.focus_requests as request
    set status = 'completed'::public.focus_request_status
    where request.id = reconciled_session.focus_request_id
      and request.requester_id = current_user_id
      and request.status = 'activated'::public.focus_request_status;
  end if;

  return reconciled_session;
end;
$function$;

revoke all
on function public.reconcile_elapsed_focus_session(uuid)
from public, anon;

grant execute
on function public.reconcile_elapsed_focus_session(uuid)
to authenticated;

comment on function public.reconcile_elapsed_focus_session(uuid)
is 'Reconciles one naturally elapsed focus session and marks its linked activated focus request completed.';
