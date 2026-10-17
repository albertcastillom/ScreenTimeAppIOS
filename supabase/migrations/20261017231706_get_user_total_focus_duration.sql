create or replace function public.get_user_total_focus_duration(
    target_user_id uuid
)
returns bigint
language plpgsql
stable
security definer
set search_path = ''
as $function$ 
declare
    caller_user_id uuid := auth.uid();
begin 
    if caller_user_id is null then
        raise exception 'Authentication Required';
    end if;

    if target_user_id is null then
        raise exception 'Target user is required';
    end if;

    -- The caller may view their own total or an accepted friend's total.
    if target_user_id <> caller_user_id
        and not exists (
        select 1
        from public.friendships as friendship
        where friendship.status = 'accepted'::public.friendship_status
            and (
            (
                friendship.requester_id = caller_user_id
                and friendship.addressee_id = target_user_id
            )
            or
            (
                friendship.addressee_id = caller_user_id
                and friendship.requester_id = target_user_id
            )
            )
        )
    then
        raise exception 'Not authorized to view this user''s focus duration';
    end if;

    return (
        select coalesce(sum(request.duration_minutes), 0)::bigint
        from public.focus_requests as request
        where request.requester_id = target_user_id
        and request.status = 'activated'::public.focus_request_status
    );
end;
$function$;

    revoke all
        on function public.get_user_total_focus_duration(uuid)
        from public, anon;

    grant execute
        on function public.get_user_total_focus_duration(uuid)
        to authenticated;

    comment on function public.get_user_total_focus_duration(uuid)
    is 'Returns total activated focus-session minutes for the signed-in user or one of their accepted friends.';

    create index if not exists focus_requests_activated_requester_index
    on public.focus_requests (requester_id)
    where status = 'activated'::public.focus_request_status;