alter table public.profiles
add column show_on_global_leaderboard boolean not null default false;

grant update (show_on_global_leaderboard)
on table public.profiles
to authenticated;

comment on column public.profiles.show_on_global_leaderboard
is 'Whether the user has opted into appearing on the global leaderboard.';
