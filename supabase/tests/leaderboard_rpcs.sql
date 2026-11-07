begin;

insert into auth.users (id, raw_user_meta_data)
values
  (
    '11111111-1111-1111-1111-111111111111',
    '{"username":"CurrentUser"}'::jsonb
  ),
  (
    '22222222-2222-2222-2222-222222222222',
    '{"username":"AcceptedFriend"}'::jsonb
  ),
  (
    '33333333-3333-3333-3333-333333333333',
    '{"username":"PrivateUser"}'::jsonb
  ),
  (
    '44444444-4444-4444-4444-444444444444',
    '{"username":"GlobalStranger"}'::jsonb
  );

update public.profiles
set show_on_global_leaderboard = id in (
  '11111111-1111-1111-1111-111111111111',
  '22222222-2222-2222-2222-222222222222',
  '44444444-4444-4444-4444-444444444444'
);

insert into public.friendships (requester_id, addressee_id, status, responded_at)
values (
  '11111111-1111-1111-1111-111111111111',
  '22222222-2222-2222-2222-222222222222',
  'accepted',
  now()
);

insert into public.focus_sessions (
  user_id,
  source,
  status,
  activated_at,
  scheduled_ends_at,
  ended_at
)
values
  (
    '11111111-1111-1111-1111-111111111111',
    'local',
    'completed',
    now() - interval '150 minutes',
    now() - interval '120 minutes',
    now() - interval '120 minutes'
  ),
  (
    '22222222-2222-2222-2222-222222222222',
    'local',
    'completed',
    now() - interval '165 minutes',
    now() - interval '120 minutes',
    now() - interval '120 minutes'
  ),
  (
    '33333333-3333-3333-3333-333333333333',
    'local',
    'completed',
    now() - interval '180 minutes',
    now() - interval '120 minutes',
    now() - interval '120 minutes'
  ),
  (
    '44444444-4444-4444-4444-444444444444',
    'local',
    'completed',
    now() - interval '140 minutes',
    now() - interval '120 minutes',
    now() - interval '120 minutes'
  ),
  (
    '11111111-1111-1111-1111-111111111111',
    'local',
    'active',
    now() - interval '10 minutes',
    now() + interval '110 minutes',
    null
  ),
  (
    '11111111-1111-1111-1111-111111111111',
    'local',
    'completed',
    now() - interval '60 days 10 minutes',
    now() - interval '60 days',
    now() - interval '60 days'
  );

do $test$
begin
  if has_function_privilege('anon', 'public.get_friend_leaderboard(text)', 'execute') then
    raise exception 'anon must not be able to execute get_friend_leaderboard';
  end if;

  if has_function_privilege('anon', 'public.get_global_leaderboard(text, integer)', 'execute') then
    raise exception 'anon must not be able to execute get_global_leaderboard';
  end if;

  if not has_function_privilege(
    'authenticated',
    'public.get_friend_leaderboard(text)',
    'execute'
  ) then
    raise exception 'authenticated must be able to execute get_friend_leaderboard';
  end if;

  if not has_function_privilege(
    'authenticated',
    'public.get_global_leaderboard(text, integer)',
    'execute'
  ) then
    raise exception 'authenticated must be able to execute get_global_leaderboard';
  end if;

  if exists (
    select 1
    from pg_proc
    join pg_namespace on pg_namespace.oid = pg_proc.pronamespace
    where pg_namespace.nspname = 'public'
      and pg_proc.proname in ('get_friend_leaderboard', 'get_global_leaderboard')
      and not ('search_path=""' = any(coalesce(pg_proc.proconfig, array[]::text[])))
  ) then
    raise exception 'leaderboard RPC search_path must be empty';
  end if;
end;
$test$;

set local role authenticated;
select set_config(
  'request.jwt.claim.sub',
  '11111111-1111-1111-1111-111111111111',
  true
);

do $test$
declare
  friend_rows jsonb;
  global_rows jsonb;
begin
  select jsonb_agg(to_jsonb(result) order by result.leaderboard_rank)
  into friend_rows
  from public.get_friend_leaderboard('week') as result;

  if friend_rows <> jsonb_build_array(
    jsonb_build_object(
      'profile_id', '22222222-2222-2222-2222-222222222222',
      'username', 'AcceptedFriend',
      'total_minutes', 45,
      'leaderboard_rank', 1
    ),
    jsonb_build_object(
      'profile_id', '11111111-1111-1111-1111-111111111111',
      'username', 'CurrentUser',
      'total_minutes', 30,
      'leaderboard_rank', 2
    )
  ) then
    raise exception 'unexpected friend leaderboard: %', friend_rows;
  end if;

  select jsonb_agg(to_jsonb(result) order by result.leaderboard_rank)
  into global_rows
  from public.get_global_leaderboard('week', 1000) as result;

  if global_rows <> jsonb_build_array(
    jsonb_build_object(
      'profile_id', '22222222-2222-2222-2222-222222222222',
      'username', 'AcceptedFriend',
      'total_minutes', 45,
      'leaderboard_rank', 1
    ),
    jsonb_build_object(
      'profile_id', '11111111-1111-1111-1111-111111111111',
      'username', 'CurrentUser',
      'total_minutes', 30,
      'leaderboard_rank', 2
    ),
    jsonb_build_object(
      'profile_id', '44444444-4444-4444-4444-444444444444',
      'username', 'GlobalStranger',
      'total_minutes', 20,
      'leaderboard_rank', 3
    )
  ) then
    raise exception 'unexpected global leaderboard: %', global_rows;
  end if;

  if (select count(*) from public.get_global_leaderboard('week', 0)) <> 1 then
    raise exception 'global limit must clamp values below 1 to 1';
  end if;

  if (
    select total_minutes
    from public.get_friend_leaderboard('all_time')
    where profile_id = '11111111-1111-1111-1111-111111111111'
  ) <> 40 then
    raise exception 'all_time must include the older completed session';
  end if;

  begin
    perform public.get_friend_leaderboard('year');
    raise exception 'invalid p_period was accepted';
  exception
    when sqlstate '22023' then
      null;
  end;
end;
$test$;

reset role;
select set_config('request.jwt.claim.sub', '', true);

do $test$
begin
  begin
    perform public.get_friend_leaderboard('week');
    raise exception 'unauthenticated call was accepted';
  exception
    when sqlstate '28000' then
      null;
  end;
end;
$test$;

select 'leaderboard RPC local tests passed' as result;

rollback;
