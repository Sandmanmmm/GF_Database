-- Migration: 001_initial_schema
-- Description: Create initial GameForge database schema
-- Created: 2025-09-15
-- Author: GameForge Team

-- This migration creates the foundational schema for GameForge
-- Including users, projects, assets, AI requests, and audit logging

BEGIN;

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "citext";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- Create custom types
CREATE TYPE user_role AS ENUM ('basic_user', 'premium_user', 'admin', 'super_admin');
CREATE TYPE project_status AS ENUM ('active', 'archived', 'deleted');
CREATE TYPE asset_type AS ENUM ('model', 'dataset', 'texture', 'audio', 'script', 'config', 'other');
CREATE TYPE ai_request_type AS ENUM ('text_generation', 'image_generation', 'model_training', 'data_analysis', 'code_generation');
CREATE TYPE ai_request_status AS ENUM ('pending', 'processing', 'completed', 'failed', 'cancelled');
CREATE TYPE audit_action AS ENUM ('create', 'read', 'update', 'delete', 'login', 'logout', 'export', 'import');

-- Create migrations tracking table
CREATE TABLE IF NOT EXISTS migrations (
    id SERIAL PRIMARY KEY,
    migration_name VARCHAR(255) UNIQUE NOT NULL,
    applied_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    checksum VARCHAR(64),
    execution_time_ms INTEGER
);

-- Record this migration
INSERT INTO migrations (migration_name, checksum) 
VALUES ('001_initial_schema', md5('001_initial_schema_v1'));

COMMIT;