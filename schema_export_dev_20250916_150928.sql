--
-- PostgreSQL database dump
--

-- Dumped from database version 17.4
-- Dumped by pg_dump version 17.4

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

ALTER TABLE IF EXISTS ONLY public.user_sessions DROP CONSTRAINT IF EXISTS user_sessions_user_id_fkey;
ALTER TABLE IF EXISTS ONLY public.user_preferences DROP CONSTRAINT IF EXISTS user_preferences_user_id_fkey;
ALTER TABLE IF EXISTS ONLY public.system_config DROP CONSTRAINT IF EXISTS system_config_updated_by_fkey;
ALTER TABLE IF EXISTS ONLY public.projects DROP CONSTRAINT IF EXISTS projects_template_id_fkey;
ALTER TABLE IF EXISTS ONLY public.projects DROP CONSTRAINT IF EXISTS projects_owner_id_fkey;
ALTER TABLE IF EXISTS ONLY public.project_collaborators DROP CONSTRAINT IF EXISTS project_collaborators_user_id_fkey;
ALTER TABLE IF EXISTS ONLY public.project_collaborators DROP CONSTRAINT IF EXISTS project_collaborators_project_id_fkey;
ALTER TABLE IF EXISTS ONLY public.project_collaborators DROP CONSTRAINT IF EXISTS project_collaborators_invited_by_fkey;
ALTER TABLE IF EXISTS ONLY public.ml_models DROP CONSTRAINT IF EXISTS ml_models_training_data_id_fkey;
ALTER TABLE IF EXISTS ONLY public.ml_models DROP CONSTRAINT IF EXISTS ml_models_trained_by_fkey;
ALTER TABLE IF EXISTS ONLY public.ml_models DROP CONSTRAINT IF EXISTS ml_models_project_id_fkey;
ALTER TABLE IF EXISTS ONLY public.game_templates DROP CONSTRAINT IF EXISTS game_templates_updated_by_fkey;
ALTER TABLE IF EXISTS ONLY public.game_templates DROP CONSTRAINT IF EXISTS game_templates_created_by_fkey;
ALTER TABLE IF EXISTS ONLY public.game_templates DROP CONSTRAINT IF EXISTS game_templates_approved_by_fkey;
ALTER TABLE IF EXISTS ONLY public.datasets DROP CONSTRAINT IF EXISTS datasets_project_id_fkey;
ALTER TABLE IF EXISTS ONLY public.datasets DROP CONSTRAINT IF EXISTS datasets_parent_dataset_id_fkey;
ALTER TABLE IF EXISTS ONLY public.datasets DROP CONSTRAINT IF EXISTS datasets_created_by_fkey;
ALTER TABLE IF EXISTS ONLY public.audit_logs DROP CONSTRAINT IF EXISTS audit_logs_user_id_fkey;
ALTER TABLE IF EXISTS ONLY public.assets DROP CONSTRAINT IF EXISTS assets_uploaded_by_fkey;
ALTER TABLE IF EXISTS ONLY public.assets DROP CONSTRAINT IF EXISTS assets_project_id_fkey;
ALTER TABLE IF EXISTS ONLY public.assets DROP CONSTRAINT IF EXISTS assets_parent_id_fkey;
ALTER TABLE IF EXISTS ONLY public.api_keys DROP CONSTRAINT IF EXISTS api_keys_user_id_fkey;
ALTER TABLE IF EXISTS ONLY public.ai_requests DROP CONSTRAINT IF EXISTS ai_requests_user_id_fkey;
ALTER TABLE IF EXISTS ONLY public.ai_requests DROP CONSTRAINT IF EXISTS ai_requests_project_id_fkey;
DROP TRIGGER IF EXISTS update_users_updated_at ON public.users;
DROP TRIGGER IF EXISTS update_user_preferences_updated_at ON public.user_preferences;
DROP TRIGGER IF EXISTS update_projects_updated_at ON public.projects;
DROP TRIGGER IF EXISTS update_ml_models_updated_at ON public.ml_models;
DROP TRIGGER IF EXISTS update_game_templates_updated_at ON public.game_templates;
DROP TRIGGER IF EXISTS update_datasets_updated_at ON public.datasets;
DROP TRIGGER IF EXISTS update_assets_updated_at ON public.assets;
DROP TRIGGER IF EXISTS update_ai_requests_updated_at ON public.ai_requests;
DROP INDEX IF EXISTS public.idx_users_username;
DROP INDEX IF EXISTS public.idx_users_role;
DROP INDEX IF EXISTS public.idx_users_provider_id;
DROP INDEX IF EXISTS public.idx_users_provider;
DROP INDEX IF EXISTS public.idx_users_github_id;
DROP INDEX IF EXISTS public.idx_users_email;
DROP INDEX IF EXISTS public.idx_users_created_at;
DROP INDEX IF EXISTS public.idx_user_sessions_user_id;
DROP INDEX IF EXISTS public.idx_user_sessions_token;
DROP INDEX IF EXISTS public.idx_user_sessions_expires_at;
DROP INDEX IF EXISTS public.idx_user_preferences_user_id;
DROP INDEX IF EXISTS public.idx_schema_migrations_version;
DROP INDEX IF EXISTS public.idx_schema_migrations_applied_at;
DROP INDEX IF EXISTS public.idx_projects_template_id;
DROP INDEX IF EXISTS public.idx_projects_target_platforms;
DROP INDEX IF EXISTS public.idx_projects_tags;
DROP INDEX IF EXISTS public.idx_projects_status;
DROP INDEX IF EXISTS public.idx_projects_slug;
DROP INDEX IF EXISTS public.idx_projects_search;
DROP INDEX IF EXISTS public.idx_projects_owner_id;
DROP INDEX IF EXISTS public.idx_projects_genre;
DROP INDEX IF EXISTS public.idx_projects_engine;
DROP INDEX IF EXISTS public.idx_projects_created_at;
DROP INDEX IF EXISTS public.idx_project_collaborators_user_id;
DROP INDEX IF EXISTS public.idx_project_collaborators_project_id;
DROP INDEX IF EXISTS public.idx_ml_models_trained_by;
DROP INDEX IF EXISTS public.idx_ml_models_project_id;
DROP INDEX IF EXISTS public.idx_ml_models_created_at;
DROP INDEX IF EXISTS public.idx_game_templates_tags;
DROP INDEX IF EXISTS public.idx_game_templates_slug;
DROP INDEX IF EXISTS public.idx_game_templates_genre;
DROP INDEX IF EXISTS public.idx_game_templates_featured;
DROP INDEX IF EXISTS public.idx_game_templates_engine;
DROP INDEX IF EXISTS public.idx_game_templates_category;
DROP INDEX IF EXISTS public.idx_game_templates_active;
DROP INDEX IF EXISTS public.idx_datasets_project_id;
DROP INDEX IF EXISTS public.idx_datasets_created_by;
DROP INDEX IF EXISTS public.idx_datasets_created_at;
DROP INDEX IF EXISTS public.idx_audit_logs_user_id;
DROP INDEX IF EXISTS public.idx_audit_logs_timestamp;
DROP INDEX IF EXISTS public.idx_audit_logs_resource_type;
DROP INDEX IF EXISTS public.idx_audit_logs_action;
DROP INDEX IF EXISTS public.idx_assets_uploaded_by;
DROP INDEX IF EXISTS public.idx_assets_type;
DROP INDEX IF EXISTS public.idx_assets_tags;
DROP INDEX IF EXISTS public.idx_assets_search;
DROP INDEX IF EXISTS public.idx_assets_project_id;
DROP INDEX IF EXISTS public.idx_assets_created_at;
DROP INDEX IF EXISTS public.idx_api_keys_user_id;
DROP INDEX IF EXISTS public.idx_api_keys_hash;
DROP INDEX IF EXISTS public.idx_ai_requests_user_id;
DROP INDEX IF EXISTS public.idx_ai_requests_type;
DROP INDEX IF EXISTS public.idx_ai_requests_status;
DROP INDEX IF EXISTS public.idx_ai_requests_project_id;
DROP INDEX IF EXISTS public.idx_ai_requests_created_at;
ALTER TABLE IF EXISTS ONLY public.users DROP CONSTRAINT IF EXISTS users_username_key;
ALTER TABLE IF EXISTS ONLY public.users DROP CONSTRAINT IF EXISTS users_pkey;
ALTER TABLE IF EXISTS ONLY public.users DROP CONSTRAINT IF EXISTS users_github_id_key;
ALTER TABLE IF EXISTS ONLY public.users DROP CONSTRAINT IF EXISTS users_email_key;
ALTER TABLE IF EXISTS ONLY public.user_sessions DROP CONSTRAINT IF EXISTS user_sessions_session_token_key;
ALTER TABLE IF EXISTS ONLY public.user_sessions DROP CONSTRAINT IF EXISTS user_sessions_refresh_token_key;
ALTER TABLE IF EXISTS ONLY public.user_sessions DROP CONSTRAINT IF EXISTS user_sessions_pkey;
ALTER TABLE IF EXISTS ONLY public.user_preferences DROP CONSTRAINT IF EXISTS user_preferences_user_id_key;
ALTER TABLE IF EXISTS ONLY public.user_preferences DROP CONSTRAINT IF EXISTS user_preferences_pkey;
ALTER TABLE IF EXISTS ONLY public.system_config DROP CONSTRAINT IF EXISTS system_config_pkey;
ALTER TABLE IF EXISTS ONLY public.schema_migrations DROP CONSTRAINT IF EXISTS schema_migrations_version_key;
ALTER TABLE IF EXISTS ONLY public.schema_migrations DROP CONSTRAINT IF EXISTS schema_migrations_pkey;
ALTER TABLE IF EXISTS ONLY public.projects DROP CONSTRAINT IF EXISTS projects_slug_key;
ALTER TABLE IF EXISTS ONLY public.projects DROP CONSTRAINT IF EXISTS projects_pkey;
ALTER TABLE IF EXISTS ONLY public.project_collaborators DROP CONSTRAINT IF EXISTS project_collaborators_project_id_user_id_key;
ALTER TABLE IF EXISTS ONLY public.project_collaborators DROP CONSTRAINT IF EXISTS project_collaborators_pkey;
ALTER TABLE IF EXISTS ONLY public.ml_models DROP CONSTRAINT IF EXISTS ml_models_project_id_name_version_key;
ALTER TABLE IF EXISTS ONLY public.ml_models DROP CONSTRAINT IF EXISTS ml_models_pkey;
ALTER TABLE IF EXISTS ONLY public.game_templates DROP CONSTRAINT IF EXISTS game_templates_slug_key;
ALTER TABLE IF EXISTS ONLY public.game_templates DROP CONSTRAINT IF EXISTS game_templates_pkey;
ALTER TABLE IF EXISTS ONLY public.datasets DROP CONSTRAINT IF EXISTS datasets_project_id_name_version_key;
ALTER TABLE IF EXISTS ONLY public.datasets DROP CONSTRAINT IF EXISTS datasets_pkey;
ALTER TABLE IF EXISTS ONLY public.audit_logs DROP CONSTRAINT IF EXISTS audit_logs_pkey;
ALTER TABLE IF EXISTS ONLY public.assets DROP CONSTRAINT IF EXISTS assets_pkey;
ALTER TABLE IF EXISTS ONLY public.api_keys DROP CONSTRAINT IF EXISTS api_keys_pkey;
ALTER TABLE IF EXISTS ONLY public.api_keys DROP CONSTRAINT IF EXISTS api_keys_key_hash_key;
ALTER TABLE IF EXISTS ONLY public.ai_requests DROP CONSTRAINT IF EXISTS ai_requests_pkey;
ALTER TABLE IF EXISTS public.schema_migrations ALTER COLUMN id DROP DEFAULT;
DROP VIEW IF EXISTS public.user_stats;
DROP TABLE IF EXISTS public.users;
DROP TABLE IF EXISTS public.user_sessions;
DROP TABLE IF EXISTS public.user_preferences;
DROP TABLE IF EXISTS public.system_config;
DROP SEQUENCE IF EXISTS public.schema_migrations_id_seq;
DROP VIEW IF EXISTS public.project_stats;
DROP TABLE IF EXISTS public.projects;
DROP TABLE IF EXISTS public.project_collaborators;
DROP TABLE IF EXISTS public.ml_models;
DROP VIEW IF EXISTS public.migration_status;
DROP TABLE IF EXISTS public.schema_migrations;
DROP TABLE IF EXISTS public.game_templates;
DROP TABLE IF EXISTS public.datasets;
DROP TABLE IF EXISTS public.audit_logs;
DROP TABLE IF EXISTS public.assets;
DROP TABLE IF EXISTS public.api_keys;
DROP TABLE IF EXISTS public.ai_requests;
DROP FUNCTION IF EXISTS public.validate_migration_checksum(migration_version character varying, expected_checksum character varying);
DROP FUNCTION IF EXISTS public.update_updated_at_column();
DROP FUNCTION IF EXISTS public.record_migration(migration_version character varying, migration_description text, migration_checksum character varying, migration_path text, execution_time integer);
DROP FUNCTION IF EXISTS public.create_project_with_owner(p_owner_id uuid, p_name character varying, p_description text, p_is_public boolean);
DROP TYPE IF EXISTS public.user_role;
DROP TYPE IF EXISTS public.project_status;
DROP TYPE IF EXISTS public.audit_action;
DROP TYPE IF EXISTS public.asset_type;
DROP TYPE IF EXISTS public.ai_request_type;
DROP TYPE IF EXISTS public.ai_request_status;
DROP EXTENSION IF EXISTS "uuid-ossp";
DROP EXTENSION IF EXISTS pg_trgm;
DROP EXTENSION IF EXISTS citext;
--
-- Name: citext; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS citext WITH SCHEMA public;


--
-- Name: EXTENSION citext; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION citext IS 'data type for case-insensitive character strings';


--
-- Name: pg_trgm; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_trgm WITH SCHEMA public;


--
-- Name: EXTENSION pg_trgm; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pg_trgm IS 'text similarity measurement and index searching based on trigrams';


--
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;


--
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


--
-- Name: ai_request_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.ai_request_status AS ENUM (
    'pending',
    'processing',
    'completed',
    'failed',
    'cancelled'
);


--
-- Name: ai_request_type; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.ai_request_type AS ENUM (
    'text_generation',
    'image_generation',
    'model_training',
    'data_analysis',
    'code_generation'
);


--
-- Name: asset_type; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.asset_type AS ENUM (
    'model',
    'dataset',
    'texture',
    'audio',
    'script',
    'config',
    'other'
);


--
-- Name: audit_action; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.audit_action AS ENUM (
    'create',
    'read',
    'update',
    'delete',
    'login',
    'logout',
    'export',
    'import'
);


--
-- Name: project_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.project_status AS ENUM (
    'active',
    'archived',
    'deleted'
);


--
-- Name: user_role; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.user_role AS ENUM (
    'basic_user',
    'premium_user',
    'admin',
    'super_admin'
);


--
-- Name: create_project_with_owner(uuid, character varying, text, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.create_project_with_owner(p_owner_id uuid, p_name character varying, p_description text DEFAULT NULL::text, p_is_public boolean DEFAULT false) RETURNS uuid
    LANGUAGE plpgsql
    AS $$
DECLARE
    project_uuid UUID;
    project_slug VARCHAR(255);
BEGIN
    -- Generate slug from name
    project_slug := lower(regexp_replace(p_name, '[^a-zA-Z0-9]+', '-', 'g'));
    project_slug := trim(both '-' from project_slug);
    
    -- Ensure unique slug
    WHILE EXISTS (SELECT 1 FROM projects WHERE slug = project_slug) LOOP
        project_slug := project_slug || '-' || substr(md5(random()::text), 1, 6);
    END LOOP;
    
    -- Create project
    INSERT INTO projects (owner_id, name, slug, description, is_public)
    VALUES (p_owner_id, p_name, project_slug, p_description, p_is_public)
    RETURNING id INTO project_uuid;
    
    -- Add owner as admin collaborator
    INSERT INTO project_collaborators (project_id, user_id, role, accepted_at)
    VALUES (project_uuid, p_owner_id, 'admin', CURRENT_TIMESTAMP);
    
    RETURN project_uuid;
END;
$$;


--
-- Name: record_migration(character varying, text, character varying, text, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.record_migration(migration_version character varying, migration_description text, migration_checksum character varying, migration_path text, execution_time integer DEFAULT NULL::integer) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
BEGIN
    INSERT INTO schema_migrations (
        version, 
        description, 
        checksum, 
        script_path, 
        execution_time_ms
    ) VALUES (
        migration_version,
        migration_description,
        migration_checksum,
        migration_path,
        execution_time
    ) ON CONFLICT (version) DO UPDATE SET
        description = EXCLUDED.description,
        checksum = EXCLUDED.checksum,
        script_path = EXCLUDED.script_path,
        execution_time_ms = EXCLUDED.execution_time_ms,
        applied_at = CURRENT_TIMESTAMP;
    
    RETURN TRUE;
EXCEPTION
    WHEN OTHERS THEN
        RETURN FALSE;
END;
$$;


--
-- Name: update_updated_at_column(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_updated_at_column() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;


--
-- Name: validate_migration_checksum(character varying, character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.validate_migration_checksum(migration_version character varying, expected_checksum character varying) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
DECLARE
    stored_checksum VARCHAR(64);
BEGIN
    SELECT checksum INTO stored_checksum 
    FROM schema_migrations 
    WHERE version = migration_version;
    
    IF stored_checksum IS NULL THEN
        RETURN TRUE; -- New migration
    END IF;
    
    RETURN stored_checksum = expected_checksum;
END;
$$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: ai_requests; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ai_requests (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    user_id uuid NOT NULL,
    project_id uuid,
    request_type public.ai_request_type NOT NULL,
    status public.ai_request_status DEFAULT 'pending'::public.ai_request_status,
    input_data jsonb DEFAULT '{}'::jsonb NOT NULL,
    output_data jsonb DEFAULT '{}'::jsonb,
    result_link text,
    error_message text,
    processing_time_ms integer,
    cost_credits numeric(10,4) DEFAULT 0,
    priority integer DEFAULT 5,
    retry_count integer DEFAULT 0,
    max_retries integer DEFAULT 3,
    scheduled_at timestamp with time zone,
    started_at timestamp with time zone,
    completed_at timestamp with time zone,
    expires_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: api_keys; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.api_keys (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    user_id uuid NOT NULL,
    name character varying(255) NOT NULL,
    key_hash character varying(255) NOT NULL,
    key_prefix character varying(10) NOT NULL,
    permissions jsonb DEFAULT '{}'::jsonb,
    rate_limit integer DEFAULT 1000,
    is_active boolean DEFAULT true,
    last_used timestamp with time zone,
    expires_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: assets; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.assets (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    project_id uuid NOT NULL,
    parent_id uuid,
    name character varying(255) NOT NULL,
    type public.asset_type NOT NULL,
    file_path text NOT NULL,
    original_filename text,
    file_size bigint DEFAULT 0 NOT NULL,
    mime_type character varying(255),
    checksum_md5 character varying(32),
    checksum_sha256 character varying(64),
    version integer DEFAULT 1,
    is_latest_version boolean DEFAULT true,
    metadata jsonb DEFAULT '{}'::jsonb,
    tags text[],
    description text,
    uploaded_by uuid NOT NULL,
    download_count integer DEFAULT 0,
    last_accessed timestamp with time zone,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: audit_logs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.audit_logs (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    user_id uuid,
    session_id character varying(255),
    action public.audit_action NOT NULL,
    resource_type character varying(100) NOT NULL,
    resource_id uuid,
    resource_name character varying(255),
    details jsonb DEFAULT '{}'::jsonb,
    ip_address inet,
    user_agent text,
    request_id character varying(255),
    success boolean DEFAULT true,
    error_message text,
    "timestamp" timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: datasets; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.datasets (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    project_id uuid NOT NULL,
    name character varying(255) NOT NULL,
    version character varying(50) NOT NULL,
    description text,
    file_path text NOT NULL,
    file_size bigint DEFAULT 0 NOT NULL,
    row_count integer,
    column_count integer,
    schema_definition jsonb DEFAULT '{}'::jsonb,
    quality_score numeric(3,2),
    data_drift_score numeric(3,2),
    validation_rules jsonb DEFAULT '{}'::jsonb,
    created_by uuid NOT NULL,
    parent_dataset_id uuid,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: game_templates; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.game_templates (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    name character varying(255) NOT NULL,
    slug character varying(255) NOT NULL,
    engine character varying(100) NOT NULL,
    engine_version character varying(50),
    category character varying(100),
    genre character varying(100),
    template_url text,
    repository_url text,
    documentation_url text,
    thumbnail_url text,
    preview_images text[],
    description text,
    detailed_description text,
    features text[],
    requirements text[],
    tags text[],
    difficulty_level character varying(20) DEFAULT 'beginner'::character varying,
    estimated_time_hours integer,
    file_size_mb integer,
    downloads integer DEFAULT 0,
    rating numeric(3,2) DEFAULT 0.00,
    review_count integer DEFAULT 0,
    is_featured boolean DEFAULT false,
    is_active boolean DEFAULT true,
    price_credits integer DEFAULT 0,
    created_by uuid,
    updated_by uuid,
    approved_at timestamp with time zone,
    approved_by uuid,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    id integer NOT NULL,
    version character varying(255) NOT NULL,
    description text,
    checksum character varying(64),
    applied_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    applied_by character varying(255) DEFAULT CURRENT_USER,
    execution_time_ms integer,
    script_path text
);


--
-- Name: migration_status; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.migration_status AS
 SELECT version,
    description,
    applied_at,
    applied_by,
    execution_time_ms,
        CASE
            WHEN (applied_at IS NOT NULL) THEN 'APPLIED'::text
            ELSE 'PENDING'::text
        END AS status
   FROM public.schema_migrations sm
  ORDER BY version;


--
-- Name: ml_models; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ml_models (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    project_id uuid NOT NULL,
    name character varying(255) NOT NULL,
    version character varying(50) NOT NULL,
    model_type character varying(100) NOT NULL,
    framework character varying(50),
    file_path text NOT NULL,
    file_size bigint DEFAULT 0 NOT NULL,
    accuracy numeric(5,4),
    loss numeric(10,6),
    training_data_id uuid,
    hyperparameters jsonb DEFAULT '{}'::jsonb,
    metrics jsonb DEFAULT '{}'::jsonb,
    is_deployed boolean DEFAULT false,
    deployment_url text,
    trained_by uuid NOT NULL,
    training_duration_minutes integer,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: project_collaborators; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.project_collaborators (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    project_id uuid NOT NULL,
    user_id uuid NOT NULL,
    role character varying(50) DEFAULT 'viewer'::character varying,
    permissions jsonb DEFAULT '{}'::jsonb,
    invited_by uuid,
    invited_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    accepted_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: projects; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.projects (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    owner_id uuid NOT NULL,
    name character varying(255) NOT NULL,
    slug character varying(255) NOT NULL,
    description text,
    status public.project_status DEFAULT 'active'::public.project_status,
    is_public boolean DEFAULT false,
    tags text[],
    metadata jsonb DEFAULT '{}'::jsonb,
    repository_url text,
    documentation_url text,
    demo_url text,
    license character varying(100),
    template_id uuid,
    engine character varying(100),
    engine_version character varying(50),
    target_platforms text[],
    genre character varying(100),
    art_style character varying(100),
    total_assets integer DEFAULT 0,
    total_size_bytes bigint DEFAULT 0,
    last_activity timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: project_stats; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.project_stats AS
 SELECT p.id,
    p.name,
    p.owner_id,
    p.status,
    p.created_at,
    count(DISTINCT a.id) AS asset_count,
    count(DISTINCT ml.id) AS model_count,
    count(DISTINCT d.id) AS dataset_count,
    count(DISTINCT pc.id) AS collaborator_count,
    COALESCE(sum(a.file_size), (0)::numeric) AS total_size_bytes,
    max(a.created_at) AS last_asset_upload
   FROM ((((public.projects p
     LEFT JOIN public.assets a ON ((p.id = a.project_id)))
     LEFT JOIN public.ml_models ml ON ((p.id = ml.project_id)))
     LEFT JOIN public.datasets d ON ((p.id = d.project_id)))
     LEFT JOIN public.project_collaborators pc ON ((p.id = pc.project_id)))
  GROUP BY p.id, p.name, p.owner_id, p.status, p.created_at;


--
-- Name: schema_migrations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.schema_migrations_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: schema_migrations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.schema_migrations_id_seq OWNED BY public.schema_migrations.id;


--
-- Name: system_config; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.system_config (
    key character varying(255) NOT NULL,
    value jsonb NOT NULL,
    description text,
    is_public boolean DEFAULT false,
    updated_by uuid,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: user_preferences; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_preferences (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    user_id uuid NOT NULL,
    theme character varying(50) DEFAULT 'system'::character varying,
    notifications_enabled boolean DEFAULT true,
    email_notifications boolean DEFAULT true,
    push_notifications boolean DEFAULT true,
    language character varying(10) DEFAULT 'en'::character varying,
    timezone character varying(100) DEFAULT 'UTC'::character varying,
    date_format character varying(20) DEFAULT 'YYYY-MM-DD'::character varying,
    time_format character varying(10) DEFAULT '24h'::character varying,
    items_per_page integer DEFAULT 25,
    auto_save boolean DEFAULT true,
    settings jsonb DEFAULT '{}'::jsonb,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: user_sessions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_sessions (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    user_id uuid NOT NULL,
    session_token character varying(255) NOT NULL,
    refresh_token character varying(255),
    ip_address inet,
    user_agent text,
    is_active boolean DEFAULT true,
    expires_at timestamp with time zone NOT NULL,
    last_activity timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    email public.citext NOT NULL,
    username character varying(50) NOT NULL,
    hashed_password text,
    role public.user_role DEFAULT 'basic_user'::public.user_role,
    first_name character varying(100),
    last_name character varying(100),
    name character varying(255),
    avatar_url text,
    is_active boolean DEFAULT true,
    email_verified boolean DEFAULT false,
    last_login timestamp with time zone,
    password_reset_token text,
    password_reset_expires timestamp with time zone,
    two_factor_enabled boolean DEFAULT false,
    two_factor_secret text,
    api_quota_limit integer DEFAULT 1000,
    api_quota_used integer DEFAULT 0,
    api_quota_reset_date date DEFAULT CURRENT_DATE,
    github_id character varying(255),
    github_username character varying(255),
    provider character varying(50) DEFAULT 'local'::character varying,
    provider_id character varying(255),
    access_token text,
    refresh_token text,
    token_expires_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: user_stats; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.user_stats AS
 SELECT u.id,
    u.email,
    u.username,
    u.role,
    u.created_at,
    count(DISTINCT p.id) AS project_count,
    count(DISTINCT a.id) AS asset_count,
    count(DISTINCT ar.id) AS ai_request_count,
    COALESCE(sum(a.file_size), (0)::numeric) AS total_storage_bytes
   FROM (((public.users u
     LEFT JOIN public.projects p ON (((u.id = p.owner_id) AND (p.status = 'active'::public.project_status))))
     LEFT JOIN public.assets a ON ((p.id = a.project_id)))
     LEFT JOIN public.ai_requests ar ON ((u.id = ar.user_id)))
  GROUP BY u.id, u.email, u.username, u.role, u.created_at;


--
-- Name: schema_migrations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations ALTER COLUMN id SET DEFAULT nextval('public.schema_migrations_id_seq'::regclass);


--
-- Name: ai_requests ai_requests_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ai_requests
    ADD CONSTRAINT ai_requests_pkey PRIMARY KEY (id);


--
-- Name: api_keys api_keys_key_hash_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.api_keys
    ADD CONSTRAINT api_keys_key_hash_key UNIQUE (key_hash);


--
-- Name: api_keys api_keys_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.api_keys
    ADD CONSTRAINT api_keys_pkey PRIMARY KEY (id);


--
-- Name: assets assets_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assets
    ADD CONSTRAINT assets_pkey PRIMARY KEY (id);


--
-- Name: audit_logs audit_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audit_logs
    ADD CONSTRAINT audit_logs_pkey PRIMARY KEY (id);


--
-- Name: datasets datasets_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.datasets
    ADD CONSTRAINT datasets_pkey PRIMARY KEY (id);


--
-- Name: datasets datasets_project_id_name_version_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.datasets
    ADD CONSTRAINT datasets_project_id_name_version_key UNIQUE (project_id, name, version);


--
-- Name: game_templates game_templates_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.game_templates
    ADD CONSTRAINT game_templates_pkey PRIMARY KEY (id);


--
-- Name: game_templates game_templates_slug_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.game_templates
    ADD CONSTRAINT game_templates_slug_key UNIQUE (slug);


--
-- Name: ml_models ml_models_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ml_models
    ADD CONSTRAINT ml_models_pkey PRIMARY KEY (id);


--
-- Name: ml_models ml_models_project_id_name_version_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ml_models
    ADD CONSTRAINT ml_models_project_id_name_version_key UNIQUE (project_id, name, version);


--
-- Name: project_collaborators project_collaborators_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_collaborators
    ADD CONSTRAINT project_collaborators_pkey PRIMARY KEY (id);


--
-- Name: project_collaborators project_collaborators_project_id_user_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_collaborators
    ADD CONSTRAINT project_collaborators_project_id_user_id_key UNIQUE (project_id, user_id);


--
-- Name: projects projects_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.projects
    ADD CONSTRAINT projects_pkey PRIMARY KEY (id);


--
-- Name: projects projects_slug_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.projects
    ADD CONSTRAINT projects_slug_key UNIQUE (slug);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_version_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_version_key UNIQUE (version);


--
-- Name: system_config system_config_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.system_config
    ADD CONSTRAINT system_config_pkey PRIMARY KEY (key);


--
-- Name: user_preferences user_preferences_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_preferences
    ADD CONSTRAINT user_preferences_pkey PRIMARY KEY (id);


--
-- Name: user_preferences user_preferences_user_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_preferences
    ADD CONSTRAINT user_preferences_user_id_key UNIQUE (user_id);


--
-- Name: user_sessions user_sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_sessions
    ADD CONSTRAINT user_sessions_pkey PRIMARY KEY (id);


--
-- Name: user_sessions user_sessions_refresh_token_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_sessions
    ADD CONSTRAINT user_sessions_refresh_token_key UNIQUE (refresh_token);


--
-- Name: user_sessions user_sessions_session_token_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_sessions
    ADD CONSTRAINT user_sessions_session_token_key UNIQUE (session_token);


--
-- Name: users users_email_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_email_key UNIQUE (email);


--
-- Name: users users_github_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_github_id_key UNIQUE (github_id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: users users_username_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_username_key UNIQUE (username);


--
-- Name: idx_ai_requests_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_ai_requests_created_at ON public.ai_requests USING btree (created_at);


--
-- Name: idx_ai_requests_project_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_ai_requests_project_id ON public.ai_requests USING btree (project_id);


--
-- Name: idx_ai_requests_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_ai_requests_status ON public.ai_requests USING btree (status);


--
-- Name: idx_ai_requests_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_ai_requests_type ON public.ai_requests USING btree (request_type);


--
-- Name: idx_ai_requests_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_ai_requests_user_id ON public.ai_requests USING btree (user_id);


--
-- Name: idx_api_keys_hash; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_api_keys_hash ON public.api_keys USING btree (key_hash);


--
-- Name: idx_api_keys_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_api_keys_user_id ON public.api_keys USING btree (user_id);


--
-- Name: idx_assets_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_assets_created_at ON public.assets USING btree (created_at);


--
-- Name: idx_assets_project_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_assets_project_id ON public.assets USING btree (project_id);


--
-- Name: idx_assets_search; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_assets_search ON public.assets USING gin (to_tsvector('english'::regconfig, (((name)::text || ' '::text) || COALESCE(description, ''::text))));


--
-- Name: idx_assets_tags; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_assets_tags ON public.assets USING gin (tags);


--
-- Name: idx_assets_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_assets_type ON public.assets USING btree (type);


--
-- Name: idx_assets_uploaded_by; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_assets_uploaded_by ON public.assets USING btree (uploaded_by);


--
-- Name: idx_audit_logs_action; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_audit_logs_action ON public.audit_logs USING btree (action);


--
-- Name: idx_audit_logs_resource_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_audit_logs_resource_type ON public.audit_logs USING btree (resource_type);


--
-- Name: idx_audit_logs_timestamp; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_audit_logs_timestamp ON public.audit_logs USING btree ("timestamp");


--
-- Name: idx_audit_logs_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_audit_logs_user_id ON public.audit_logs USING btree (user_id);


--
-- Name: idx_datasets_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_datasets_created_at ON public.datasets USING btree (created_at);


--
-- Name: idx_datasets_created_by; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_datasets_created_by ON public.datasets USING btree (created_by);


--
-- Name: idx_datasets_project_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_datasets_project_id ON public.datasets USING btree (project_id);


--
-- Name: idx_game_templates_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_game_templates_active ON public.game_templates USING btree (is_active);


--
-- Name: idx_game_templates_category; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_game_templates_category ON public.game_templates USING btree (category);


--
-- Name: idx_game_templates_engine; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_game_templates_engine ON public.game_templates USING btree (engine);


--
-- Name: idx_game_templates_featured; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_game_templates_featured ON public.game_templates USING btree (is_featured);


--
-- Name: idx_game_templates_genre; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_game_templates_genre ON public.game_templates USING btree (genre);


--
-- Name: idx_game_templates_slug; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_game_templates_slug ON public.game_templates USING btree (slug);


--
-- Name: idx_game_templates_tags; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_game_templates_tags ON public.game_templates USING gin (tags);


--
-- Name: idx_ml_models_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_ml_models_created_at ON public.ml_models USING btree (created_at);


--
-- Name: idx_ml_models_project_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_ml_models_project_id ON public.ml_models USING btree (project_id);


--
-- Name: idx_ml_models_trained_by; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_ml_models_trained_by ON public.ml_models USING btree (trained_by);


--
-- Name: idx_project_collaborators_project_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_project_collaborators_project_id ON public.project_collaborators USING btree (project_id);


--
-- Name: idx_project_collaborators_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_project_collaborators_user_id ON public.project_collaborators USING btree (user_id);


--
-- Name: idx_projects_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_projects_created_at ON public.projects USING btree (created_at);


--
-- Name: idx_projects_engine; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_projects_engine ON public.projects USING btree (engine);


--
-- Name: idx_projects_genre; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_projects_genre ON public.projects USING btree (genre);


--
-- Name: idx_projects_owner_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_projects_owner_id ON public.projects USING btree (owner_id);


--
-- Name: idx_projects_search; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_projects_search ON public.projects USING gin (to_tsvector('english'::regconfig, (((name)::text || ' '::text) || COALESCE(description, ''::text))));


--
-- Name: idx_projects_slug; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_projects_slug ON public.projects USING btree (slug);


--
-- Name: idx_projects_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_projects_status ON public.projects USING btree (status);


--
-- Name: idx_projects_tags; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_projects_tags ON public.projects USING gin (tags);


--
-- Name: idx_projects_target_platforms; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_projects_target_platforms ON public.projects USING gin (target_platforms);


--
-- Name: idx_projects_template_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_projects_template_id ON public.projects USING btree (template_id);


--
-- Name: idx_schema_migrations_applied_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_schema_migrations_applied_at ON public.schema_migrations USING btree (applied_at);


--
-- Name: idx_schema_migrations_version; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_schema_migrations_version ON public.schema_migrations USING btree (version);


--
-- Name: idx_user_preferences_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_user_preferences_user_id ON public.user_preferences USING btree (user_id);


--
-- Name: idx_user_sessions_expires_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_user_sessions_expires_at ON public.user_sessions USING btree (expires_at);


--
-- Name: idx_user_sessions_token; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_user_sessions_token ON public.user_sessions USING btree (session_token);


--
-- Name: idx_user_sessions_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_user_sessions_user_id ON public.user_sessions USING btree (user_id);


--
-- Name: idx_users_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_users_created_at ON public.users USING btree (created_at);


--
-- Name: idx_users_email; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_users_email ON public.users USING btree (email);


--
-- Name: idx_users_github_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_users_github_id ON public.users USING btree (github_id);


--
-- Name: idx_users_provider; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_users_provider ON public.users USING btree (provider);


--
-- Name: idx_users_provider_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_users_provider_id ON public.users USING btree (provider_id);


--
-- Name: idx_users_role; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_users_role ON public.users USING btree (role);


--
-- Name: idx_users_username; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_users_username ON public.users USING btree (username);


--
-- Name: ai_requests update_ai_requests_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_ai_requests_updated_at BEFORE UPDATE ON public.ai_requests FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: assets update_assets_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_assets_updated_at BEFORE UPDATE ON public.assets FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: datasets update_datasets_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_datasets_updated_at BEFORE UPDATE ON public.datasets FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: game_templates update_game_templates_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_game_templates_updated_at BEFORE UPDATE ON public.game_templates FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: ml_models update_ml_models_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_ml_models_updated_at BEFORE UPDATE ON public.ml_models FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: projects update_projects_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_projects_updated_at BEFORE UPDATE ON public.projects FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: user_preferences update_user_preferences_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_user_preferences_updated_at BEFORE UPDATE ON public.user_preferences FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: users update_users_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON public.users FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: ai_requests ai_requests_project_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ai_requests
    ADD CONSTRAINT ai_requests_project_id_fkey FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE SET NULL;


--
-- Name: ai_requests ai_requests_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ai_requests
    ADD CONSTRAINT ai_requests_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: api_keys api_keys_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.api_keys
    ADD CONSTRAINT api_keys_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: assets assets_parent_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assets
    ADD CONSTRAINT assets_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES public.assets(id) ON DELETE CASCADE;


--
-- Name: assets assets_project_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assets
    ADD CONSTRAINT assets_project_id_fkey FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;


--
-- Name: assets assets_uploaded_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assets
    ADD CONSTRAINT assets_uploaded_by_fkey FOREIGN KEY (uploaded_by) REFERENCES public.users(id);


--
-- Name: audit_logs audit_logs_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audit_logs
    ADD CONSTRAINT audit_logs_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: datasets datasets_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.datasets
    ADD CONSTRAINT datasets_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id);


--
-- Name: datasets datasets_parent_dataset_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.datasets
    ADD CONSTRAINT datasets_parent_dataset_id_fkey FOREIGN KEY (parent_dataset_id) REFERENCES public.datasets(id);


--
-- Name: datasets datasets_project_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.datasets
    ADD CONSTRAINT datasets_project_id_fkey FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;


--
-- Name: game_templates game_templates_approved_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.game_templates
    ADD CONSTRAINT game_templates_approved_by_fkey FOREIGN KEY (approved_by) REFERENCES public.users(id);


--
-- Name: game_templates game_templates_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.game_templates
    ADD CONSTRAINT game_templates_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id);


--
-- Name: game_templates game_templates_updated_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.game_templates
    ADD CONSTRAINT game_templates_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES public.users(id);


--
-- Name: ml_models ml_models_project_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ml_models
    ADD CONSTRAINT ml_models_project_id_fkey FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;


--
-- Name: ml_models ml_models_trained_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ml_models
    ADD CONSTRAINT ml_models_trained_by_fkey FOREIGN KEY (trained_by) REFERENCES public.users(id);


--
-- Name: ml_models ml_models_training_data_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ml_models
    ADD CONSTRAINT ml_models_training_data_id_fkey FOREIGN KEY (training_data_id) REFERENCES public.assets(id);


--
-- Name: project_collaborators project_collaborators_invited_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_collaborators
    ADD CONSTRAINT project_collaborators_invited_by_fkey FOREIGN KEY (invited_by) REFERENCES public.users(id);


--
-- Name: project_collaborators project_collaborators_project_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_collaborators
    ADD CONSTRAINT project_collaborators_project_id_fkey FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;


--
-- Name: project_collaborators project_collaborators_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_collaborators
    ADD CONSTRAINT project_collaborators_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: projects projects_owner_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.projects
    ADD CONSTRAINT projects_owner_id_fkey FOREIGN KEY (owner_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: projects projects_template_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.projects
    ADD CONSTRAINT projects_template_id_fkey FOREIGN KEY (template_id) REFERENCES public.game_templates(id);


--
-- Name: system_config system_config_updated_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.system_config
    ADD CONSTRAINT system_config_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES public.users(id);


--
-- Name: user_preferences user_preferences_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_preferences
    ADD CONSTRAINT user_preferences_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: user_sessions user_sessions_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_sessions
    ADD CONSTRAINT user_sessions_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

