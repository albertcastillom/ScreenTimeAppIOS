SET local check_function_bodies = off;

CREATE TABLE "public"."focus_requests" (
  "id"               uuid                     NOT NULL DEFAULT gen_random_uuid(),
  "requester_id"     uuid                     NOT NULL,
  "approver_id"      uuid                     NOT NULL,
  "duration_minutes" integer                  NOT NULL,
  "created_at"       timestamp with time zone NOT NULL DEFAULT now(),
  "responded_at"     timestamp with time zone,
  "activated_at"     timestamp with time zone,
  "ends_at"          timestamp with time zone,
  CONSTRAINT "focus_requests_duration_check" CHECK (((duration_minutes >= 1) AND (duration_minutes <= 1440))),
  CONSTRAINT "focus_requests_ends_after_activation" CHECK (((ends_at IS NULL) OR (activated_at IS NULL) OR (ends_at > activated_at))),
  CONSTRAINT "focus_requests_no_self_request" CHECK ((requester_id <> approver_id)),
  CONSTRAINT "focus_requests_pkey" PRIMARY KEY (id)
);

ALTER TABLE "public"."focus_requests"
  ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON TABLE "public"."focus_requests" FROM "anon";

CREATE TABLE "public"."friendships" (
  "id"           uuid                     NOT NULL DEFAULT gen_random_uuid(),
  "requester_id" uuid                     NOT NULL,
  "addressee_id" uuid                     NOT NULL,
  "created_at"   timestamp with time zone NOT NULL DEFAULT now(),
  "responded_at" timestamp with time zone,
  CONSTRAINT "friendships_no_self_request" CHECK ((requester_id <> addressee_id)),
  CONSTRAINT "friendships_pkey" PRIMARY KEY (id)
);

ALTER TABLE "public"."friendships"
  ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON TABLE "public"."friendships" FROM "anon";

CREATE TABLE "public"."profiles" (
  "id"         uuid                     NOT NULL,
  "username"   text                     NOT NULL,
  "created_at" timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT "profiles_pkey" PRIMARY KEY (id),
  CONSTRAINT "username_format_check" CHECK ((username ~ '^[A-Za-z0-9_]+$'::text)),
  CONSTRAINT "username_length_check" CHECK (((char_length(username) >= 3) AND (char_length(username) <= 30)))
);

ALTER TABLE "public"."profiles"
  ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON TABLE "public"."profiles" FROM "anon";

CREATE TYPE "public"."focus_request_status" AS ENUM (
  'pending',
  'accepted',
  'declined',
  'activated',
  'expired',
  'cancelled',
  'failed'
);

ALTER TABLE "public"."focus_requests"
  ADD COLUMN "status" public.focus_request_status NOT NULL DEFAULT 'pending'::public.focus_request_status;

CREATE TYPE "public"."friendship_statuses" AS ENUM (
  'pending',
  'accepted',
  'declined',
  'blocked'
);

CREATE TYPE "public"."friendship_status" AS ENUM (
  'pending',
  'accepted',
  'declined',
  'blocked'
);

ALTER TABLE "public"."friendships"
  ADD COLUMN "status" public.friendship_status NOT NULL DEFAULT 'pending'::public.friendship_status;

CREATE OR REPLACE FUNCTION public.accept_focus_request (
  request_id uuid
)
  RETURNS public.focus_requests
  LANGUAGE plpgsql
  SECURITY DEFINER
  SET search_path TO ''
  AS $function$
declare
  current_user_id uuid;
  updated_request public.focus_requests;
begin
  current_user_id := auth.uid();

  if current_user_id is null then
    raise exception 'Authentication required';
  end if;

  update public.focus_requests
  set
    status = 'accepted',
    responded_at = now()
  where id = request_id
    and approver_id = current_user_id
    and status = 'pending'
  returning *
  into updated_request;

  if updated_request.id is null then
    raise exception
      'Request not found, you are not the approver, or request is no longer pending';
  end if;

  return updated_request;
end;
$function$;

REVOKE ALL ON FUNCTION "public"."accept_focus_request"(uuid) FROM PUBLIC, "anon";

CREATE OR REPLACE FUNCTION public.cancel_focus_request (
  request_id uuid
)
  RETURNS public.focus_requests
  LANGUAGE plpgsql
  SECURITY DEFINER
  SET search_path TO ''
  AS $function$
declare
  updated_request public.focus_requests;
begin
  if auth.uid() is null then
    raise exception 'Authentication required';
  end if;

  update public.focus_requests
  set status = 'cancelled'
  where id = request_id
    and requester_id = auth.uid()
    and status = 'pending'
  returning *
  into updated_request;

  if updated_request.id is null then
    raise exception
      'Request not found, unauthorized, or no longer pending';
  end if;

  return updated_request;
end;
$function$;

REVOKE ALL ON FUNCTION "public"."cancel_focus_request"(uuid) FROM PUBLIC, "anon";

CREATE OR REPLACE FUNCTION public.decline_focus_request (
  request_id uuid
)
  RETURNS public.focus_requests
  LANGUAGE plpgsql
  SECURITY DEFINER
  SET search_path TO ''
  AS $function$
declare
  current_user_id uuid;
  updated_request public.focus_requests;
begin
  current_user_id := auth.uid();

  if current_user_id is null then
    raise exception 'Authentication required';
  end if;

  update public.focus_requests
  set
    status = 'declined',
    responded_at = now()
  where id = request_id
    and approver_id = current_user_id
    and status = 'pending'
  returning *
  into updated_request;

  if updated_request.id is null then
    raise exception
      'Request not found, you are not the approver, or request is no longer pending';
  end if;

  return updated_request;
end;
$function$;

REVOKE ALL ON FUNCTION "public"."decline_focus_request"(uuid) FROM PUBLIC, "anon";

CREATE OR REPLACE FUNCTION public.focus_requests_broadcast_accepted()
  RETURNS TRIGGER
  LANGUAGE plpgsql
  SECURITY DEFINER
  SET search_path TO ''
  AS $function$
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
$function$;

REVOKE ALL ON FUNCTION "public"."focus_requests_broadcast_accepted"() FROM PUBLIC, "anon", "authenticated", "service_role";

CREATE OR REPLACE FUNCTION public.handle_new_user()
  RETURNS TRIGGER
  LANGUAGE plpgsql
  SECURITY DEFINER
  SET search_path TO ''
  AS $function$
declare
  requested_username text;
begin
  requested_username := trim(new.raw_user_meta_data ->> 'username');

  if requested_username is null or requested_username = '' then
    raise exception 'Username is required';
  end if;

  insert into public.profiles (id, username)
  values (new.id, requested_username);

  return new;
end;
$function$;

CREATE OR REPLACE FUNCTION public.mark_focus_request_activated (
  request_id uuid
)
  RETURNS public.focus_requests
  LANGUAGE plpgsql
  SECURITY DEFINER
  SET search_path TO ''
  AS $function$
declare
  current_user_id uuid;
  updated_request public.focus_requests;
begin
  current_user_id := auth.uid();

  if current_user_id is null then
    raise exception 'Authentication required';
  end if;

  update public.focus_requests
  set
    status = 'activated',
    activated_at = now(),
    ends_at = now() + make_interval(mins => duration_minutes)
  where id = request_id
    and requester_id = current_user_id
    and status = 'accepted'
  returning *
  into updated_request;

  if updated_request.id is null then
    raise exception
      'Request not found, you are not the requester, or request is not accepted';
  end if;

  return updated_request;
end;
$function$;

REVOKE ALL ON FUNCTION "public"."mark_focus_request_activated"(uuid) FROM PUBLIC, "anon";

CREATE OR REPLACE FUNCTION public.respond_to_friend_request (
  request_id uuid,
  new_status public.friendship_status
)
  RETURNS public.friendships
  LANGUAGE plpgsql
  SECURITY DEFINER
  SET search_path TO ''
  AS $function$
declare
  updated_friendship public.friendships;
begin
  if auth.uid() is null then
    raise exception 'Authentication required';
  end if;

  if new_status not in (
    'accepted'::public.friendship_status,
    'declined'::public.friendship_status,
    'blocked'::public.friendship_status
  ) then
    raise exception 'Invalid response status';
  end if;

  update public.friendships
  set status = new_status
  where id = request_id
    and addressee_id = auth.uid()
    and status = 'pending'
  returning *
  into updated_friendship;

  if updated_friendship.id is null then
    raise exception
      'Request not found, unauthorized, or no longer pending';
  end if;

  return updated_friendship;
end;
$function$;

CREATE OR REPLACE FUNCTION public.set_friendship_responded_at()
  RETURNS TRIGGER
  LANGUAGE plpgsql
  SET search_path TO ''
  AS $function$
begin
  if old.status <> new.status then
    if old.status <> 'pending' then
      raise exception 'Only pending friendship requests can be answered';
    end if;

    if new.status not in (
      'accepted'::public.friendship_status,
      'declined'::public.friendship_status,
      'blocked'::public.friendship_status
    ) then
      raise exception 'Invalid friendship status transition';
    end if;

    new.responded_at := now();
  end if;

  return new;
end;
$function$;

ALTER TABLE "public"."profiles"
  ADD CONSTRAINT "profiles_id_fkey" FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE CASCADE;

ALTER TABLE "public"."focus_requests"
  ADD CONSTRAINT "focus_requests_approver_id_fkey" FOREIGN KEY (approver_id) REFERENCES public.profiles(id) ON DELETE CASCADE;

ALTER TABLE "public"."focus_requests"
  ADD CONSTRAINT "focus_requests_requester_id_fkey" FOREIGN KEY (requester_id) REFERENCES public.profiles(id) ON DELETE CASCADE;

ALTER TABLE "public"."friendships"
  ADD CONSTRAINT "friendships_addressee_id_fkey" FOREIGN KEY (addressee_id) REFERENCES public.profiles(id) ON DELETE CASCADE;

ALTER TABLE "public"."friendships"
  ADD CONSTRAINT "friendships_requester_id_fkey" FOREIGN KEY (requester_id) REFERENCES public.profiles(id) ON DELETE CASCADE;

CREATE INDEX focus_requests_approver_index ON public.focus_requests USING btree (approver_id);

CREATE INDEX focus_requests_pending_approver_index ON public.focus_requests USING btree (approver_id, created_at DESC)
  WHERE (status = 'pending'::public.focus_request_status);

CREATE INDEX focus_requests_requester_index ON public.focus_requests USING btree (requester_id);

CREATE INDEX focus_requests_status_index ON public.focus_requests USING btree (status);

CREATE INDEX friendships_addressee_index ON public.friendships USING btree (addressee_id);

CREATE INDEX friendships_requester_index ON public.friendships USING btree (requester_id);

CREATE INDEX friendships_status_index ON public.friendships USING btree (status);

CREATE UNIQUE INDEX friendships_unique_active_relationship ON public.friendships USING btree (LEAST(requester_id, addressee_id), GREATEST(requester_id, addressee_id))
  WHERE (status = ANY (ARRAY['pending'::public.friendship_status, 'accepted'::public.friendship_status]));

CREATE UNIQUE INDEX profiles_username_unique_ci ON public.profiles USING btree (lower(username));

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

CREATE TRIGGER focus_requests_broadcast_accepted_trg
  AFTER UPDATE OF status ON public.focus_requests
  FOR EACH ROW
  WHEN (((old.status = 'pending'::public.focus_request_status) AND (new.status = 'accepted'::public.focus_request_status)))
  EXECUTE FUNCTION public.focus_requests_broadcast_accepted();

CREATE TRIGGER set_friendship_responded_at_trigger
  BEFORE UPDATE ON public.friendships
  FOR EACH ROW
  EXECUTE FUNCTION public.set_friendship_responded_at();

CREATE POLICY "Participants can view focus requests" ON "public"."focus_requests"
  FOR SELECT
  TO "authenticated"
  USING (((requester_id = ( SELECT auth.uid() AS uid)) OR (approver_id = ( SELECT auth.uid() AS uid))));

CREATE POLICY "Requesters can delete pending focus requests" ON "public"."focus_requests"
  FOR DELETE
  TO "authenticated"
  USING (((requester_id = ( SELECT auth.uid() AS uid)) AND (status = 'pending'::public.focus_request_status)));

CREATE POLICY "Users can create focus requests" ON "public"."focus_requests"
  FOR INSERT
  TO "authenticated"
  WITH
    CHECK
    (((requester_id = ( SELECT auth.uid() AS uid)) AND (approver_id <> ( SELECT auth.uid() AS uid)) AND (status = 'pending'::public.focus_request_status) AND (responded_at IS NULL)
    AND (activated_at IS NULL) AND (ends_at IS NULL)));

CREATE POLICY "Addressees can respond to friendship requests" ON "public"."friendships"
  FOR UPDATE
  TO "authenticated"
  USING (((addressee_id = ( SELECT auth.uid() AS uid)) AND (status = 'pending'::public.friendship_status)))
  WITH
    CHECK
    (((addressee_id = ( SELECT auth.uid() AS uid)) AND (status = ANY (ARRAY['accepted'::public.friendship_status, 'declined'::public.friendship_status,
    'blocked'::public.friendship_status]))));

CREATE POLICY "Participants can delete non-blocked friendships" ON "public"."friendships"
  FOR DELETE
  TO "authenticated"
  USING ((((requester_id = ( SELECT auth.uid() AS uid)) OR (addressee_id = ( SELECT auth.uid() AS uid))) AND (status <> 'blocked'::public.friendship_status)));

CREATE POLICY "Users can send friendship requests" ON "public"."friendships"
  FOR INSERT
  TO "authenticated"
  WITH
    CHECK
    (((requester_id = ( SELECT auth.uid() AS uid)) AND (addressee_id <> ( SELECT auth.uid() AS uid)) AND (status = 'pending'::public.friendship_status) AND (responded_at IS NULL)));

CREATE POLICY "Users can view their friendships" ON "public"."friendships"
  FOR SELECT
  TO "authenticated"
  USING (((requester_id = ( SELECT auth.uid() AS uid)) OR (addressee_id = ( SELECT auth.uid() AS uid))));

CREATE POLICY "Authenticated users can view profiles" ON "public"."profiles"
  FOR SELECT
  TO "authenticated"
  USING (true);

CREATE POLICY "Users can update their own profile" ON "public"."profiles"
  FOR UPDATE
  TO "authenticated"
  USING ((id = ( SELECT auth.uid() AS uid)))
  WITH CHECK ((id = ( SELECT auth.uid() AS uid)));

CREATE POLICY "requesters_can_receive_focus_request_events" ON "realtime"."messages"
  FOR SELECT
  TO "authenticated"
  USING (((EXTENSION = 'broadcast'::text) AND (realtime.topic() = ('focus_requests:'::text || (( SELECT auth.uid() AS uid))::text))));

ALTER PUBLICATION "supabase_realtime" ADD TABLE "public"."focus_requests";

GRANT EXECUTE ON FUNCTION "public"."accept_focus_request"(uuid) TO "authenticated";

REVOKE ALL ON FUNCTION "public"."accept_focus_request"(uuid) FROM "postgres";

GRANT EXECUTE ON FUNCTION "public"."accept_focus_request"(uuid) TO "postgres";

GRANT EXECUTE ON FUNCTION "public"."accept_focus_request"(uuid) TO "service_role";

GRANT EXECUTE ON FUNCTION "public"."cancel_focus_request"(uuid) TO "authenticated";

REVOKE ALL ON FUNCTION "public"."cancel_focus_request"(uuid) FROM "postgres";

GRANT EXECUTE ON FUNCTION "public"."cancel_focus_request"(uuid) TO "postgres";

GRANT EXECUTE ON FUNCTION "public"."cancel_focus_request"(uuid) TO "service_role";

GRANT EXECUTE ON FUNCTION "public"."decline_focus_request"(uuid) TO "authenticated";

REVOKE ALL ON FUNCTION "public"."decline_focus_request"(uuid) FROM "postgres";

GRANT EXECUTE ON FUNCTION "public"."decline_focus_request"(uuid) TO "postgres";

GRANT EXECUTE ON FUNCTION "public"."decline_focus_request"(uuid) TO "service_role";

REVOKE ALL ON FUNCTION "public"."focus_requests_broadcast_accepted"() FROM "postgres";

GRANT EXECUTE ON FUNCTION "public"."focus_requests_broadcast_accepted"() TO "postgres";

GRANT EXECUTE ON FUNCTION "public"."handle_new_user"() TO PUBLIC, "anon", "authenticated";

REVOKE ALL ON FUNCTION "public"."handle_new_user"() FROM "postgres";

GRANT EXECUTE ON FUNCTION "public"."handle_new_user"() TO "postgres";

GRANT EXECUTE ON FUNCTION "public"."handle_new_user"() TO "service_role";

GRANT EXECUTE ON FUNCTION "public"."mark_focus_request_activated"(uuid) TO "authenticated";

REVOKE ALL ON FUNCTION "public"."mark_focus_request_activated"(uuid) FROM "postgres";

GRANT EXECUTE ON FUNCTION "public"."mark_focus_request_activated"(uuid) TO "postgres";

GRANT EXECUTE ON FUNCTION "public"."mark_focus_request_activated"(uuid) TO "service_role";

GRANT EXECUTE ON FUNCTION "public"."respond_to_friend_request"(uuid, public.friendship_status) TO PUBLIC, "anon", "authenticated";

REVOKE ALL ON FUNCTION "public"."respond_to_friend_request"(uuid, public.friendship_status) FROM "postgres";

GRANT EXECUTE ON FUNCTION "public"."respond_to_friend_request"(uuid, public.friendship_status) TO "postgres";

GRANT EXECUTE ON FUNCTION "public"."respond_to_friend_request"(uuid, public.friendship_status) TO "service_role";

GRANT EXECUTE ON FUNCTION "public"."set_friendship_responded_at"() TO PUBLIC, "anon", "authenticated";

REVOKE ALL ON FUNCTION "public"."set_friendship_responded_at"() FROM "postgres";

GRANT EXECUTE ON FUNCTION "public"."set_friendship_responded_at"() TO "postgres";

GRANT EXECUTE ON FUNCTION "public"."set_friendship_responded_at"() TO "service_role";

REVOKE ALL ON TABLE "public"."focus_requests" FROM "authenticated";

REVOKE ALL ("approver_id") ON TABLE "public"."focus_requests" FROM "authenticated";

GRANT INSERT ("approver_id") ON TABLE "public"."focus_requests" TO "authenticated";

REVOKE ALL ("duration_minutes") ON TABLE "public"."focus_requests" FROM "authenticated";

GRANT INSERT ("duration_minutes") ON TABLE "public"."focus_requests" TO "authenticated";

REVOKE ALL ("requester_id") ON TABLE "public"."focus_requests" FROM "authenticated";

GRANT INSERT ("requester_id") ON TABLE "public"."focus_requests" TO "authenticated";

REVOKE ALL ("status") ON TABLE "public"."focus_requests" FROM "authenticated";

GRANT INSERT ("status") ON TABLE "public"."focus_requests" TO "authenticated";

GRANT SELECT ON TABLE "public"."focus_requests" TO "authenticated";

REVOKE ALL ON TABLE "public"."focus_requests" FROM "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."focus_requests" TO "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."focus_requests" TO "service_role";

REVOKE ALL ON TABLE "public"."friendships" FROM "authenticated";

REVOKE ALL ("addressee_id") ON TABLE "public"."friendships" FROM "authenticated";

GRANT INSERT ("addressee_id") ON TABLE "public"."friendships" TO "authenticated";

REVOKE ALL ("requester_id") ON TABLE "public"."friendships" FROM "authenticated";

GRANT INSERT ("requester_id") ON TABLE "public"."friendships" TO "authenticated";

REVOKE ALL ("status") ON TABLE "public"."friendships" FROM "authenticated";

GRANT INSERT ("status"), UPDATE ("status") ON TABLE "public"."friendships" TO "authenticated";

GRANT SELECT ON TABLE "public"."friendships" TO "authenticated";

REVOKE ALL ON TABLE "public"."friendships" FROM "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."friendships" TO "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."friendships" TO "service_role";

REVOKE ALL ON TABLE "public"."profiles" FROM "authenticated";

REVOKE ALL ("username") ON TABLE "public"."profiles" FROM "authenticated";

GRANT UPDATE ("username") ON TABLE "public"."profiles" TO "authenticated";

GRANT SELECT ON TABLE "public"."profiles" TO "authenticated";

REVOKE ALL ON TABLE "public"."profiles" FROM "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."profiles" TO "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."profiles" TO "service_role";

