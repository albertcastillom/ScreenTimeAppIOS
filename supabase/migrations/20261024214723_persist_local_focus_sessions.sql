create or replace function public.start_local_focus_session (
  duration_minutes integer
)
returns public.focus_sessions
language plpgsql
security definer
set search_path = ''
as $function$
declare
  current_user_id uuid := auth.uid();
  v_activated_at timestamp with time zone := clock_timestamp();
  new_session public.focus_sessions;
begin
  if current_user_id is null then
    raise exception 'Authentication required';
  end if;

  if duration_minutes is null or duration_minutes < 1 or duration_minutes > 1440 then
    raise exception 'Duration must be between 1 and 1440 minutes';
  end if;

  insert into public.focus_sessions (
    user_id,
    source,
    status,
    activated_at,
    scheduled_ends_at
  )
  values (
    current_user_id,
    'local'::public.focus_session_source,
    'active'::public.focus_session_status,
    v_activated_at,
    v_activated_at + make_interval(mins => duration_minutes)
  )
  returning * into new_session;

  return new_session;
end;
$function$;

revoke all on function public.start_local_focus_session(integer)
from public, anon, authenticated;
grant execute on function public.start_local_focus_session(integer)
to authenticated;

create or replace function public.end_focus_session_early (
  session_id uuid
)
returns public.focus_sessions
language plpgsql
security definer
set search_path = ''
as $function$
declare
  current_user_id uuid := auth.uid();
  v_ended_at timestamp with time zone := clock_timestamp();
  updated_session public.focus_sessions;
begin
  if current_user_id is null then
    raise exception 'Authentication required';
  end if;

  update public.focus_sessions
  set
    ended_at = v_ended_at,
    status = 'completed_early'::public.focus_session_status
  where id = session_id
    and user_id = current_user_id
    and status = 'active'::public.focus_session_status
    and scheduled_ends_at > v_ended_at
  returning * into updated_session;

  if updated_session.id is null then
    raise exception
      'Session not found, unauthorized, already completed, or no longer active';
  end if;

  return updated_session;
end;
$function$;

revoke all on function public.end_focus_session_early(uuid)
from public, anon, authenticated;
grant execute on function public.end_focus_session_early(uuid)
to authenticated;

create or replace function public.reconcile_elapsed_focus_session (
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

  update public.focus_sessions
  set
    ended_at = scheduled_ends_at,
    status = 'completed'::public.focus_session_status
  where id = session_id
    and user_id = current_user_id
    and status = 'active'::public.focus_session_status
    and scheduled_ends_at <= clock_timestamp()
  returning * into reconciled_session;

  if reconciled_session.id is null then
    select *
    into reconciled_session
    from public.focus_sessions
    where id = session_id
      and user_id = current_user_id;
  end if;

  if reconciled_session.id is null then
    raise exception 'Session not found or unauthorized';
  end if;

  return reconciled_session;
end;
$function$;

revoke all on function public.reconcile_elapsed_focus_session(uuid)
from public, anon, authenticated;
grant execute on function public.reconcile_elapsed_focus_session(uuid)
to authenticated;
