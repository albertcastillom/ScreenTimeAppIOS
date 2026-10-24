alter type public.focus_request_status
add value if not exists 'completed' after 'activated';

alter type public.focus_request_status
add value if not exists 'completed_early' after 'completed';

create type public.focus_session_source as enum (
  'local',
  'friend_request'
);

create type public.focus_session_status as enum (
  'active',
  'completed',
  'completed_early'
);

create table public.focus_sessions (
  id uuid not null default gen_random_uuid(),
  user_id uuid not null,
  focus_request_id uuid,
  source public.focus_session_source not null,
  status public.focus_session_status not null default 'active'::public.focus_session_status,
  activated_at timestamp with time zone not null default now(),
  scheduled_ends_at timestamp with time zone not null,
  ended_at timestamp with time zone,
  constraint focus_sessions_pkey primary key (id),
  constraint focus_sessions_user_id_fkey
    foreign key (user_id) references public.profiles(id) on delete cascade,
  constraint focus_sessions_focus_request_id_fkey
    foreign key (focus_request_id) references public.focus_requests(id) on delete set null,
  constraint focus_sessions_focus_request_id_key unique (focus_request_id),
  constraint focus_sessions_scheduled_end_after_activation_check
    check (scheduled_ends_at > activated_at),
  constraint focus_sessions_end_after_activation_check
    check (ended_at is null or ended_at > activated_at),
  constraint focus_sessions_end_no_later_than_scheduled_check
    check (ended_at is null or ended_at <= scheduled_ends_at),
  constraint focus_sessions_source_check
    check (
      source <> 'local'::public.focus_session_source
      or focus_request_id is null
    ),
  constraint focus_sessions_status_timestamps_check
    check (
      (status = 'active'::public.focus_session_status and ended_at is null)
      or
      (
        status = 'completed'::public.focus_session_status
        and ended_at = scheduled_ends_at
      )
      or
      (
        status = 'completed_early'::public.focus_session_status
        and ended_at is not null
        and ended_at < scheduled_ends_at
      )
    )
);

alter table public.focus_sessions enable row level security;

create index focus_sessions_user_activated_index
on public.focus_sessions (user_id, activated_at);

create policy "Users can view their own focus sessions"
on public.focus_sessions
for select
to authenticated
using ((select auth.uid()) = user_id);

revoke all on table public.focus_sessions from public, anon, authenticated;
grant select on table public.focus_sessions to authenticated;
grant select, insert, update, delete on table public.focus_sessions to service_role;
