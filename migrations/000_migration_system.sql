-- Migration Tracking System for GameForge
-- This creates the infrastructure needed to track schema migrations

BEGIN;

-- Create migrations tracking table
CREATE TABLE IF NOT EXISTS schema_migrations (
    id SERIAL PRIMARY KEY,
    version VARCHAR(255) UNIQUE NOT NULL,
    description TEXT,
    checksum VARCHAR(64),
    applied_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    applied_by VARCHAR(255) DEFAULT current_user,
    execution_time_ms INTEGER,
    script_path TEXT
);

-- Create migration status view
CREATE OR REPLACE VIEW migration_status AS
SELECT 
    sm.version,
    sm.description,
    sm.applied_at,
    sm.applied_by,
    sm.execution_time_ms,
    CASE 
        WHEN sm.applied_at IS NOT NULL THEN 'APPLIED'
        ELSE 'PENDING'
    END as status
FROM schema_migrations sm
ORDER BY sm.version;

-- Insert baseline migration record
INSERT INTO schema_migrations (version, description, checksum, applied_by, script_path)
VALUES (
    '000_baseline',
    'Initial GameForge schema baseline',
    'baseline',
    'system',
    'schema.sql'
) ON CONFLICT (version) DO NOTHING;

-- Function to validate migration checksums
CREATE OR REPLACE FUNCTION validate_migration_checksum(
    migration_version VARCHAR(255),
    expected_checksum VARCHAR(64)
) RETURNS BOOLEAN AS $$
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
$$ LANGUAGE plpgsql;

-- Function to record migration application
CREATE OR REPLACE FUNCTION record_migration(
    migration_version VARCHAR(255),
    migration_description TEXT,
    migration_checksum VARCHAR(64),
    migration_path TEXT,
    execution_time INTEGER DEFAULT NULL
) RETURNS BOOLEAN AS $$
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
$$ LANGUAGE plpgsql;

-- Create index for faster lookups
CREATE INDEX IF NOT EXISTS idx_schema_migrations_version ON schema_migrations(version);
CREATE INDEX IF NOT EXISTS idx_schema_migrations_applied_at ON schema_migrations(applied_at);

COMMIT;

-- Display current migration status
SELECT 'Migration tracking system installed successfully!' as status;

SELECT * FROM migration_status;