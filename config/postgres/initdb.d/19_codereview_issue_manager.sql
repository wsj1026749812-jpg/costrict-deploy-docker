SELECT 'CREATE DATABASE codereview OWNER zgsm'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'codereview')\gexec

\connect codereview

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

SET default_tablespace = '';
SET default_table_access_method = heap;

CREATE TABLE IF NOT EXISTS public.issue_archives (
    source character varying(100),
    review_task_id text,
    client_id character varying(100),
    workspace character varying(255),
    review_code text,
    issue_code text,
    fix_code text,
    start_line bigint,
    end_line bigint,
    slide_line bigint,
    title character varying(255),
    message text,
    fingerprint character varying(255),
    issue_types text[],
    severity bigint DEFAULT 1,
    status bigint DEFAULT 0,
    confidence numeric DEFAULT 0,
    file_path text,
    no bigint DEFAULT 0,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    id bigint NOT NULL,
    issue_id text,
    archived_at timestamp with time zone,
    duplication_count smallint DEFAULT 0
);

ALTER TABLE public.issue_archives OWNER TO zgsm;

CREATE SEQUENCE IF NOT EXISTS public.issue_archives_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE public.issue_archives_id_seq OWNER TO zgsm;
ALTER SEQUENCE public.issue_archives_id_seq OWNED BY public.issue_archives.id;

CREATE TABLE IF NOT EXISTS public.issues (
    source character varying(100),
    review_task_id text,
    client_id character varying(100),
    workspace character varying(255),
    review_code text,
    issue_code text,
    fix_code text,
    start_line bigint,
    end_line bigint,
    slide_line bigint,
    title character varying(255),
    message text,
    fingerprint character varying(255),
    issue_types text[],
    severity bigint DEFAULT 1,
    status bigint DEFAULT 0,
    confidence numeric DEFAULT 0,
    file_path text,
    no bigint DEFAULT 0,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    id text NOT NULL
);

ALTER TABLE public.issues OWNER TO zgsm;

CREATE TABLE IF NOT EXISTS public.review_task (
    id text NOT NULL,
    status bigint DEFAULT 0,
    err_msg text,
    client_id character varying(100),
    workspace character varying(255),
    total_count bigint DEFAULT 0,
    finished_count bigint DEFAULT 0,
    fail_count bigint DEFAULT 0,
    run_task_id character varying(50),
    targets json,
    creator character varying(100),
    project_id bigint,
    merge_request_iid bigint,
    merge_request_id bigint,
    target_branch character varying(100),
    ref character varying(100),
    original_ref character varying(100),
    merge_request_url character varying(500),
    user_id bigint,
    user_name character varying(100),
    source character varying(100),
    base_url text,
    comments text,
    elapsed_time bigint DEFAULT 0,
    created_at timestamp with time zone,
    updated_at timestamp with time zone
);

ALTER TABLE public.review_task OWNER TO zgsm;

ALTER TABLE ONLY public.issue_archives ALTER COLUMN id SET DEFAULT nextval('public.issue_archives_id_seq'::regclass);

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'issue_archives_pkey' AND conrelid = 'public.issue_archives'::regclass
    ) THEN
        ALTER TABLE ONLY public.issue_archives ADD CONSTRAINT issue_archives_pkey PRIMARY KEY (id);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'issues_pkey' AND conrelid = 'public.issues'::regclass
    ) THEN
        ALTER TABLE ONLY public.issues ADD CONSTRAINT issues_pkey PRIMARY KEY (id);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'review_task_pkey' AND conrelid = 'public.review_task'::regclass
    ) THEN
        ALTER TABLE ONLY public.review_task ADD CONSTRAINT review_task_pkey PRIMARY KEY (id);
    END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_issue_archives_issue_types ON public.issue_archives USING gin (issue_types);
CREATE INDEX IF NOT EXISTS idx_issues_issue_types ON public.issues USING gin (issue_types);
