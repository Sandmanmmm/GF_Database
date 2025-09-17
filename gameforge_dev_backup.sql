--
-- PostgreSQL database dump
--

\restrict tCnvbjie3crbjmQ9GfugKYkUWvLaIcof2oeHYQxpHdXflJEk4YX2YzZp9FHhNYc

-- Dumped from database version 16.10
-- Dumped by pg_dump version 16.10

-- Started on 2025-09-16 20:55:44

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
-- TOC entry 3 (class 3079 OID 16411)
-- Name: citext; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS citext WITH SCHEMA public;


--
-- TOC entry 5489 (class 0 OID 0)
-- Dependencies: 3
-- Name: EXTENSION citext; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION citext IS 'data type for case-insensitive character strings';


--
-- TOC entry 4 (class 3079 OID 16516)
-- Name: pg_trgm; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_trgm WITH SCHEMA public;


--
-- TOC entry 5490 (class 0 OID 0)
-- Dependencies: 4
-- Name: EXTENSION pg_trgm; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pg_trgm IS 'text similarity measurement and index searching based on trigrams';


--
-- TOC entry 2 (class 3079 OID 16400)
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;


--
-- TOC entry 5491 (class 0 OID 0)
-- Dependencies: 2
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


--
-- TOC entry 975 (class 1247 OID 16644)
-- Name: ai_request_status; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.ai_request_status AS ENUM (
    'pending',
    'processing',
    'completed',
    'failed',
    'cancelled'
);


ALTER TYPE public.ai_request_status OWNER TO postgres;

--
-- TOC entry 972 (class 1247 OID 16632)
-- Name: ai_request_type; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.ai_request_type AS ENUM (
    'text_generation',
    'image_generation',
    'model_training',
    'data_analysis',
    'code_generation'
);


ALTER TYPE public.ai_request_type OWNER TO postgres;

--
-- TOC entry 969 (class 1247 OID 16616)
-- Name: asset_type; Type: TYPE; Schema: public; Owner: postgres
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


ALTER TYPE public.asset_type OWNER TO postgres;

--
-- TOC entry 978 (class 1247 OID 16656)
-- Name: audit_action; Type: TYPE; Schema: public; Owner: postgres
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


ALTER TYPE public.audit_action OWNER TO postgres;

--
-- TOC entry 1035 (class 1247 OID 17126)
-- Name: data_classification; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.data_classification AS ENUM (
    'USER_IDENTITY',
    'USER_AUTH',
    'PAYMENT_DATA',
    'BILLING_INFO',
    'PROJECT_METADATA',
    'ASSET_METADATA',
    'ASSET_BINARIES',
    'USER_UPLOADS',
    'MODEL_ARTIFACTS',
    'TRAINING_DATASETS',
    'MODEL_METADATA',
    'APPLICATION_LOGS',
    'ACCESS_LOGS',
    'AUDIT_LOGS',
    'SYSTEM_METRICS',
    'API_KEYS',
    'ENCRYPTION_KEYS',
    'TLS_CERTIFICATES',
    'VAULT_TOKENS',
    'USAGE_ANALYTICS',
    'BUSINESS_METRICS',
    'PERFORMANCE_METRICS'
);


ALTER TYPE public.data_classification OWNER TO postgres;

--
-- TOC entry 966 (class 1247 OID 16608)
-- Name: project_status; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.project_status AS ENUM (
    'active',
    'archived',
    'deleted'
);


ALTER TYPE public.project_status OWNER TO postgres;

--
-- TOC entry 963 (class 1247 OID 16598)
-- Name: user_role; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.user_role AS ENUM (
    'basic_user',
    'premium_user',
    'admin',
    'super_admin',
    'ai_user'
);


ALTER TYPE public.user_role OWNER TO postgres;

--
-- TOC entry 251 (class 1255 OID 17270)
-- Name: assign_default_permissions(uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.assign_default_permissions(user_uuid uuid) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
    user_role_value user_role;
BEGIN
    -- Get user role
    SELECT role INTO user_role_value FROM users WHERE id = user_uuid;
    
    -- Clear existing permissions (in case of role change)
    DELETE FROM user_permissions WHERE user_id = user_uuid AND resource_id IS NULL;
    
    -- Assign permissions based on role
    CASE user_role_value
        WHEN 'basic_user' THEN
            INSERT INTO user_permissions (user_id, permission, resource_type) VALUES
            (user_uuid, 'assets:read', 'global'),
            (user_uuid, 'projects:read', 'global'),
            (user_uuid, 'projects:create', 'global');
            
        WHEN 'premium_user' THEN
            INSERT INTO user_permissions (user_id, permission, resource_type) VALUES
            (user_uuid, 'assets:read', 'global'),
            (user_uuid, 'assets:create', 'global'),
            (user_uuid, 'assets:update', 'global'),
            (user_uuid, 'projects:read', 'global'),
            (user_uuid, 'projects:create', 'global'),
            (user_uuid, 'projects:update', 'global'),
            (user_uuid, 'models:read', 'global'),
            (user_uuid, 'models:create', 'global');
            
        WHEN 'ai_user' THEN
            INSERT INTO user_permissions (user_id, permission, resource_type) VALUES
            (user_uuid, 'assets:read', 'global'),
            (user_uuid, 'assets:create', 'global'),
            (user_uuid, 'assets:update', 'global'),
            (user_uuid, 'projects:read', 'global'),
            (user_uuid, 'projects:create', 'global'),
            (user_uuid, 'projects:update', 'global'),
            (user_uuid, 'models:read', 'global'),
            (user_uuid, 'models:create', 'global'),
            (user_uuid, 'models:train', 'global'),
            (user_uuid, 'ai:generate', 'global');
            
        WHEN 'admin' THEN
            INSERT INTO user_permissions (user_id, permission, resource_type) VALUES
            (user_uuid, 'assets:*', 'global'),
            (user_uuid, 'projects:*', 'global'),
            (user_uuid, 'models:*', 'global'),
            (user_uuid, 'users:*', 'global'),
            (user_uuid, 'system:*', 'global');
            
        WHEN 'super_admin' THEN
            INSERT INTO user_permissions (user_id, permission, resource_type) VALUES
            (user_uuid, '*:*', 'global');
    END CASE;
END;
$$;


ALTER FUNCTION public.assign_default_permissions(user_uuid uuid) OWNER TO postgres;

--
-- TOC entry 294 (class 1255 OID 17075)
-- Name: create_project_with_owner(uuid, character varying, text, boolean); Type: FUNCTION; Schema: public; Owner: postgres
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


ALTER FUNCTION public.create_project_with_owner(p_owner_id uuid, p_name character varying, p_description text, p_is_public boolean) OWNER TO postgres;

--
-- TOC entry 241 (class 1255 OID 17096)
-- Name: record_migration(character varying, text, character varying, text, integer); Type: FUNCTION; Schema: public; Owner: postgres
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


ALTER FUNCTION public.record_migration(migration_version character varying, migration_description text, migration_checksum character varying, migration_path text, execution_time integer) OWNER TO postgres;

--
-- TOC entry 319 (class 1255 OID 17271)
-- Name: trigger_assign_permissions(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.trigger_assign_permissions() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Only assign permissions if role changed or new user
    IF TG_OP = 'INSERT' OR (TG_OP = 'UPDATE' AND OLD.role != NEW.role) THEN
        PERFORM assign_default_permissions(NEW.id);
    END IF;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.trigger_assign_permissions() OWNER TO postgres;

--
-- TOC entry 338 (class 1255 OID 17056)
-- Name: update_updated_at_column(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.update_updated_at_column() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.update_updated_at_column() OWNER TO postgres;

--
-- TOC entry 299 (class 1255 OID 17095)
-- Name: validate_migration_checksum(character varying, character varying); Type: FUNCTION; Schema: public; Owner: postgres
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


ALTER FUNCTION public.validate_migration_checksum(migration_version character varying, expected_checksum character varying) OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 238 (class 1259 OID 17202)
-- Name: access_tokens; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.access_tokens (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    user_id uuid NOT NULL,
    token_hash character varying(255) NOT NULL,
    token_prefix character varying(10) NOT NULL,
    resource_type character varying(50) NOT NULL,
    resource_id character varying(255) NOT NULL,
    allowed_actions text[] NOT NULL,
    conditions jsonb DEFAULT '{}'::jsonb,
    expires_at timestamp with time zone NOT NULL,
    last_used timestamp with time zone,
    use_count integer DEFAULT 0,
    max_uses integer,
    metadata jsonb DEFAULT '{}'::jsonb,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.access_tokens OWNER TO postgres;

--
-- TOC entry 224 (class 1259 OID 16846)
-- Name: ai_requests; Type: TABLE; Schema: public; Owner: postgres
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


ALTER TABLE public.ai_requests OWNER TO postgres;

--
-- TOC entry 229 (class 1259 OID 16970)
-- Name: api_keys; Type: TABLE; Schema: public; Owner: postgres
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
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    data_classification public.data_classification DEFAULT 'API_KEYS'::public.data_classification,
    encryption_required boolean DEFAULT true
);


ALTER TABLE public.api_keys OWNER TO postgres;

--
-- TOC entry 223 (class 1259 OID 16816)
-- Name: assets; Type: TABLE; Schema: public; Owner: postgres
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
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    data_classification public.data_classification DEFAULT 'ASSET_BINARIES'::public.data_classification,
    retention_period_days integer DEFAULT 1825,
    encryption_required boolean DEFAULT true
);


ALTER TABLE public.assets OWNER TO postgres;

--
-- TOC entry 227 (class 1259 OID 16934)
-- Name: audit_logs; Type: TABLE; Schema: public; Owner: postgres
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
    "timestamp" timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    data_classification public.data_classification DEFAULT 'AUDIT_LOGS'::public.data_classification,
    retention_period_days integer DEFAULT 2555,
    compliance_event boolean DEFAULT false,
    gdpr_relevant boolean DEFAULT false,
    retention_required boolean DEFAULT true
);


ALTER TABLE public.audit_logs OWNER TO postgres;

--
-- TOC entry 240 (class 1259 OID 17249)
-- Name: compliance_events; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.compliance_events (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    user_id uuid,
    event_type character varying(100) NOT NULL,
    data_classification public.data_classification NOT NULL,
    resource_type character varying(50),
    resource_id uuid,
    legal_basis character varying(100),
    purpose text,
    retention_period integer,
    automated_decision boolean DEFAULT false,
    cross_border_transfer boolean DEFAULT false,
    details jsonb DEFAULT '{}'::jsonb,
    "timestamp" timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.compliance_events OWNER TO postgres;

--
-- TOC entry 226 (class 1259 OID 16904)
-- Name: datasets; Type: TABLE; Schema: public; Owner: postgres
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
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    data_classification public.data_classification DEFAULT 'TRAINING_DATASETS'::public.data_classification
);


ALTER TABLE public.datasets OWNER TO postgres;

--
-- TOC entry 220 (class 1259 OID 16725)
-- Name: game_templates; Type: TABLE; Schema: public; Owner: postgres
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


ALTER TABLE public.game_templates OWNER TO postgres;

--
-- TOC entry 234 (class 1259 OID 17079)
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: postgres
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


ALTER TABLE public.schema_migrations OWNER TO postgres;

--
-- TOC entry 235 (class 1259 OID 17091)
-- Name: migration_status; Type: VIEW; Schema: public; Owner: postgres
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


ALTER VIEW public.migration_status OWNER TO postgres;

--
-- TOC entry 225 (class 1259 OID 16873)
-- Name: ml_models; Type: TABLE; Schema: public; Owner: postgres
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
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    data_classification public.data_classification DEFAULT 'MODEL_ARTIFACTS'::public.data_classification
);


ALTER TABLE public.ml_models OWNER TO postgres;

--
-- TOC entry 239 (class 1259 OID 17221)
-- Name: presigned_urls; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.presigned_urls (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    user_id uuid NOT NULL,
    resource_id character varying(255) NOT NULL,
    url_hash character varying(255) NOT NULL,
    method character varying(10) NOT NULL,
    expires_at timestamp with time zone NOT NULL,
    access_count integer DEFAULT 0,
    max_accesses integer DEFAULT 1,
    metadata jsonb DEFAULT '{}'::jsonb,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.presigned_urls OWNER TO postgres;

--
-- TOC entry 222 (class 1259 OID 16787)
-- Name: project_collaborators; Type: TABLE; Schema: public; Owner: postgres
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


ALTER TABLE public.project_collaborators OWNER TO postgres;

--
-- TOC entry 221 (class 1259 OID 16759)
-- Name: projects; Type: TABLE; Schema: public; Owner: postgres
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


ALTER TABLE public.projects OWNER TO postgres;

--
-- TOC entry 232 (class 1259 OID 17070)
-- Name: project_stats; Type: VIEW; Schema: public; Owner: postgres
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


ALTER VIEW public.project_stats OWNER TO postgres;

--
-- TOC entry 233 (class 1259 OID 17078)
-- Name: schema_migrations_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.schema_migrations_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.schema_migrations_id_seq OWNER TO postgres;

--
-- TOC entry 5592 (class 0 OID 0)
-- Dependencies: 233
-- Name: schema_migrations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.schema_migrations_id_seq OWNED BY public.schema_migrations.id;


--
-- TOC entry 237 (class 1259 OID 17185)
-- Name: storage_configs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.storage_configs (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    name character varying(255) NOT NULL,
    provider character varying(50) NOT NULL,
    bucket_name character varying(255) NOT NULL,
    region character varying(100),
    endpoint_url text,
    access_key_id character varying(255),
    secret_access_key_hash character varying(255),
    configuration jsonb DEFAULT '{}'::jsonb,
    is_default boolean DEFAULT false,
    is_active boolean DEFAULT true,
    max_file_size_mb integer DEFAULT 100,
    allowed_file_types text[] DEFAULT ARRAY['*'::text],
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.storage_configs OWNER TO postgres;

--
-- TOC entry 230 (class 1259 OID 16989)
-- Name: system_config; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.system_config (
    key character varying(255) NOT NULL,
    value jsonb NOT NULL,
    description text,
    is_public boolean DEFAULT false,
    updated_by uuid,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.system_config OWNER TO postgres;

--
-- TOC entry 236 (class 1259 OID 17101)
-- Name: user_permissions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_permissions (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    user_id uuid NOT NULL,
    permission character varying(100) NOT NULL,
    resource_type character varying(50),
    resource_id uuid,
    granted_by uuid,
    expires_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.user_permissions OWNER TO postgres;

--
-- TOC entry 219 (class 1259 OID 16697)
-- Name: user_preferences; Type: TABLE; Schema: public; Owner: postgres
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


ALTER TABLE public.user_preferences OWNER TO postgres;

--
-- TOC entry 228 (class 1259 OID 16950)
-- Name: user_sessions; Type: TABLE; Schema: public; Owner: postgres
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
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    data_classification public.data_classification DEFAULT 'USER_AUTH'::public.data_classification,
    retention_period_days integer DEFAULT 90
);


ALTER TABLE public.user_sessions OWNER TO postgres;

--
-- TOC entry 218 (class 1259 OID 16673)
-- Name: users; Type: TABLE; Schema: public; Owner: postgres
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
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    data_classification public.data_classification DEFAULT 'USER_IDENTITY'::public.data_classification,
    retention_period_days integer DEFAULT 2555,
    encryption_required boolean DEFAULT true
);


ALTER TABLE public.users OWNER TO postgres;

--
-- TOC entry 231 (class 1259 OID 17065)
-- Name: user_stats; Type: VIEW; Schema: public; Owner: postgres
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


ALTER VIEW public.user_stats OWNER TO postgres;

--
-- TOC entry 5109 (class 2604 OID 17082)
-- Name: schema_migrations id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.schema_migrations ALTER COLUMN id SET DEFAULT nextval('public.schema_migrations_id_seq'::regclass);


--
-- TOC entry 5480 (class 0 OID 17202)
-- Dependencies: 238
-- Data for Name: access_tokens; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.access_tokens (id, user_id, token_hash, token_prefix, resource_type, resource_id, allowed_actions, conditions, expires_at, last_used, use_count, max_uses, metadata, created_at) FROM stdin;
\.


--
-- TOC entry 5469 (class 0 OID 16846)
-- Dependencies: 224
-- Data for Name: ai_requests; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.ai_requests (id, user_id, project_id, request_type, status, input_data, output_data, result_link, error_message, processing_time_ms, cost_credits, priority, retry_count, max_retries, scheduled_at, started_at, completed_at, expires_at, created_at, updated_at) FROM stdin;
\.


--
-- TOC entry 5474 (class 0 OID 16970)
-- Dependencies: 229
-- Data for Name: api_keys; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.api_keys (id, user_id, name, key_hash, key_prefix, permissions, rate_limit, is_active, last_used, expires_at, created_at, data_classification, encryption_required) FROM stdin;
\.


--
-- TOC entry 5468 (class 0 OID 16816)
-- Dependencies: 223
-- Data for Name: assets; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.assets (id, project_id, parent_id, name, type, file_path, original_filename, file_size, mime_type, checksum_md5, checksum_sha256, version, is_latest_version, metadata, tags, description, uploaded_by, download_count, last_accessed, created_at, updated_at, data_classification, retention_period_days, encryption_required) FROM stdin;
\.


--
-- TOC entry 5472 (class 0 OID 16934)
-- Dependencies: 227
-- Data for Name: audit_logs; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.audit_logs (id, user_id, session_id, action, resource_type, resource_id, resource_name, details, ip_address, user_agent, request_id, success, error_message, "timestamp", data_classification, retention_period_days, compliance_event, gdpr_relevant, retention_required) FROM stdin;
\.


--
-- TOC entry 5482 (class 0 OID 17249)
-- Dependencies: 240
-- Data for Name: compliance_events; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.compliance_events (id, user_id, event_type, data_classification, resource_type, resource_id, legal_basis, purpose, retention_period, automated_decision, cross_border_transfer, details, "timestamp") FROM stdin;
\.


--
-- TOC entry 5471 (class 0 OID 16904)
-- Dependencies: 226
-- Data for Name: datasets; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.datasets (id, project_id, name, version, description, file_path, file_size, row_count, column_count, schema_definition, quality_score, data_drift_score, validation_rules, created_by, parent_dataset_id, created_at, updated_at, data_classification) FROM stdin;
\.


--
-- TOC entry 5465 (class 0 OID 16725)
-- Dependencies: 220
-- Data for Name: game_templates; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.game_templates (id, name, slug, engine, engine_version, category, genre, template_url, repository_url, documentation_url, thumbnail_url, preview_images, description, detailed_description, features, requirements, tags, difficulty_level, estimated_time_hours, file_size_mb, downloads, rating, review_count, is_featured, is_active, price_credits, created_by, updated_by, approved_at, approved_by, created_at, updated_at) FROM stdin;
011d3a0b-3a44-4caa-b0ad-b142914fd35d	Test 2D Platformer	test-2d-platformer	Unity	\N	game	2D Platformer	\N	\N	\N	\N	\N	A test template for verification	\N	\N	\N	\N	beginner	\N	\N	100	4.50	0	f	t	0	\N	\N	\N	\N	2025-09-15 03:27:42.983901-04	2025-09-15 03:27:42.983901-04
\.


--
-- TOC entry 5470 (class 0 OID 16873)
-- Dependencies: 225
-- Data for Name: ml_models; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.ml_models (id, project_id, name, version, model_type, framework, file_path, file_size, accuracy, loss, training_data_id, hyperparameters, metrics, is_deployed, deployment_url, trained_by, training_duration_minutes, created_at, updated_at, data_classification) FROM stdin;
\.


--
-- TOC entry 5481 (class 0 OID 17221)
-- Dependencies: 239
-- Data for Name: presigned_urls; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.presigned_urls (id, user_id, resource_id, url_hash, method, expires_at, access_count, max_accesses, metadata, created_at) FROM stdin;
\.


--
-- TOC entry 5467 (class 0 OID 16787)
-- Dependencies: 222
-- Data for Name: project_collaborators; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.project_collaborators (id, project_id, user_id, role, permissions, invited_by, invited_at, accepted_at, created_at) FROM stdin;
\.


--
-- TOC entry 5466 (class 0 OID 16759)
-- Dependencies: 221
-- Data for Name: projects; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.projects (id, owner_id, name, slug, description, status, is_public, tags, metadata, repository_url, documentation_url, demo_url, license, template_id, engine, engine_version, target_platforms, genre, art_style, total_assets, total_size_bytes, last_activity, created_at, updated_at) FROM stdin;
\.


--
-- TOC entry 5477 (class 0 OID 17079)
-- Dependencies: 234
-- Data for Name: schema_migrations; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.schema_migrations (id, version, description, checksum, applied_at, applied_by, execution_time_ms, script_path) FROM stdin;
1	000_baseline	Initial GameForge schema baseline	baseline	2025-09-16 20:52:34.906924-04	system	\N	schema.sql
2	003	GameForge Integration Fixes - Auth, Permissions, Data Classification	\N	2025-09-16 20:52:39.745276-04	postgres	\N	\N
\.


--
-- TOC entry 5479 (class 0 OID 17185)
-- Dependencies: 237
-- Data for Name: storage_configs; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.storage_configs (id, name, provider, bucket_name, region, endpoint_url, access_key_id, secret_access_key_hash, configuration, is_default, is_active, max_file_size_mb, allowed_file_types, created_at, updated_at) FROM stdin;
c87392f0-6ba5-49f9-a536-105c00470f60	local_storage	local	gameforge_assets	local	/app/storage	\N	\N	{}	t	t	500	{image/*,model/*,text/*,application/*}	2025-09-16 20:52:39.745276-04	2025-09-16 20:52:39.745276-04
\.


--
-- TOC entry 5475 (class 0 OID 16989)
-- Dependencies: 230
-- Data for Name: system_config; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.system_config (key, value, description, is_public, updated_by, updated_at) FROM stdin;
max_file_size_mb	1024	Maximum file upload size in MB	t	\N	2025-09-15 03:02:55.711105-04
ai_request_timeout_minutes	30	Default timeout for AI requests in minutes	t	\N	2025-09-15 03:02:55.711105-04
max_projects_per_user	10	Maximum projects per basic user	t	\N	2025-09-15 03:02:55.711105-04
maintenance_mode	false	System maintenance mode flag	t	\N	2025-09-15 03:02:55.711105-04
api_version	"v1"	Current API version	t	\N	2025-09-15 03:02:55.711105-04
template_approval_required	true	Whether game templates require approval	f	\N	2025-09-15 03:02:55.711105-04
featured_templates_count	6	Number of featured templates to display	t	\N	2025-09-15 03:02:55.711105-04
oauth_github_enabled	true	Enable GitHub OAuth integration	t	\N	2025-09-15 03:02:55.711105-04
oauth_google_enabled	false	Enable Google OAuth integration	t	\N	2025-09-15 03:02:55.711105-04
default_theme	"system"	Default theme for new users	t	\N	2025-09-15 03:02:55.711105-04
supported_engines	["unity", "unreal", "godot", "custom"]	List of supported game engines	t	\N	2025-09-15 03:02:55.711105-04
\.


--
-- TOC entry 5478 (class 0 OID 17101)
-- Dependencies: 236
-- Data for Name: user_permissions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.user_permissions (id, user_id, permission, resource_type, resource_id, granted_by, expires_at, created_at, updated_at) FROM stdin;
eb431402-aa83-4c48-8143-da79512d643c	42fff14b-315d-4ed6-875e-962b152fef5e	assets:read	global	\N	\N	\N	2025-09-16 20:52:39.745276-04	2025-09-16 20:52:39.745276-04
aef29f3a-09e4-4064-8d2f-2d3255fb03f7	42fff14b-315d-4ed6-875e-962b152fef5e	projects:read	global	\N	\N	\N	2025-09-16 20:52:39.745276-04	2025-09-16 20:52:39.745276-04
02cd04c5-8b63-4c93-977a-0b112acbfe77	42fff14b-315d-4ed6-875e-962b152fef5e	projects:create	global	\N	\N	\N	2025-09-16 20:52:39.745276-04	2025-09-16 20:52:39.745276-04
\.


--
-- TOC entry 5464 (class 0 OID 16697)
-- Dependencies: 219
-- Data for Name: user_preferences; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.user_preferences (id, user_id, theme, notifications_enabled, email_notifications, push_notifications, language, timezone, date_format, time_format, items_per_page, auto_save, settings, created_at, updated_at) FROM stdin;
\.


--
-- TOC entry 5473 (class 0 OID 16950)
-- Dependencies: 228
-- Data for Name: user_sessions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.user_sessions (id, user_id, session_token, refresh_token, ip_address, user_agent, is_active, expires_at, last_activity, created_at, data_classification, retention_period_days) FROM stdin;
\.


--
-- TOC entry 5463 (class 0 OID 16673)
-- Dependencies: 218
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.users (id, email, username, hashed_password, role, first_name, last_name, name, avatar_url, is_active, email_verified, last_login, password_reset_token, password_reset_expires, two_factor_enabled, two_factor_secret, api_quota_limit, api_quota_used, api_quota_reset_date, github_id, github_username, provider, provider_id, access_token, refresh_token, token_expires_at, created_at, updated_at, data_classification, retention_period_days, encryption_required) FROM stdin;
42fff14b-315d-4ed6-875e-962b152fef5e	admin@gameforge.com	admin	\N	basic_user	\N	\N	GameForge Admin	\N	t	f	\N	\N	\N	f	\N	1000	0	2025-09-15	\N	\N	local	\N	\N	\N	\N	2025-09-15 03:04:26.749292-04	2025-09-15 03:04:26.749292-04	USER_IDENTITY	2555	t
\.


--
-- TOC entry 5598 (class 0 OID 0)
-- Dependencies: 233
-- Name: schema_migrations_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.schema_migrations_id_seq', 2, true);


--
-- TOC entry 5262 (class 2606 OID 17213)
-- Name: access_tokens access_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.access_tokens
    ADD CONSTRAINT access_tokens_pkey PRIMARY KEY (id);


--
-- TOC entry 5264 (class 2606 OID 17215)
-- Name: access_tokens access_tokens_token_hash_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.access_tokens
    ADD CONSTRAINT access_tokens_token_hash_key UNIQUE (token_hash);


--
-- TOC entry 5198 (class 2606 OID 16862)
-- Name: ai_requests ai_requests_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ai_requests
    ADD CONSTRAINT ai_requests_pkey PRIMARY KEY (id);


--
-- TOC entry 5234 (class 2606 OID 16983)
-- Name: api_keys api_keys_key_hash_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.api_keys
    ADD CONSTRAINT api_keys_key_hash_key UNIQUE (key_hash);


--
-- TOC entry 5236 (class 2606 OID 16981)
-- Name: api_keys api_keys_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.api_keys
    ADD CONSTRAINT api_keys_pkey PRIMARY KEY (id);


--
-- TOC entry 5190 (class 2606 OID 16830)
-- Name: assets assets_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.assets
    ADD CONSTRAINT assets_pkey PRIMARY KEY (id);


--
-- TOC entry 5219 (class 2606 OID 16944)
-- Name: audit_logs audit_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.audit_logs
    ADD CONSTRAINT audit_logs_pkey PRIMARY KEY (id);


--
-- TOC entry 5274 (class 2606 OID 17260)
-- Name: compliance_events compliance_events_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.compliance_events
    ADD CONSTRAINT compliance_events_pkey PRIMARY KEY (id);


--
-- TOC entry 5212 (class 2606 OID 16916)
-- Name: datasets datasets_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.datasets
    ADD CONSTRAINT datasets_pkey PRIMARY KEY (id);


--
-- TOC entry 5214 (class 2606 OID 16918)
-- Name: datasets datasets_project_id_name_version_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.datasets
    ADD CONSTRAINT datasets_project_id_name_version_key UNIQUE (project_id, name, version);


--
-- TOC entry 5159 (class 2606 OID 16741)
-- Name: game_templates game_templates_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.game_templates
    ADD CONSTRAINT game_templates_pkey PRIMARY KEY (id);


--
-- TOC entry 5161 (class 2606 OID 16743)
-- Name: game_templates game_templates_slug_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.game_templates
    ADD CONSTRAINT game_templates_slug_key UNIQUE (slug);


--
-- TOC entry 5208 (class 2606 OID 16886)
-- Name: ml_models ml_models_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ml_models
    ADD CONSTRAINT ml_models_pkey PRIMARY KEY (id);


--
-- TOC entry 5210 (class 2606 OID 16888)
-- Name: ml_models ml_models_project_id_name_version_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ml_models
    ADD CONSTRAINT ml_models_project_id_name_version_key UNIQUE (project_id, name, version);


--
-- TOC entry 5272 (class 2606 OID 17232)
-- Name: presigned_urls presigned_urls_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.presigned_urls
    ADD CONSTRAINT presigned_urls_pkey PRIMARY KEY (id);


--
-- TOC entry 5186 (class 2606 OID 16798)
-- Name: project_collaborators project_collaborators_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.project_collaborators
    ADD CONSTRAINT project_collaborators_pkey PRIMARY KEY (id);


--
-- TOC entry 5188 (class 2606 OID 16800)
-- Name: project_collaborators project_collaborators_project_id_user_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.project_collaborators
    ADD CONSTRAINT project_collaborators_project_id_user_id_key UNIQUE (project_id, user_id);


--
-- TOC entry 5180 (class 2606 OID 16774)
-- Name: projects projects_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.projects
    ADD CONSTRAINT projects_pkey PRIMARY KEY (id);


--
-- TOC entry 5182 (class 2606 OID 16776)
-- Name: projects projects_slug_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.projects
    ADD CONSTRAINT projects_slug_key UNIQUE (slug);


--
-- TOC entry 5244 (class 2606 OID 17088)
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (id);


--
-- TOC entry 5246 (class 2606 OID 17090)
-- Name: schema_migrations schema_migrations_version_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_version_key UNIQUE (version);


--
-- TOC entry 5258 (class 2606 OID 17199)
-- Name: storage_configs storage_configs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.storage_configs
    ADD CONSTRAINT storage_configs_pkey PRIMARY KEY (id);


--
-- TOC entry 5240 (class 2606 OID 16997)
-- Name: system_config system_config_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.system_config
    ADD CONSTRAINT system_config_pkey PRIMARY KEY (key);


--
-- TOC entry 5260 (class 2606 OID 17201)
-- Name: storage_configs unique_storage_name; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.storage_configs
    ADD CONSTRAINT unique_storage_name UNIQUE (name);


--
-- TOC entry 5252 (class 2606 OID 17110)
-- Name: user_permissions unique_user_permission; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_permissions
    ADD CONSTRAINT unique_user_permission UNIQUE (user_id, permission, resource_type, resource_id);


--
-- TOC entry 5254 (class 2606 OID 17108)
-- Name: user_permissions user_permissions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_permissions
    ADD CONSTRAINT user_permissions_pkey PRIMARY KEY (id);


--
-- TOC entry 5155 (class 2606 OID 16717)
-- Name: user_preferences user_preferences_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_preferences
    ADD CONSTRAINT user_preferences_pkey PRIMARY KEY (id);


--
-- TOC entry 5157 (class 2606 OID 16719)
-- Name: user_preferences user_preferences_user_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_preferences
    ADD CONSTRAINT user_preferences_user_id_key UNIQUE (user_id);


--
-- TOC entry 5228 (class 2606 OID 16960)
-- Name: user_sessions user_sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_sessions
    ADD CONSTRAINT user_sessions_pkey PRIMARY KEY (id);


--
-- TOC entry 5230 (class 2606 OID 16964)
-- Name: user_sessions user_sessions_refresh_token_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_sessions
    ADD CONSTRAINT user_sessions_refresh_token_key UNIQUE (refresh_token);


--
-- TOC entry 5232 (class 2606 OID 16962)
-- Name: user_sessions user_sessions_session_token_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_sessions
    ADD CONSTRAINT user_sessions_session_token_key UNIQUE (session_token);


--
-- TOC entry 5146 (class 2606 OID 16692)
-- Name: users users_email_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_email_key UNIQUE (email);


--
-- TOC entry 5148 (class 2606 OID 16696)
-- Name: users users_github_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_github_id_key UNIQUE (github_id);


--
-- TOC entry 5150 (class 2606 OID 16690)
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- TOC entry 5152 (class 2606 OID 16694)
-- Name: users users_username_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_username_key UNIQUE (username);


--
-- TOC entry 5265 (class 1259 OID 17242)
-- Name: idx_access_tokens_expires; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_access_tokens_expires ON public.access_tokens USING btree (expires_at);


--
-- TOC entry 5266 (class 1259 OID 17241)
-- Name: idx_access_tokens_hash; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_access_tokens_hash ON public.access_tokens USING btree (token_hash);


--
-- TOC entry 5267 (class 1259 OID 17243)
-- Name: idx_access_tokens_resource; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_access_tokens_resource ON public.access_tokens USING btree (resource_type, resource_id);


--
-- TOC entry 5268 (class 1259 OID 17240)
-- Name: idx_access_tokens_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_access_tokens_user_id ON public.access_tokens USING btree (user_id);


--
-- TOC entry 5199 (class 1259 OID 17038)
-- Name: idx_ai_requests_created_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_ai_requests_created_at ON public.ai_requests USING btree (created_at);


--
-- TOC entry 5200 (class 1259 OID 17035)
-- Name: idx_ai_requests_project_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_ai_requests_project_id ON public.ai_requests USING btree (project_id);


--
-- TOC entry 5201 (class 1259 OID 17036)
-- Name: idx_ai_requests_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_ai_requests_status ON public.ai_requests USING btree (status);


--
-- TOC entry 5202 (class 1259 OID 17037)
-- Name: idx_ai_requests_type; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_ai_requests_type ON public.ai_requests USING btree (request_type);


--
-- TOC entry 5203 (class 1259 OID 17034)
-- Name: idx_ai_requests_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_ai_requests_user_id ON public.ai_requests USING btree (user_id);


--
-- TOC entry 5237 (class 1259 OID 17053)
-- Name: idx_api_keys_hash; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_api_keys_hash ON public.api_keys USING btree (key_hash);


--
-- TOC entry 5238 (class 1259 OID 17052)
-- Name: idx_api_keys_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_api_keys_user_id ON public.api_keys USING btree (user_id);


--
-- TOC entry 5191 (class 1259 OID 17032)
-- Name: idx_assets_created_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_assets_created_at ON public.assets USING btree (created_at);


--
-- TOC entry 5192 (class 1259 OID 17029)
-- Name: idx_assets_project_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_assets_project_id ON public.assets USING btree (project_id);


--
-- TOC entry 5193 (class 1259 OID 17055)
-- Name: idx_assets_search; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_assets_search ON public.assets USING gin (to_tsvector('english'::regconfig, (((name)::text || ' '::text) || COALESCE(description, ''::text))));


--
-- TOC entry 5194 (class 1259 OID 17033)
-- Name: idx_assets_tags; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_assets_tags ON public.assets USING gin (tags);


--
-- TOC entry 5195 (class 1259 OID 17030)
-- Name: idx_assets_type; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_assets_type ON public.assets USING btree (type);


--
-- TOC entry 5196 (class 1259 OID 17031)
-- Name: idx_assets_uploaded_by; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_assets_uploaded_by ON public.assets USING btree (uploaded_by);


--
-- TOC entry 5220 (class 1259 OID 17046)
-- Name: idx_audit_logs_action; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_audit_logs_action ON public.audit_logs USING btree (action);


--
-- TOC entry 5221 (class 1259 OID 17047)
-- Name: idx_audit_logs_resource_type; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_audit_logs_resource_type ON public.audit_logs USING btree (resource_type);


--
-- TOC entry 5222 (class 1259 OID 17048)
-- Name: idx_audit_logs_timestamp; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_audit_logs_timestamp ON public.audit_logs USING btree ("timestamp");


--
-- TOC entry 5223 (class 1259 OID 17045)
-- Name: idx_audit_logs_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_audit_logs_user_id ON public.audit_logs USING btree (user_id);


--
-- TOC entry 5275 (class 1259 OID 17268)
-- Name: idx_compliance_events_classification; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_compliance_events_classification ON public.compliance_events USING btree (data_classification);


--
-- TOC entry 5276 (class 1259 OID 17269)
-- Name: idx_compliance_events_timestamp; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_compliance_events_timestamp ON public.compliance_events USING btree ("timestamp");


--
-- TOC entry 5277 (class 1259 OID 17267)
-- Name: idx_compliance_events_type; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_compliance_events_type ON public.compliance_events USING btree (event_type);


--
-- TOC entry 5278 (class 1259 OID 17266)
-- Name: idx_compliance_events_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_compliance_events_user_id ON public.compliance_events USING btree (user_id);


--
-- TOC entry 5215 (class 1259 OID 17044)
-- Name: idx_datasets_created_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_datasets_created_at ON public.datasets USING btree (created_at);


--
-- TOC entry 5216 (class 1259 OID 17043)
-- Name: idx_datasets_created_by; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_datasets_created_by ON public.datasets USING btree (created_by);


--
-- TOC entry 5217 (class 1259 OID 17042)
-- Name: idx_datasets_project_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_datasets_project_id ON public.datasets USING btree (project_id);


--
-- TOC entry 5162 (class 1259 OID 17016)
-- Name: idx_game_templates_active; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_game_templates_active ON public.game_templates USING btree (is_active);


--
-- TOC entry 5163 (class 1259 OID 17012)
-- Name: idx_game_templates_category; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_game_templates_category ON public.game_templates USING btree (category);


--
-- TOC entry 5164 (class 1259 OID 17011)
-- Name: idx_game_templates_engine; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_game_templates_engine ON public.game_templates USING btree (engine);


--
-- TOC entry 5165 (class 1259 OID 17015)
-- Name: idx_game_templates_featured; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_game_templates_featured ON public.game_templates USING btree (is_featured);


--
-- TOC entry 5166 (class 1259 OID 17013)
-- Name: idx_game_templates_genre; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_game_templates_genre ON public.game_templates USING btree (genre);


--
-- TOC entry 5167 (class 1259 OID 17014)
-- Name: idx_game_templates_slug; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_game_templates_slug ON public.game_templates USING btree (slug);


--
-- TOC entry 5168 (class 1259 OID 17017)
-- Name: idx_game_templates_tags; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_game_templates_tags ON public.game_templates USING gin (tags);


--
-- TOC entry 5204 (class 1259 OID 17041)
-- Name: idx_ml_models_created_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_ml_models_created_at ON public.ml_models USING btree (created_at);


--
-- TOC entry 5205 (class 1259 OID 17039)
-- Name: idx_ml_models_project_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_ml_models_project_id ON public.ml_models USING btree (project_id);


--
-- TOC entry 5206 (class 1259 OID 17040)
-- Name: idx_ml_models_trained_by; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_ml_models_trained_by ON public.ml_models USING btree (trained_by);


--
-- TOC entry 5269 (class 1259 OID 17245)
-- Name: idx_presigned_urls_expires; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_presigned_urls_expires ON public.presigned_urls USING btree (expires_at);


--
-- TOC entry 5270 (class 1259 OID 17244)
-- Name: idx_presigned_urls_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_presigned_urls_user_id ON public.presigned_urls USING btree (user_id);


--
-- TOC entry 5183 (class 1259 OID 17027)
-- Name: idx_project_collaborators_project_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_project_collaborators_project_id ON public.project_collaborators USING btree (project_id);


--
-- TOC entry 5184 (class 1259 OID 17028)
-- Name: idx_project_collaborators_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_project_collaborators_user_id ON public.project_collaborators USING btree (user_id);


--
-- TOC entry 5169 (class 1259 OID 17021)
-- Name: idx_projects_created_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_projects_created_at ON public.projects USING btree (created_at);


--
-- TOC entry 5170 (class 1259 OID 17023)
-- Name: idx_projects_engine; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_projects_engine ON public.projects USING btree (engine);


--
-- TOC entry 5171 (class 1259 OID 17024)
-- Name: idx_projects_genre; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_projects_genre ON public.projects USING btree (genre);


--
-- TOC entry 5172 (class 1259 OID 17018)
-- Name: idx_projects_owner_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_projects_owner_id ON public.projects USING btree (owner_id);


--
-- TOC entry 5173 (class 1259 OID 17054)
-- Name: idx_projects_search; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_projects_search ON public.projects USING gin (to_tsvector('english'::regconfig, (((name)::text || ' '::text) || COALESCE(description, ''::text))));


--
-- TOC entry 5174 (class 1259 OID 17019)
-- Name: idx_projects_slug; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_projects_slug ON public.projects USING btree (slug);


--
-- TOC entry 5175 (class 1259 OID 17020)
-- Name: idx_projects_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_projects_status ON public.projects USING btree (status);


--
-- TOC entry 5176 (class 1259 OID 17025)
-- Name: idx_projects_tags; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_projects_tags ON public.projects USING gin (tags);


--
-- TOC entry 5177 (class 1259 OID 17026)
-- Name: idx_projects_target_platforms; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_projects_target_platforms ON public.projects USING gin (target_platforms);


--
-- TOC entry 5178 (class 1259 OID 17022)
-- Name: idx_projects_template_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_projects_template_id ON public.projects USING btree (template_id);


--
-- TOC entry 5241 (class 1259 OID 17098)
-- Name: idx_schema_migrations_applied_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_schema_migrations_applied_at ON public.schema_migrations USING btree (applied_at);


--
-- TOC entry 5242 (class 1259 OID 17097)
-- Name: idx_schema_migrations_version; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_schema_migrations_version ON public.schema_migrations USING btree (version);


--
-- TOC entry 5255 (class 1259 OID 17239)
-- Name: idx_storage_configs_active; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_storage_configs_active ON public.storage_configs USING btree (is_active);


--
-- TOC entry 5256 (class 1259 OID 17238)
-- Name: idx_storage_configs_provider; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_storage_configs_provider ON public.storage_configs USING btree (provider);


--
-- TOC entry 5247 (class 1259 OID 17124)
-- Name: idx_user_permissions_expires; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_user_permissions_expires ON public.user_permissions USING btree (expires_at);


--
-- TOC entry 5248 (class 1259 OID 17122)
-- Name: idx_user_permissions_permission; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_user_permissions_permission ON public.user_permissions USING btree (permission);


--
-- TOC entry 5249 (class 1259 OID 17123)
-- Name: idx_user_permissions_resource; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_user_permissions_resource ON public.user_permissions USING btree (resource_type, resource_id);


--
-- TOC entry 5250 (class 1259 OID 17121)
-- Name: idx_user_permissions_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_user_permissions_user_id ON public.user_permissions USING btree (user_id);


--
-- TOC entry 5153 (class 1259 OID 17010)
-- Name: idx_user_preferences_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_user_preferences_user_id ON public.user_preferences USING btree (user_id);


--
-- TOC entry 5224 (class 1259 OID 17051)
-- Name: idx_user_sessions_expires_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_user_sessions_expires_at ON public.user_sessions USING btree (expires_at);


--
-- TOC entry 5225 (class 1259 OID 17050)
-- Name: idx_user_sessions_token; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_user_sessions_token ON public.user_sessions USING btree (session_token);


--
-- TOC entry 5226 (class 1259 OID 17049)
-- Name: idx_user_sessions_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_user_sessions_user_id ON public.user_sessions USING btree (user_id);


--
-- TOC entry 5138 (class 1259 OID 17006)
-- Name: idx_users_created_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_users_created_at ON public.users USING btree (created_at);


--
-- TOC entry 5139 (class 1259 OID 17003)
-- Name: idx_users_email; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_users_email ON public.users USING btree (email);


--
-- TOC entry 5140 (class 1259 OID 17008)
-- Name: idx_users_github_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_users_github_id ON public.users USING btree (github_id);


--
-- TOC entry 5141 (class 1259 OID 17007)
-- Name: idx_users_provider; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_users_provider ON public.users USING btree (provider);


--
-- TOC entry 5142 (class 1259 OID 17009)
-- Name: idx_users_provider_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_users_provider_id ON public.users USING btree (provider_id);


--
-- TOC entry 5143 (class 1259 OID 17005)
-- Name: idx_users_role; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_users_role ON public.users USING btree (role);


--
-- TOC entry 5144 (class 1259 OID 17004)
-- Name: idx_users_username; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_users_username ON public.users USING btree (username);


--
-- TOC entry 5308 (class 2620 OID 17272)
-- Name: users assign_permissions_trigger; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER assign_permissions_trigger AFTER INSERT OR UPDATE OF role ON public.users FOR EACH ROW EXECUTE FUNCTION public.trigger_assign_permissions();


--
-- TOC entry 5314 (class 2620 OID 17062)
-- Name: ai_requests update_ai_requests_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER update_ai_requests_updated_at BEFORE UPDATE ON public.ai_requests FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- TOC entry 5313 (class 2620 OID 17061)
-- Name: assets update_assets_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER update_assets_updated_at BEFORE UPDATE ON public.assets FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- TOC entry 5316 (class 2620 OID 17064)
-- Name: datasets update_datasets_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER update_datasets_updated_at BEFORE UPDATE ON public.datasets FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- TOC entry 5311 (class 2620 OID 17059)
-- Name: game_templates update_game_templates_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER update_game_templates_updated_at BEFORE UPDATE ON public.game_templates FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- TOC entry 5315 (class 2620 OID 17063)
-- Name: ml_models update_ml_models_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER update_ml_models_updated_at BEFORE UPDATE ON public.ml_models FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- TOC entry 5312 (class 2620 OID 17060)
-- Name: projects update_projects_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER update_projects_updated_at BEFORE UPDATE ON public.projects FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- TOC entry 5310 (class 2620 OID 17058)
-- Name: user_preferences update_user_preferences_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER update_user_preferences_updated_at BEFORE UPDATE ON public.user_preferences FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- TOC entry 5309 (class 2620 OID 17057)
-- Name: users update_users_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON public.users FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- TOC entry 5305 (class 2606 OID 17216)
-- Name: access_tokens access_tokens_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.access_tokens
    ADD CONSTRAINT access_tokens_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- TOC entry 5291 (class 2606 OID 16868)
-- Name: ai_requests ai_requests_project_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ai_requests
    ADD CONSTRAINT ai_requests_project_id_fkey FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE SET NULL;


--
-- TOC entry 5292 (class 2606 OID 16863)
-- Name: ai_requests ai_requests_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ai_requests
    ADD CONSTRAINT ai_requests_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- TOC entry 5301 (class 2606 OID 16984)
-- Name: api_keys api_keys_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.api_keys
    ADD CONSTRAINT api_keys_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- TOC entry 5288 (class 2606 OID 16836)
-- Name: assets assets_parent_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.assets
    ADD CONSTRAINT assets_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES public.assets(id) ON DELETE CASCADE;


--
-- TOC entry 5289 (class 2606 OID 16831)
-- Name: assets assets_project_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.assets
    ADD CONSTRAINT assets_project_id_fkey FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;


--
-- TOC entry 5290 (class 2606 OID 16841)
-- Name: assets assets_uploaded_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.assets
    ADD CONSTRAINT assets_uploaded_by_fkey FOREIGN KEY (uploaded_by) REFERENCES public.users(id);


--
-- TOC entry 5299 (class 2606 OID 16945)
-- Name: audit_logs audit_logs_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.audit_logs
    ADD CONSTRAINT audit_logs_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- TOC entry 5307 (class 2606 OID 17261)
-- Name: compliance_events compliance_events_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.compliance_events
    ADD CONSTRAINT compliance_events_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- TOC entry 5296 (class 2606 OID 16924)
-- Name: datasets datasets_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.datasets
    ADD CONSTRAINT datasets_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id);


--
-- TOC entry 5297 (class 2606 OID 16929)
-- Name: datasets datasets_parent_dataset_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.datasets
    ADD CONSTRAINT datasets_parent_dataset_id_fkey FOREIGN KEY (parent_dataset_id) REFERENCES public.datasets(id);


--
-- TOC entry 5298 (class 2606 OID 16919)
-- Name: datasets datasets_project_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.datasets
    ADD CONSTRAINT datasets_project_id_fkey FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;


--
-- TOC entry 5280 (class 2606 OID 16754)
-- Name: game_templates game_templates_approved_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.game_templates
    ADD CONSTRAINT game_templates_approved_by_fkey FOREIGN KEY (approved_by) REFERENCES public.users(id);


--
-- TOC entry 5281 (class 2606 OID 16744)
-- Name: game_templates game_templates_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.game_templates
    ADD CONSTRAINT game_templates_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id);


--
-- TOC entry 5282 (class 2606 OID 16749)
-- Name: game_templates game_templates_updated_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.game_templates
    ADD CONSTRAINT game_templates_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES public.users(id);


--
-- TOC entry 5293 (class 2606 OID 16889)
-- Name: ml_models ml_models_project_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ml_models
    ADD CONSTRAINT ml_models_project_id_fkey FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;


--
-- TOC entry 5294 (class 2606 OID 16899)
-- Name: ml_models ml_models_trained_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ml_models
    ADD CONSTRAINT ml_models_trained_by_fkey FOREIGN KEY (trained_by) REFERENCES public.users(id);


--
-- TOC entry 5295 (class 2606 OID 16894)
-- Name: ml_models ml_models_training_data_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ml_models
    ADD CONSTRAINT ml_models_training_data_id_fkey FOREIGN KEY (training_data_id) REFERENCES public.assets(id);


--
-- TOC entry 5306 (class 2606 OID 17233)
-- Name: presigned_urls presigned_urls_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.presigned_urls
    ADD CONSTRAINT presigned_urls_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- TOC entry 5285 (class 2606 OID 16811)
-- Name: project_collaborators project_collaborators_invited_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.project_collaborators
    ADD CONSTRAINT project_collaborators_invited_by_fkey FOREIGN KEY (invited_by) REFERENCES public.users(id);


--
-- TOC entry 5286 (class 2606 OID 16801)
-- Name: project_collaborators project_collaborators_project_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.project_collaborators
    ADD CONSTRAINT project_collaborators_project_id_fkey FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;


--
-- TOC entry 5287 (class 2606 OID 16806)
-- Name: project_collaborators project_collaborators_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.project_collaborators
    ADD CONSTRAINT project_collaborators_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- TOC entry 5283 (class 2606 OID 16777)
-- Name: projects projects_owner_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.projects
    ADD CONSTRAINT projects_owner_id_fkey FOREIGN KEY (owner_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- TOC entry 5284 (class 2606 OID 16782)
-- Name: projects projects_template_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.projects
    ADD CONSTRAINT projects_template_id_fkey FOREIGN KEY (template_id) REFERENCES public.game_templates(id);


--
-- TOC entry 5302 (class 2606 OID 16998)
-- Name: system_config system_config_updated_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.system_config
    ADD CONSTRAINT system_config_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES public.users(id);


--
-- TOC entry 5303 (class 2606 OID 17116)
-- Name: user_permissions user_permissions_granted_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_permissions
    ADD CONSTRAINT user_permissions_granted_by_fkey FOREIGN KEY (granted_by) REFERENCES public.users(id);


--
-- TOC entry 5304 (class 2606 OID 17111)
-- Name: user_permissions user_permissions_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_permissions
    ADD CONSTRAINT user_permissions_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- TOC entry 5279 (class 2606 OID 16720)
-- Name: user_preferences user_preferences_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_preferences
    ADD CONSTRAINT user_preferences_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- TOC entry 5300 (class 2606 OID 16965)
-- Name: user_sessions user_sessions_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_sessions
    ADD CONSTRAINT user_sessions_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- TOC entry 5488 (class 0 OID 0)
-- Dependencies: 8
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: pg_database_owner
--

GRANT USAGE ON SCHEMA public TO gameforge_readonly;


--
-- TOC entry 5492 (class 0 OID 0)
-- Dependencies: 275
-- Name: FUNCTION citextin(cstring); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.citextin(cstring) TO gameforge_user;


--
-- TOC entry 5493 (class 0 OID 0)
-- Dependencies: 270
-- Name: FUNCTION citextout(public.citext); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.citextout(public.citext) TO gameforge_user;


--
-- TOC entry 5494 (class 0 OID 0)
-- Dependencies: 287
-- Name: FUNCTION citextrecv(internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.citextrecv(internal) TO gameforge_user;


--
-- TOC entry 5495 (class 0 OID 0)
-- Dependencies: 317
-- Name: FUNCTION citextsend(public.citext); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.citextsend(public.citext) TO gameforge_user;


--
-- TOC entry 5496 (class 0 OID 0)
-- Dependencies: 323
-- Name: FUNCTION gtrgm_in(cstring); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.gtrgm_in(cstring) TO gameforge_user;


--
-- TOC entry 5497 (class 0 OID 0)
-- Dependencies: 330
-- Name: FUNCTION gtrgm_out(public.gtrgm); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.gtrgm_out(public.gtrgm) TO gameforge_user;


--
-- TOC entry 5498 (class 0 OID 0)
-- Dependencies: 312
-- Name: FUNCTION citext(boolean); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.citext(boolean) TO gameforge_user;


--
-- TOC entry 5499 (class 0 OID 0)
-- Dependencies: 253
-- Name: FUNCTION citext(character); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.citext(character) TO gameforge_user;


--
-- TOC entry 5500 (class 0 OID 0)
-- Dependencies: 318
-- Name: FUNCTION citext(inet); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.citext(inet) TO gameforge_user;


--
-- TOC entry 5501 (class 0 OID 0)
-- Dependencies: 258
-- Name: FUNCTION citext_cmp(public.citext, public.citext); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.citext_cmp(public.citext, public.citext) TO gameforge_user;


--
-- TOC entry 5502 (class 0 OID 0)
-- Dependencies: 286
-- Name: FUNCTION citext_eq(public.citext, public.citext); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.citext_eq(public.citext, public.citext) TO gameforge_user;


--
-- TOC entry 5503 (class 0 OID 0)
-- Dependencies: 267
-- Name: FUNCTION citext_ge(public.citext, public.citext); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.citext_ge(public.citext, public.citext) TO gameforge_user;


--
-- TOC entry 5504 (class 0 OID 0)
-- Dependencies: 303
-- Name: FUNCTION citext_gt(public.citext, public.citext); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.citext_gt(public.citext, public.citext) TO gameforge_user;


--
-- TOC entry 5505 (class 0 OID 0)
-- Dependencies: 266
-- Name: FUNCTION citext_hash(public.citext); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.citext_hash(public.citext) TO gameforge_user;


--
-- TOC entry 5506 (class 0 OID 0)
-- Dependencies: 335
-- Name: FUNCTION citext_hash_extended(public.citext, bigint); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.citext_hash_extended(public.citext, bigint) TO gameforge_user;


--
-- TOC entry 5507 (class 0 OID 0)
-- Dependencies: 250
-- Name: FUNCTION citext_larger(public.citext, public.citext); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.citext_larger(public.citext, public.citext) TO gameforge_user;


--
-- TOC entry 5508 (class 0 OID 0)
-- Dependencies: 328
-- Name: FUNCTION citext_le(public.citext, public.citext); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.citext_le(public.citext, public.citext) TO gameforge_user;


--
-- TOC entry 5509 (class 0 OID 0)
-- Dependencies: 304
-- Name: FUNCTION citext_lt(public.citext, public.citext); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.citext_lt(public.citext, public.citext) TO gameforge_user;


--
-- TOC entry 5510 (class 0 OID 0)
-- Dependencies: 290
-- Name: FUNCTION citext_ne(public.citext, public.citext); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.citext_ne(public.citext, public.citext) TO gameforge_user;


--
-- TOC entry 5511 (class 0 OID 0)
-- Dependencies: 252
-- Name: FUNCTION citext_pattern_cmp(public.citext, public.citext); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.citext_pattern_cmp(public.citext, public.citext) TO gameforge_user;


--
-- TOC entry 5512 (class 0 OID 0)
-- Dependencies: 268
-- Name: FUNCTION citext_pattern_ge(public.citext, public.citext); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.citext_pattern_ge(public.citext, public.citext) TO gameforge_user;


--
-- TOC entry 5513 (class 0 OID 0)
-- Dependencies: 307
-- Name: FUNCTION citext_pattern_gt(public.citext, public.citext); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.citext_pattern_gt(public.citext, public.citext) TO gameforge_user;


--
-- TOC entry 5514 (class 0 OID 0)
-- Dependencies: 297
-- Name: FUNCTION citext_pattern_le(public.citext, public.citext); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.citext_pattern_le(public.citext, public.citext) TO gameforge_user;


--
-- TOC entry 5515 (class 0 OID 0)
-- Dependencies: 296
-- Name: FUNCTION citext_pattern_lt(public.citext, public.citext); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.citext_pattern_lt(public.citext, public.citext) TO gameforge_user;


--
-- TOC entry 5516 (class 0 OID 0)
-- Dependencies: 308
-- Name: FUNCTION citext_smaller(public.citext, public.citext); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.citext_smaller(public.citext, public.citext) TO gameforge_user;


--
-- TOC entry 5517 (class 0 OID 0)
-- Dependencies: 294
-- Name: FUNCTION create_project_with_owner(p_owner_id uuid, p_name character varying, p_description text, p_is_public boolean); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.create_project_with_owner(p_owner_id uuid, p_name character varying, p_description text, p_is_public boolean) TO gameforge_user;


--
-- TOC entry 5518 (class 0 OID 0)
-- Dependencies: 295
-- Name: FUNCTION gin_extract_query_trgm(text, internal, smallint, internal, internal, internal, internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.gin_extract_query_trgm(text, internal, smallint, internal, internal, internal, internal) TO gameforge_user;


--
-- TOC entry 5519 (class 0 OID 0)
-- Dependencies: 254
-- Name: FUNCTION gin_extract_value_trgm(text, internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.gin_extract_value_trgm(text, internal) TO gameforge_user;


--
-- TOC entry 5520 (class 0 OID 0)
-- Dependencies: 247
-- Name: FUNCTION gin_trgm_consistent(internal, smallint, text, integer, internal, internal, internal, internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.gin_trgm_consistent(internal, smallint, text, integer, internal, internal, internal, internal) TO gameforge_user;


--
-- TOC entry 5521 (class 0 OID 0)
-- Dependencies: 260
-- Name: FUNCTION gin_trgm_triconsistent(internal, smallint, text, integer, internal, internal, internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.gin_trgm_triconsistent(internal, smallint, text, integer, internal, internal, internal) TO gameforge_user;


--
-- TOC entry 5522 (class 0 OID 0)
-- Dependencies: 277
-- Name: FUNCTION gtrgm_compress(internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.gtrgm_compress(internal) TO gameforge_user;


--
-- TOC entry 5523 (class 0 OID 0)
-- Dependencies: 259
-- Name: FUNCTION gtrgm_consistent(internal, text, smallint, oid, internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.gtrgm_consistent(internal, text, smallint, oid, internal) TO gameforge_user;


--
-- TOC entry 5524 (class 0 OID 0)
-- Dependencies: 283
-- Name: FUNCTION gtrgm_decompress(internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.gtrgm_decompress(internal) TO gameforge_user;


--
-- TOC entry 5525 (class 0 OID 0)
-- Dependencies: 249
-- Name: FUNCTION gtrgm_distance(internal, text, smallint, oid, internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.gtrgm_distance(internal, text, smallint, oid, internal) TO gameforge_user;


--
-- TOC entry 5526 (class 0 OID 0)
-- Dependencies: 289
-- Name: FUNCTION gtrgm_options(internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.gtrgm_options(internal) TO gameforge_user;


--
-- TOC entry 5527 (class 0 OID 0)
-- Dependencies: 343
-- Name: FUNCTION gtrgm_penalty(internal, internal, internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.gtrgm_penalty(internal, internal, internal) TO gameforge_user;


--
-- TOC entry 5528 (class 0 OID 0)
-- Dependencies: 340
-- Name: FUNCTION gtrgm_picksplit(internal, internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.gtrgm_picksplit(internal, internal) TO gameforge_user;


--
-- TOC entry 5529 (class 0 OID 0)
-- Dependencies: 262
-- Name: FUNCTION gtrgm_same(public.gtrgm, public.gtrgm, internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.gtrgm_same(public.gtrgm, public.gtrgm, internal) TO gameforge_user;


--
-- TOC entry 5530 (class 0 OID 0)
-- Dependencies: 342
-- Name: FUNCTION gtrgm_union(internal, internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.gtrgm_union(internal, internal) TO gameforge_user;


--
-- TOC entry 5531 (class 0 OID 0)
-- Dependencies: 273
-- Name: FUNCTION regexp_match(public.citext, public.citext); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.regexp_match(public.citext, public.citext) TO gameforge_user;


--
-- TOC entry 5532 (class 0 OID 0)
-- Dependencies: 264
-- Name: FUNCTION regexp_match(public.citext, public.citext, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.regexp_match(public.citext, public.citext, text) TO gameforge_user;


--
-- TOC entry 5533 (class 0 OID 0)
-- Dependencies: 248
-- Name: FUNCTION regexp_matches(public.citext, public.citext); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.regexp_matches(public.citext, public.citext) TO gameforge_user;


--
-- TOC entry 5534 (class 0 OID 0)
-- Dependencies: 315
-- Name: FUNCTION regexp_matches(public.citext, public.citext, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.regexp_matches(public.citext, public.citext, text) TO gameforge_user;


--
-- TOC entry 5535 (class 0 OID 0)
-- Dependencies: 276
-- Name: FUNCTION regexp_replace(public.citext, public.citext, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.regexp_replace(public.citext, public.citext, text) TO gameforge_user;


--
-- TOC entry 5536 (class 0 OID 0)
-- Dependencies: 302
-- Name: FUNCTION regexp_replace(public.citext, public.citext, text, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.regexp_replace(public.citext, public.citext, text, text) TO gameforge_user;


--
-- TOC entry 5537 (class 0 OID 0)
-- Dependencies: 320
-- Name: FUNCTION regexp_split_to_array(public.citext, public.citext); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.regexp_split_to_array(public.citext, public.citext) TO gameforge_user;


--
-- TOC entry 5538 (class 0 OID 0)
-- Dependencies: 257
-- Name: FUNCTION regexp_split_to_array(public.citext, public.citext, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.regexp_split_to_array(public.citext, public.citext, text) TO gameforge_user;


--
-- TOC entry 5539 (class 0 OID 0)
-- Dependencies: 246
-- Name: FUNCTION regexp_split_to_table(public.citext, public.citext); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.regexp_split_to_table(public.citext, public.citext) TO gameforge_user;


--
-- TOC entry 5540 (class 0 OID 0)
-- Dependencies: 284
-- Name: FUNCTION regexp_split_to_table(public.citext, public.citext, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.regexp_split_to_table(public.citext, public.citext, text) TO gameforge_user;


--
-- TOC entry 5541 (class 0 OID 0)
-- Dependencies: 305
-- Name: FUNCTION replace(public.citext, public.citext, public.citext); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.replace(public.citext, public.citext, public.citext) TO gameforge_user;


--
-- TOC entry 5542 (class 0 OID 0)
-- Dependencies: 243
-- Name: FUNCTION set_limit(real); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.set_limit(real) TO gameforge_user;


--
-- TOC entry 5543 (class 0 OID 0)
-- Dependencies: 256
-- Name: FUNCTION show_limit(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.show_limit() TO gameforge_user;


--
-- TOC entry 5544 (class 0 OID 0)
-- Dependencies: 314
-- Name: FUNCTION show_trgm(text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.show_trgm(text) TO gameforge_user;


--
-- TOC entry 5545 (class 0 OID 0)
-- Dependencies: 309
-- Name: FUNCTION similarity(text, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.similarity(text, text) TO gameforge_user;


--
-- TOC entry 5546 (class 0 OID 0)
-- Dependencies: 306
-- Name: FUNCTION similarity_dist(text, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.similarity_dist(text, text) TO gameforge_user;


--
-- TOC entry 5547 (class 0 OID 0)
-- Dependencies: 280
-- Name: FUNCTION similarity_op(text, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.similarity_op(text, text) TO gameforge_user;


--
-- TOC entry 5548 (class 0 OID 0)
-- Dependencies: 333
-- Name: FUNCTION split_part(public.citext, public.citext, integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.split_part(public.citext, public.citext, integer) TO gameforge_user;


--
-- TOC entry 5549 (class 0 OID 0)
-- Dependencies: 261
-- Name: FUNCTION strict_word_similarity(text, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.strict_word_similarity(text, text) TO gameforge_user;


--
-- TOC entry 5550 (class 0 OID 0)
-- Dependencies: 293
-- Name: FUNCTION strict_word_similarity_commutator_op(text, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.strict_word_similarity_commutator_op(text, text) TO gameforge_user;


--
-- TOC entry 5551 (class 0 OID 0)
-- Dependencies: 278
-- Name: FUNCTION strict_word_similarity_dist_commutator_op(text, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.strict_word_similarity_dist_commutator_op(text, text) TO gameforge_user;


--
-- TOC entry 5552 (class 0 OID 0)
-- Dependencies: 316
-- Name: FUNCTION strict_word_similarity_dist_op(text, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.strict_word_similarity_dist_op(text, text) TO gameforge_user;


--
-- TOC entry 5553 (class 0 OID 0)
-- Dependencies: 279
-- Name: FUNCTION strict_word_similarity_op(text, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.strict_word_similarity_op(text, text) TO gameforge_user;


--
-- TOC entry 5554 (class 0 OID 0)
-- Dependencies: 325
-- Name: FUNCTION strpos(public.citext, public.citext); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.strpos(public.citext, public.citext) TO gameforge_user;


--
-- TOC entry 5555 (class 0 OID 0)
-- Dependencies: 242
-- Name: FUNCTION texticlike(public.citext, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.texticlike(public.citext, text) TO gameforge_user;


--
-- TOC entry 5556 (class 0 OID 0)
-- Dependencies: 285
-- Name: FUNCTION texticlike(public.citext, public.citext); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.texticlike(public.citext, public.citext) TO gameforge_user;


--
-- TOC entry 5557 (class 0 OID 0)
-- Dependencies: 334
-- Name: FUNCTION texticnlike(public.citext, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.texticnlike(public.citext, text) TO gameforge_user;


--
-- TOC entry 5558 (class 0 OID 0)
-- Dependencies: 329
-- Name: FUNCTION texticnlike(public.citext, public.citext); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.texticnlike(public.citext, public.citext) TO gameforge_user;


--
-- TOC entry 5559 (class 0 OID 0)
-- Dependencies: 326
-- Name: FUNCTION texticregexeq(public.citext, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.texticregexeq(public.citext, text) TO gameforge_user;


--
-- TOC entry 5560 (class 0 OID 0)
-- Dependencies: 321
-- Name: FUNCTION texticregexeq(public.citext, public.citext); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.texticregexeq(public.citext, public.citext) TO gameforge_user;


--
-- TOC entry 5561 (class 0 OID 0)
-- Dependencies: 332
-- Name: FUNCTION texticregexne(public.citext, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.texticregexne(public.citext, text) TO gameforge_user;


--
-- TOC entry 5562 (class 0 OID 0)
-- Dependencies: 324
-- Name: FUNCTION texticregexne(public.citext, public.citext); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.texticregexne(public.citext, public.citext) TO gameforge_user;


--
-- TOC entry 5563 (class 0 OID 0)
-- Dependencies: 288
-- Name: FUNCTION translate(public.citext, public.citext, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.translate(public.citext, public.citext, text) TO gameforge_user;


--
-- TOC entry 5564 (class 0 OID 0)
-- Dependencies: 338
-- Name: FUNCTION update_updated_at_column(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.update_updated_at_column() TO gameforge_user;


--
-- TOC entry 5565 (class 0 OID 0)
-- Dependencies: 274
-- Name: FUNCTION uuid_generate_v1(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.uuid_generate_v1() TO gameforge_user;


--
-- TOC entry 5566 (class 0 OID 0)
-- Dependencies: 331
-- Name: FUNCTION uuid_generate_v1mc(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.uuid_generate_v1mc() TO gameforge_user;


--
-- TOC entry 5567 (class 0 OID 0)
-- Dependencies: 244
-- Name: FUNCTION uuid_generate_v3(namespace uuid, name text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.uuid_generate_v3(namespace uuid, name text) TO gameforge_user;


--
-- TOC entry 5568 (class 0 OID 0)
-- Dependencies: 298
-- Name: FUNCTION uuid_generate_v4(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.uuid_generate_v4() TO gameforge_user;


--
-- TOC entry 5569 (class 0 OID 0)
-- Dependencies: 310
-- Name: FUNCTION uuid_generate_v5(namespace uuid, name text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.uuid_generate_v5(namespace uuid, name text) TO gameforge_user;


--
-- TOC entry 5570 (class 0 OID 0)
-- Dependencies: 341
-- Name: FUNCTION uuid_nil(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.uuid_nil() TO gameforge_user;


--
-- TOC entry 5571 (class 0 OID 0)
-- Dependencies: 337
-- Name: FUNCTION uuid_ns_dns(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.uuid_ns_dns() TO gameforge_user;


--
-- TOC entry 5572 (class 0 OID 0)
-- Dependencies: 263
-- Name: FUNCTION uuid_ns_oid(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.uuid_ns_oid() TO gameforge_user;


--
-- TOC entry 5573 (class 0 OID 0)
-- Dependencies: 269
-- Name: FUNCTION uuid_ns_url(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.uuid_ns_url() TO gameforge_user;


--
-- TOC entry 5574 (class 0 OID 0)
-- Dependencies: 282
-- Name: FUNCTION uuid_ns_x500(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.uuid_ns_x500() TO gameforge_user;


--
-- TOC entry 5575 (class 0 OID 0)
-- Dependencies: 291
-- Name: FUNCTION word_similarity(text, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.word_similarity(text, text) TO gameforge_user;


--
-- TOC entry 5576 (class 0 OID 0)
-- Dependencies: 245
-- Name: FUNCTION word_similarity_commutator_op(text, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.word_similarity_commutator_op(text, text) TO gameforge_user;


--
-- TOC entry 5577 (class 0 OID 0)
-- Dependencies: 336
-- Name: FUNCTION word_similarity_dist_commutator_op(text, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.word_similarity_dist_commutator_op(text, text) TO gameforge_user;


--
-- TOC entry 5578 (class 0 OID 0)
-- Dependencies: 272
-- Name: FUNCTION word_similarity_dist_op(text, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.word_similarity_dist_op(text, text) TO gameforge_user;


--
-- TOC entry 5579 (class 0 OID 0)
-- Dependencies: 300
-- Name: FUNCTION word_similarity_op(text, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.word_similarity_op(text, text) TO gameforge_user;


--
-- TOC entry 5580 (class 0 OID 0)
-- Dependencies: 1052
-- Name: FUNCTION max(public.citext); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.max(public.citext) TO gameforge_user;


--
-- TOC entry 5581 (class 0 OID 0)
-- Dependencies: 1051
-- Name: FUNCTION min(public.citext); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.min(public.citext) TO gameforge_user;


--
-- TOC entry 5582 (class 0 OID 0)
-- Dependencies: 224
-- Name: TABLE ai_requests; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.ai_requests TO gameforge_readonly;
GRANT ALL ON TABLE public.ai_requests TO gameforge_user;


--
-- TOC entry 5583 (class 0 OID 0)
-- Dependencies: 229
-- Name: TABLE api_keys; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.api_keys TO gameforge_readonly;
GRANT ALL ON TABLE public.api_keys TO gameforge_user;


--
-- TOC entry 5584 (class 0 OID 0)
-- Dependencies: 223
-- Name: TABLE assets; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.assets TO gameforge_readonly;
GRANT ALL ON TABLE public.assets TO gameforge_user;


--
-- TOC entry 5585 (class 0 OID 0)
-- Dependencies: 227
-- Name: TABLE audit_logs; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.audit_logs TO gameforge_readonly;
GRANT ALL ON TABLE public.audit_logs TO gameforge_user;


--
-- TOC entry 5586 (class 0 OID 0)
-- Dependencies: 226
-- Name: TABLE datasets; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.datasets TO gameforge_readonly;
GRANT ALL ON TABLE public.datasets TO gameforge_user;


--
-- TOC entry 5587 (class 0 OID 0)
-- Dependencies: 220
-- Name: TABLE game_templates; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.game_templates TO gameforge_readonly;
GRANT ALL ON TABLE public.game_templates TO gameforge_user;


--
-- TOC entry 5588 (class 0 OID 0)
-- Dependencies: 225
-- Name: TABLE ml_models; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.ml_models TO gameforge_readonly;
GRANT ALL ON TABLE public.ml_models TO gameforge_user;


--
-- TOC entry 5589 (class 0 OID 0)
-- Dependencies: 222
-- Name: TABLE project_collaborators; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.project_collaborators TO gameforge_readonly;
GRANT ALL ON TABLE public.project_collaborators TO gameforge_user;


--
-- TOC entry 5590 (class 0 OID 0)
-- Dependencies: 221
-- Name: TABLE projects; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.projects TO gameforge_readonly;
GRANT ALL ON TABLE public.projects TO gameforge_user;


--
-- TOC entry 5591 (class 0 OID 0)
-- Dependencies: 232
-- Name: TABLE project_stats; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.project_stats TO gameforge_readonly;
GRANT ALL ON TABLE public.project_stats TO gameforge_user;


--
-- TOC entry 5593 (class 0 OID 0)
-- Dependencies: 230
-- Name: TABLE system_config; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.system_config TO gameforge_readonly;
GRANT ALL ON TABLE public.system_config TO gameforge_user;


--
-- TOC entry 5594 (class 0 OID 0)
-- Dependencies: 219
-- Name: TABLE user_preferences; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.user_preferences TO gameforge_readonly;
GRANT ALL ON TABLE public.user_preferences TO gameforge_user;


--
-- TOC entry 5595 (class 0 OID 0)
-- Dependencies: 228
-- Name: TABLE user_sessions; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.user_sessions TO gameforge_readonly;
GRANT ALL ON TABLE public.user_sessions TO gameforge_user;


--
-- TOC entry 5596 (class 0 OID 0)
-- Dependencies: 218
-- Name: TABLE users; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.users TO gameforge_readonly;
GRANT ALL ON TABLE public.users TO gameforge_user;


--
-- TOC entry 5597 (class 0 OID 0)
-- Dependencies: 231
-- Name: TABLE user_stats; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.user_stats TO gameforge_readonly;
GRANT ALL ON TABLE public.user_stats TO gameforge_user;


-- Completed on 2025-09-16 20:55:45

--
-- PostgreSQL database dump complete
--

\unrestrict tCnvbjie3crbjmQ9GfugKYkUWvLaIcof2oeHYQxpHdXflJEk4YX2YzZp9FHhNYc

