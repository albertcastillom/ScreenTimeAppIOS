create or replace function public.get_friend_leaderboard(
  p_period text default 'week'
)
returns table (
  profile_id uuid,
  username text,
  total_minutes bigint,
  leaderboard_rank bigint
)
language plpgsql
stable
security definer
set search_path = ''
as $function$
declare
  current_user_id uuid := auth.uid();
  v_now timestamp with time zone := statement_timestamp();
  v_period_start timestamp with time zone;
begin
  if current_user_id is null then
    raise exception using
      errcode = '28000',
      message = 'Authentication required';
  end if;

  if p_period is null
    or p_period not in ('week', 'month', 'all_time')
  then
    raise exception using
      errcode = '22023',
      message = 'p_period must be week, month, or all_time';
  end if;

  v_period_start := case p_period
    when 'week' then
      date_trunc('week', v_now at time zone 'UTC') at time zone 'UTC'
    when 'month' then
      date_trunc('month', v_now at time zone 'UTC') at time zone 'UTC'
    when 'all_time' then
      null
  end;

  return query
  with eligible_profiles as (
    select current_user_id as profile_id

    union

    select
      case
        when friendship.requester_id = current_user_id
          then friendship.addressee_id
        else friendship.requester_id
      end as profile_id
    from public.friendships as friendship
    where friendship.status = 'accepted'::public.friendship_status
      and (
        friendship.requester_id = current_user_id
        or friendship.addressee_id = current_user_id
      )
  ),
  totals as (
    select
      eligible.profile_id,
      profile.username,
      coalesce(
        floor(
          sum(
            extract(
              epoch from (
                coalesce(session.ended_at, session.scheduled_ends_at)
                - session.activated_at
              )
            )
          ) / 60.0
        ),
        0
      )::bigint as total_minutes
    from eligible_profiles as eligible
    join public.profiles as profile
      on profile.id = eligible.profile_id
    left join public.focus_sessions as session
      on session.user_id = eligible.profile_id
      and (v_period_start is null or session.activated_at >= v_period_start)
      and coalesce(session.ended_at, session.scheduled_ends_at) <= v_now
    group by eligible.profile_id, profile.username
  ),
  ranked as (
    select
      totals.profile_id,
      totals.username,
      totals.total_minutes,
      rank() over (
        order by totals.total_minutes desc
      ) as leaderboard_rank
    from totals
  )
  select
    ranked.profile_id,
    ranked.username,
    ranked.total_minutes,
    ranked.leaderboard_rank
  from ranked
  order by
    ranked.leaderboard_rank,
    lower(ranked.username),
    ranked.profile_id;
end;
$function$;

revoke all
on function public.get_friend_leaderboard(text)
from public, anon, authenticated;

grant execute
on function public.get_friend_leaderboard(text)
to authenticated;

comment on function public.get_friend_leaderboard(text)
is 'Returns completed focus minutes and rank for the signed-in user and accepted friends for week, month, or all_time.';

create or replace function public.get_global_leaderboard(
  p_period text default 'week',
  p_limit integer default 50
)
returns table (
  profile_id uuid,
  username text,
  total_minutes bigint,
  leaderboard_rank bigint
)
language plpgsql
stable
security definer
set search_path = ''
as $function$
declare
  current_user_id uuid := auth.uid();
  v_now timestamp with time zone := statement_timestamp();
  v_period_start timestamp with time zone;
  v_limit integer;
begin
  if current_user_id is null then
    raise exception using
      errcode = '28000',
      message = 'Authentication required';
  end if;

  if p_period is null
    or p_period not in ('week', 'month', 'all_time')
  then
    raise exception using
      errcode = '22023',
      message = 'p_period must be week, month, or all_time';
  end if;

  v_period_start := case p_period
    when 'week' then
      date_trunc('week', v_now at time zone 'UTC') at time zone 'UTC'
    when 'month' then
      date_trunc('month', v_now at time zone 'UTC') at time zone 'UTC'
    when 'all_time' then
      null
  end;

  v_limit := greatest(1, least(coalesce(p_limit, 50), 100));

  return query
  with totals as (
    select
      profile.id as profile_id,
      profile.username,
      coalesce(
        floor(
          sum(
            extract(
              epoch from (
                coalesce(session.ended_at, session.scheduled_ends_at)
                - session.activated_at
              )
            )
          ) / 60.0
        ),
        0
      )::bigint as total_minutes
    from public.profiles as profile
    left join public.focus_sessions as session
      on session.user_id = profile.id
      and (v_period_start is null or session.activated_at >= v_period_start)
      and coalesce(session.ended_at, session.scheduled_ends_at) <= v_now
    where profile.show_on_global_leaderboard = true
    group by profile.id, profile.username
  ),
  ranked as (
    select
      totals.profile_id,
      totals.username,
      totals.total_minutes,
      rank() over (
        order by totals.total_minutes desc
      ) as leaderboard_rank
    from totals
    where totals.total_minutes > 0
  )
  select
    ranked.profile_id,
    ranked.username,
    ranked.total_minutes,
    ranked.leaderboard_rank
  from ranked
  order by
    ranked.leaderboard_rank,
    lower(ranked.username),
    ranked.profile_id
  limit v_limit;
end;
$function$;

revoke all
on function public.get_global_leaderboard(text, integer)
from public, anon, authenticated;

grant execute
on function public.get_global_leaderboard(text, integer)
to authenticated;

comment on function public.get_global_leaderboard(text, integer)
is 'Returns completed focus minutes and rank for opted-in profiles, with a result limit clamped from 1 through 100.';
