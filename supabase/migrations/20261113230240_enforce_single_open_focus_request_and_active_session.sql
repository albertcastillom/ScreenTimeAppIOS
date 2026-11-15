-- Only one unresolved outgoing focus request may exist for a requester.
-- Completed, declined, cancelled, expired, and failed requests remain in the
-- table as history and are intentionally excluded from this constraint.
create unique index focus_requests_one_open_per_requester
on public.focus_requests (requester_id)
where status in (
  'pending'::public.focus_request_status,
  'accepted'::public.focus_request_status
);

-- A user may have many historical focus sessions, but only one session may be
-- active at a time, regardless of whether it was local or friend-approved.
create unique index focus_sessions_one_active_per_user
on public.focus_sessions (user_id)
where status = 'active'::public.focus_session_status;
