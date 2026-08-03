SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;


--
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


--
-- Name: recording_studio_users_reject_profile_mutation(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.recording_studio_users_reject_profile_mutation() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  RAISE EXCEPTION 'recording_studio_users_profiles is append-only'
    USING ERRCODE = 'integrity_constraint_violation';
END;
$$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: ar_internal_metadata; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ar_internal_metadata (
    key character varying NOT NULL,
    value character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: folders; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.folders (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    name character varying,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: pages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pages (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    title character varying,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: recording_studio_events; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.recording_studio_events (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    action character varying NOT NULL,
    actor_id uuid,
    actor_type character varying,
    created_at timestamp(6) without time zone NOT NULL,
    idempotency_key character varying,
    impersonator_id uuid,
    impersonator_type character varying,
    metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    occurred_at timestamp(6) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    previous_recordable_id uuid,
    previous_recordable_type character varying,
    recordable_id uuid NOT NULL,
    recordable_type character varying NOT NULL,
    recording_id uuid NOT NULL
);


--
-- Name: recording_studio_recordings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.recording_studio_recordings (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    parent_recording_id uuid,
    recordable_id uuid NOT NULL,
    recordable_type character varying NOT NULL,
    root_recording_id uuid,
    trashed_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: recording_studio_root_switchable_selections; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.recording_studio_root_switchable_selections (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    actor_id character varying,
    actor_type character varying,
    created_at timestamp(6) without time zone NOT NULL,
    device_browser character varying,
    device_key character varying NOT NULL,
    device_label character varying,
    device_platform character varying,
    device_type character varying,
    last_used_at timestamp(6) without time zone NOT NULL,
    root_recording_id uuid NOT NULL,
    scope_key character varying NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    user_agent text
);


--
-- Name: recording_studio_users_profiles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.recording_studio_users_profiles (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_root_id uuid NOT NULL,
    display_name character varying NOT NULL,
    given_name character varying,
    family_name character varying,
    pronouns character varying,
    bio text,
    locale character varying,
    time_zone character varying,
    metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    CONSTRAINT recording_studio_users_profiles_display_name_length CHECK ((char_length((display_name)::text) <= 200)),
    CONSTRAINT recording_studio_users_profiles_metadata_object CHECK ((jsonb_typeof(metadata) = 'object'::text))
);


--
-- Name: recording_studio_users_user_roots; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.recording_studio_users_user_roots (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_type character varying NOT NULL,
    user_id uuid NOT NULL,
    created_at timestamp(6) without time zone NOT NULL
);


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version character varying NOT NULL
);


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    email character varying DEFAULT ''::character varying NOT NULL,
    encrypted_password character varying DEFAULT ''::character varying NOT NULL,
    remember_created_at timestamp(6) without time zone,
    reset_password_sent_at timestamp(6) without time zone,
    reset_password_token character varying,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: workspaces; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.workspaces (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    name character varying,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: ar_internal_metadata ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- Name: folders folders_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.folders
    ADD CONSTRAINT folders_pkey PRIMARY KEY (id);


--
-- Name: pages pages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pages
    ADD CONSTRAINT pages_pkey PRIMARY KEY (id);


--
-- Name: recording_studio_events recording_studio_events_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recording_studio_events
    ADD CONSTRAINT recording_studio_events_pkey PRIMARY KEY (id);


--
-- Name: recording_studio_recordings recording_studio_recordings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recording_studio_recordings
    ADD CONSTRAINT recording_studio_recordings_pkey PRIMARY KEY (id);


--
-- Name: recording_studio_root_switchable_selections recording_studio_root_switchable_selections_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recording_studio_root_switchable_selections
    ADD CONSTRAINT recording_studio_root_switchable_selections_pkey PRIMARY KEY (id);


--
-- Name: recording_studio_users_profiles recording_studio_users_profiles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recording_studio_users_profiles
    ADD CONSTRAINT recording_studio_users_profiles_pkey PRIMARY KEY (id);


--
-- Name: recording_studio_users_user_roots recording_studio_users_user_roots_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recording_studio_users_user_roots
    ADD CONSTRAINT recording_studio_users_user_roots_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: workspaces workspaces_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.workspaces
    ADD CONSTRAINT workspaces_pkey PRIMARY KEY (id);


--
-- Name: idx_recording_studio_users_profiles_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_recording_studio_users_profiles_on_name ON public.recording_studio_users_profiles USING btree (display_name);


--
-- Name: idx_recording_studio_users_profiles_on_root; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_recording_studio_users_profiles_on_root ON public.recording_studio_users_profiles USING btree (user_root_id);


--
-- Name: idx_recording_studio_users_roots_on_user; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_recording_studio_users_roots_on_user ON public.recording_studio_users_user_roots USING btree (user_type, user_id);


--
-- Name: idx_rs_root_switchable_actor_device_scope; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_rs_root_switchable_actor_device_scope ON public.recording_studio_root_switchable_selections USING btree (actor_type, actor_id, device_key, scope_key) WHERE (actor_id IS NOT NULL);


--
-- Name: idx_rs_root_switchable_anonymous_device_scope; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_rs_root_switchable_anonymous_device_scope ON public.recording_studio_root_switchable_selections USING btree (device_key, scope_key) WHERE (actor_id IS NULL);


--
-- Name: idx_rs_root_switchable_root_recording; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_rs_root_switchable_root_recording ON public.recording_studio_root_switchable_selections USING btree (root_recording_id);


--
-- Name: index_recording_studio_events_on_recording_and_idempotency_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_recording_studio_events_on_recording_and_idempotency_key ON public.recording_studio_events USING btree (recording_id, idempotency_key) WHERE (idempotency_key IS NOT NULL);


--
-- Name: index_recording_studio_events_on_recording_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_recording_studio_events_on_recording_id ON public.recording_studio_events USING btree (recording_id);


--
-- Name: index_recording_studio_recordings_on_parent_recording_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_recording_studio_recordings_on_parent_recording_id ON public.recording_studio_recordings USING btree (parent_recording_id);


--
-- Name: index_recording_studio_recordings_on_recordable; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_recording_studio_recordings_on_recordable ON public.recording_studio_recordings USING btree (recordable_type, recordable_id);


--
-- Name: index_recording_studio_recordings_on_recordable_parent_trashed; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_recording_studio_recordings_on_recordable_parent_trashed ON public.recording_studio_recordings USING btree (recordable_type, recordable_id, parent_recording_id, trashed_at);


--
-- Name: index_rs_recordings_on_root_recording; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_rs_recordings_on_root_recording ON public.recording_studio_recordings USING btree (root_recording_id);


--
-- Name: index_users_on_email; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_email ON public.users USING btree (email);


--
-- Name: index_users_on_reset_password_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_reset_password_token ON public.users USING btree (reset_password_token);


--
-- Name: recording_studio_users_profiles recording_studio_users_profiles_append_only; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER recording_studio_users_profiles_append_only BEFORE DELETE OR UPDATE ON public.recording_studio_users_profiles FOR EACH ROW EXECUTE FUNCTION public.recording_studio_users_reject_profile_mutation();


--
-- Name: recording_studio_recordings fk_rails_26012d5ca3; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recording_studio_recordings
    ADD CONSTRAINT fk_rails_26012d5ca3 FOREIGN KEY (parent_recording_id) REFERENCES public.recording_studio_recordings(id);


--
-- Name: recording_studio_users_profiles fk_rails_ecb6ef2cea; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recording_studio_users_profiles
    ADD CONSTRAINT fk_rails_ecb6ef2cea FOREIGN KEY (user_root_id) REFERENCES public.recording_studio_users_user_roots(id);


--
-- Name: recording_studio_events fk_rails_ff21937ccd; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recording_studio_events
    ADD CONSTRAINT fk_rails_ff21937ccd FOREIGN KEY (recording_id) REFERENCES public.recording_studio_recordings(id);


--
-- Name: recording_studio_recordings fk_rails_ffcd14a670; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recording_studio_recordings
    ADD CONSTRAINT fk_rails_ffcd14a670 FOREIGN KEY (root_recording_id) REFERENCES public.recording_studio_recordings(id);


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user", public;

INSERT INTO "schema_migrations" (version) VALUES
('20260803000002'),
('20260803000001'),
('20260803000000'),
('20260612000000'),
('20260505000001'),
('20260421000000'),
('20260217233016'),
('20260217072940'),
('20260217072923'),
('20260217072826'),
('20260217072825'),
('20260217072824'),
('20260217072823'),
('20260217072822'),
('20260217072821'),
('20260217072820'),
('20260217072819'),
('20260217072818'),
('20260217072817'),
('20260217072816'),
('20260217072815'),
('20250101000000');

