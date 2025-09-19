const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const rateLimit = require('express-rate-limit');
const { Pool } = require('pg');
const AIQueryService = require('./services/AIQueryService');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 5002;

// Security middleware
app.use(helmet());
app.use(cors({
  origin: process.env.FRONTEND_URL || 'http://localhost:5173',
  credentials: true
}));

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // limit each IP to 100 requests per windowMs
  message: 'Too many requests from this IP, please try again later.'
});
app.use(limiter);

// Logging
app.use(morgan('combined'));

// Body parsing
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// Database connection pools
const pools = {
  dev: new Pool({
    host: process.env.DEV_DB_HOST || 'localhost',
    port: process.env.DEV_DB_PORT || 5432,
    database: process.env.DEV_DB_NAME || 'gameforge_dev',
    user: process.env.DEV_DB_USER || 'postgres',
    password: process.env.DEV_DB_PASSWORD || 'postgres',
    max: 10,
    idleTimeoutMillis: 30000,
    connectionTimeoutMillis: 10000,
  }),
  prod: new Pool({
    host: process.env.PROD_DB_HOST || 'localhost',
    port: process.env.PROD_DB_PORT || 5432,
    database: process.env.PROD_DB_NAME || 'gameforge_prod',
    user: process.env.PROD_DB_USER || 'gameforge_prod_user',
    password: process.env.PROD_DB_PASSWORD || 'prod_secure_password_2025',
    max: 5,
    idleTimeoutMillis: 30000,
    connectionTimeoutMillis: 10000,
  })
};

// Health check endpoint
app.get('/api/health', (req, res) => {
  res.json({ status: 'OK', timestamp: new Date().toISOString() });
});

// Database status endpoint
app.get('/api/databases/status', async (req, res) => {
  try {
    const status = {};
    
    for (const [env, pool] of Object.entries(pools)) {
      try {
        const client = await pool.connect();
        const result = await client.query('SELECT current_database(), version(), now()');
        client.release();
        
        status[env] = {
          connected: true,
          database: result.rows[0].current_database,
          version: result.rows[0].version,
          timestamp: result.rows[0].now
        };
      } catch (error) {
        status[env] = {
          connected: false,
          error: error.message
        };
      }
    }
    
    res.json(status);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get table information
app.get('/api/:env/tables', async (req, res) => {
  try {
    const { env } = req.params;
    const pool = pools[env];
    
    if (!pool) {
      return res.status(400).json({ error: 'Invalid environment' });
    }
    
    const query = `
      SELECT 
        t.table_name,
        t.table_type,
        COALESCE(s.n_tup_ins, 0) as row_count,
        pg_size_pretty(pg_total_relation_size(c.oid)) as size
      FROM information_schema.tables t
      LEFT JOIN pg_stat_user_tables s ON s.relname = t.table_name
      LEFT JOIN pg_class c ON c.relname = t.table_name
      WHERE t.table_schema = 'public'
        AND t.table_type = 'BASE TABLE'
      ORDER BY t.table_name;
    `;
    
    const result = await pool.query(query);
    res.json(result.rows);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get table schema
app.get('/api/:env/tables/:tableName/schema', async (req, res) => {
  try {
    const { env, tableName } = req.params;
    const pool = pools[env];
    
    if (!pool) {
      return res.status(400).json({ error: 'Invalid environment' });
    }
    
    const query = `
      SELECT 
        column_name,
        data_type,
        is_nullable,
        column_default,
        character_maximum_length,
        numeric_precision,
        numeric_scale
      FROM information_schema.columns 
      WHERE table_schema = 'public' 
        AND table_name = $1
      ORDER BY ordinal_position;
    `;
    
    const result = await pool.query(query, [tableName]);
    res.json(result.rows);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get real-time database metrics
app.get('/api/:env/metrics', async (req, res) => {
  try {
    const { env } = req.params;
    const pool = pools[env];
    
    if (!pool) {
      return res.status(400).json({ error: 'Invalid environment' });
    }

    // Get connection metrics
    const connectionQuery = `
      SELECT 
        count(*) FILTER (WHERE state = 'active') as active_connections,
        count(*) FILTER (WHERE state = 'idle') as idle_connections,
        count(*) as total_connections,
        (SELECT setting::int FROM pg_settings WHERE name = 'max_connections') as max_connections
      FROM pg_stat_activity 
      WHERE datname = current_database();
    `;

    // Get database size and performance metrics
    const performanceQuery = `
      SELECT 
        pg_database_size(current_database()) as database_size,
        numbackends as backends,
        xact_commit as commits,
        xact_rollback as rollbacks,
        blks_read as blocks_read,
        blks_hit as blocks_hit,
        tup_returned as tuples_returned,
        tup_fetched as tuples_fetched,
        tup_inserted as tuples_inserted,
        tup_updated as tuples_updated,
        tup_deleted as tuples_deleted,
        conflicts as conflicts,
        temp_files as temp_files,
        temp_bytes as temp_bytes,
        deadlocks as deadlocks,
        stats_reset
      FROM pg_stat_database 
      WHERE datname = current_database();
    `;

    // Get tablespace sizes
    const tablespaceQuery = `
      SELECT 
        spcname as name,
        pg_size_pretty(pg_tablespace_size(spcname)) as size,
        pg_tablespace_size(spcname) as size_bytes
      FROM pg_tablespace
      ORDER BY pg_tablespace_size(spcname) DESC;
    `;

    // Get slow queries (only if pg_stat_statements is available)
    const slowQueriesQuery = `
      SELECT 
        query,
        calls,
        total_exec_time,
        mean_exec_time,
        rows
      FROM pg_stat_statements 
      WHERE query NOT LIKE '%pg_stat_statements%'
        AND query NOT LIKE '%information_schema%'
      ORDER BY mean_exec_time DESC 
      LIMIT 10;
    `;

    // Get table sizes
    const tableSizesQuery = `
      SELECT 
        schemaname,
        tablename,
        pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as size,
        pg_total_relation_size(schemaname||'.'||tablename) as size_bytes,
        pg_size_pretty(pg_relation_size(schemaname||'.'||tablename)) as table_size,
        pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename) - 
                      pg_relation_size(schemaname||'.'||tablename)) as index_size
      FROM pg_tables 
      WHERE schemaname = 'public'
      ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC
      LIMIT 10;
    `;

    // Execute all queries
    const [
      connectionResult,
      performanceResult,
      tablespaceResult,
      tableSizesResult
    ] = await Promise.all([
      pool.query(connectionQuery),
      pool.query(performanceQuery),
      pool.query(tablespaceQuery),
      pool.query(tableSizesQuery)
    ]);

    // Try to get slow queries (may fail if pg_stat_statements not installed)
    let slowQueriesResult = { rows: [] };
    try {
      slowQueriesResult = await pool.query(slowQueriesQuery);
    } catch (error) {
      console.log('pg_stat_statements not available:', error.message);
    }

    const connectionData = connectionResult.rows[0];
    const performanceData = performanceResult.rows[0];
    const tablespaceData = tablespaceResult.rows;
    const tableSizesData = tableSizesResult.rows;
    const slowQueriesData = slowQueriesResult.rows;

    // Calculate cache hit ratio
    const cacheHitRatio = performanceData.blocks_hit > 0 
      ? ((performanceData.blocks_hit / (performanceData.blocks_hit + performanceData.blocks_read)) * 100)
      : 0;

    // Format response
    const metrics = {
      timestamp: new Date().toISOString(),
      connections: {
        active: parseInt(connectionData.active_connections) || 0,
        idle: parseInt(connectionData.idle_connections) || 0,
        total: parseInt(connectionData.total_connections) || 0,
        max: parseInt(connectionData.max_connections) || 100
      },
      performance: {
        cacheHitRatio: parseFloat(cacheHitRatio.toFixed(2)),
        commits: parseInt(performanceData.commits) || 0,
        rollbacks: parseInt(performanceData.rollbacks) || 0,
        tuplesReturned: parseInt(performanceData.tuples_returned) || 0,
        tuplesFetched: parseInt(performanceData.tuples_fetched) || 0,
        tuplesInserted: parseInt(performanceData.tuples_inserted) || 0,
        tuplesUpdated: parseInt(performanceData.tuples_updated) || 0,
        tuplesDeleted: parseInt(performanceData.tuples_deleted) || 0,
        conflicts: parseInt(performanceData.conflicts) || 0,
        deadlocks: parseInt(performanceData.deadlocks) || 0,
        tempFiles: parseInt(performanceData.temp_files) || 0,
        tempBytes: parseInt(performanceData.temp_bytes) || 0
      },
      storage: {
        databaseSize: parseInt(performanceData.database_size) || 0,
        databaseSizeFormatted: formatBytes(parseInt(performanceData.database_size) || 0),
        tablespaces: tablespaceData.map(ts => ({
          name: ts.name,
          size: ts.size,
          sizeBytes: parseInt(ts.size_bytes) || 0
        })),
        largestTables: tableSizesData.map(table => ({
          schema: table.schemaname,
          name: table.tablename,
          totalSize: table.size,
          tableSize: table.table_size,
          indexSize: table.index_size,
          sizeBytes: parseInt(table.size_bytes) || 0
        }))
      },
      slowQueries: slowQueriesData.map(query => ({
        query: query.query ? query.query.substring(0, 200) + '...' : '',
        calls: parseInt(query.calls) || 0,
        totalTime: parseFloat(query.total_exec_time) || 0,
        meanTime: parseFloat(query.mean_exec_time) || 0,
        rows: parseInt(query.rows) || 0
      }))
    };

    res.json(metrics);
  } catch (error) {
    console.error('Error fetching metrics:', error);
    res.status(500).json({ error: error.message });
  }
});

// Helper function to format bytes
function formatBytes(bytes, decimals = 2) {
  if (bytes === 0) return '0 Bytes';
  const k = 1024;
  const dm = decimals < 0 ? 0 : decimals;
  const sizes = ['Bytes', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB'];
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  return parseFloat((bytes / Math.pow(k, i)).toFixed(dm)) + ' ' + sizes[i];
}

// Get migration status
app.get('/api/:env/migrations', async (req, res) => {
  try {
    const { env } = req.params;
    const pool = pools[env];
    
    if (!pool) {
      return res.status(400).json({ error: 'Invalid environment' });
    }
    
    const query = `
      SELECT * FROM migration_status 
      ORDER BY version DESC;
    `;
    
    const result = await pool.query(query);
    res.json(result.rows);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get database users
app.get('/api/:env/users', async (req, res) => {
  try {
    const { env } = req.params;
    const pool = pools[env];
    
    if (!pool) {
      return res.status(400).json({ error: 'Invalid environment' });
    }
    
    const query = `
      SELECT 
        u.usename as username,
        u.usecreatedb as can_create_db,
        u.usesuper as is_superuser,
        u.userepl as can_replicate,
        u.valuntil as password_expiry,
        COALESCE(
          d.description,
          CASE 
            WHEN u.usename = 'postgres' THEN 'PostgreSQL Superuser'
            WHEN u.usesuper THEN 'Database Administrator'
            WHEN u.usecreatedb THEN 'Database Creator'
            ELSE 'Standard User'
          END
        ) as display_name
      FROM pg_user u
      LEFT JOIN pg_description d ON d.objoid = u.usesysid AND d.classoid = 'pg_authid'::regclass
      ORDER BY u.usename;
    `;
    
    const result = await pool.query(query);
    res.json(result.rows);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Create new user
app.post('/api/:env/users', async (req, res) => {
  try {
    const { env } = req.params;
    const { username, password, can_create_db, is_superuser, can_replicate } = req.body;
    const pool = pools[env];
    
    if (!pool) {
      return res.status(400).json({ error: 'Invalid environment' });
    }
    
    if (!username || !password) {
      return res.status(400).json({ error: 'Username and password are required' });
    }
    
    // Build CREATE USER query with permissions
    let query = `CREATE USER "${username}" WITH PASSWORD '${password}'`;
    
    if (can_create_db) query += ' CREATEDB';
    if (is_superuser) query += ' SUPERUSER';
    if (can_replicate) query += ' REPLICATION';
    
    await pool.query(query);
    
    res.json({ message: 'User created successfully', username });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Update user permissions
app.put('/api/:env/users/:username', async (req, res) => {
  try {
    const { env, username } = req.params;
    const { can_create_db, is_superuser, can_replicate, new_password } = req.body;
    const pool = pools[env];
    
    if (!pool) {
      return res.status(400).json({ error: 'Invalid environment' });
    }
    
    const client = await pool.connect();
    
    try {
      await client.query('BEGIN');
      
      // Update permissions
      if (typeof can_create_db === 'boolean') {
        const createDBQuery = can_create_db 
          ? `ALTER USER "${username}" CREATEDB`
          : `ALTER USER "${username}" NOCREATEDB`;
        await client.query(createDBQuery);
      }
      
      if (typeof is_superuser === 'boolean') {
        const superuserQuery = is_superuser 
          ? `ALTER USER "${username}" SUPERUSER`
          : `ALTER USER "${username}" NOSUPERUSER`;
        await client.query(superuserQuery);
      }
      
      if (typeof can_replicate === 'boolean') {
        const replicateQuery = can_replicate 
          ? `ALTER USER "${username}" REPLICATION`
          : `ALTER USER "${username}" NOREPLICATION`;
        await client.query(replicateQuery);
      }
      
      // Update password if provided
      if (new_password) {
        await client.query(`ALTER USER "${username}" WITH PASSWORD '${new_password}'`);
      }
      
      await client.query('COMMIT');
      res.json({ message: 'User updated successfully', username });
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Delete user
app.delete('/api/:env/users/:username', async (req, res) => {
  try {
    const { env, username } = req.params;
    const pool = pools[env];
    
    if (!pool) {
      return res.status(400).json({ error: 'Invalid environment' });
    }
    
    // Safety check - prevent deletion of postgres user
    if (username === 'postgres') {
      return res.status(400).json({ error: 'Cannot delete postgres superuser' });
    }
    
    await pool.query(`DROP USER IF EXISTS "${username}"`);
    
    res.json({ message: 'User deleted successfully', username });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Update user display name
app.put('/api/:env/users/:username/display-name', async (req, res) => {
  try {
    const { env, username } = req.params;
    const { display_name } = req.body;
    const pool = pools[env];
    
    if (!pool) {
      return res.status(400).json({ error: 'Invalid environment' });
    }
    
    if (!display_name || display_name.trim() === '') {
      return res.status(400).json({ error: 'Display name is required' });
    }
    
    // First get the user's OID
    const userOidQuery = 'SELECT usesysid FROM pg_user WHERE usename = $1';
    const userOidResult = await pool.query(userOidQuery, [username]);
    
    if (userOidResult.rows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }
    
    const userOid = userOidResult.rows[0].usesysid;
    
    // Check if description already exists
    const existingDescQuery = `
      SELECT objoid FROM pg_description 
      WHERE objoid = $1 AND classoid = 'pg_authid'::regclass
    `;
    const existingDescResult = await pool.query(existingDescQuery, [userOid]);
    
    if (existingDescResult.rows.length > 0) {
      // Update existing description
      await pool.query(`
        UPDATE pg_description 
        SET description = $1 
        WHERE objoid = $2 AND classoid = 'pg_authid'::regclass
      `, [display_name.trim(), userOid]);
    } else {
      // Insert new description
      await pool.query(`
        INSERT INTO pg_description (objoid, classoid, objsubid, description)
        VALUES ($1, 'pg_authid'::regclass, 0, $2)
      `, [userOid, display_name.trim()]);
    }
    
    res.json({ 
      message: 'Display name updated successfully', 
      username, 
      display_name: display_name.trim() 
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get detailed user information
app.get('/api/:env/users/:username/details', async (req, res) => {
  try {
    const { env, username } = req.params;
    const pool = pools[env];
    
    if (!pool) {
      return res.status(400).json({ error: 'Invalid environment' });
    }
    
    // Get detailed user information including activity and permissions
    const userDetailsQuery = `
      SELECT 
        u.usename as username,
        u.usecreatedb as can_create_db,
        u.usesuper as is_superuser,
        u.userepl as can_replicate,
        u.valuntil as password_expiry,
        COALESCE(
          d.description,
          CASE 
            WHEN u.usename = 'postgres' THEN 'PostgreSQL Superuser'
            WHEN u.usesuper THEN 'Database Administrator'
            WHEN u.usecreatedb THEN 'Database Creator'
            ELSE 'Standard User'
          END
        ) as display_name,
        CASE WHEN u.usename IS NOT NULL THEN true ELSE false END as is_active,
        (SELECT backend_start FROM pg_stat_activity WHERE usename = u.usename ORDER BY backend_start DESC LIMIT 1) as last_login,
        (SELECT COUNT(*) FROM pg_stat_activity WHERE usename = u.usename) as active_connections
      FROM pg_user u
      LEFT JOIN pg_description d ON d.objoid = u.usesysid AND d.classoid = 'pg_authid'::regclass
      WHERE u.usename = $1;
    `;
    
    const permissionsQuery = `
      SELECT 
        r.rolname as role_name,
        n.nspname as schema_name,
        c.relname as object_name,
        c.relkind as object_type,
        ARRAY_AGG(p.privilege_type) as privileges
      FROM pg_roles r
      LEFT JOIN pg_namespace n ON true
      LEFT JOIN pg_class c ON c.relnamespace = n.oid
      LEFT JOIN (
        SELECT 
          grantee,
          table_schema,
          table_name,
          privilege_type
        FROM information_schema.table_privileges
        WHERE grantee = $1
        UNION ALL
        SELECT 
          grantee,
          specific_schema as table_schema,
          specific_name as table_name,
          privilege_type
        FROM information_schema.routine_privileges
        WHERE grantee = $1
      ) p ON p.grantee = r.rolname AND p.table_schema = n.nspname AND p.table_name = c.relname
      WHERE r.rolname = $1
      GROUP BY r.rolname, n.nspname, c.relname, c.relkind
      HAVING COUNT(p.privilege_type) > 0;
    `;
    
    const [userResult, permissionsResult] = await Promise.all([
      pool.query(userDetailsQuery, [username]),
      pool.query(permissionsQuery, [username])
    ]);
    
    if (userResult.rows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }
    
    const userDetails = userResult.rows[0];
    userDetails.permissions = permissionsResult.rows;
    userDetails.connection_count = userDetails.active_connections || 0;
    
    res.json(userDetails);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get databases owned by user
app.get('/api/:env/users/:username/databases', async (req, res) => {
  try {
    const { env, username } = req.params;
    const pool = pools[env];
    
    if (!pool) {
      return res.status(400).json({ error: 'Invalid environment' });
    }
    
    const query = `
      SELECT 
        d.datname as name,
        pg_size_pretty(pg_database_size(d.datname)) as size,
        d.datcollate as collation,
        d.datctype as ctype,
        (SELECT COUNT(*) FROM information_schema.tables WHERE table_catalog = d.datname) as table_count
      FROM pg_database d
      JOIN pg_roles r ON d.datdba = r.oid
      WHERE r.rolname = $1
      AND d.datname NOT IN ('template0', 'template1')
      ORDER BY d.datname;
    `;
    
    const result = await pool.query(query, [username]);
    res.json(result.rows);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get user connection history
app.get('/api/:env/users/:username/connections', async (req, res) => {
  try {
    const { env, username } = req.params;
    const pool = pools[env];
    
    if (!pool) {
      return res.status(400).json({ error: 'Invalid environment' });
    }
    
    // Get current active connections
    const activeConnectionsQuery = `
      SELECT 
        pid,
        datname as database,
        client_addr,
        client_port,
        backend_start as connect_time,
        state,
        EXTRACT(EPOCH FROM (now() - backend_start)) as duration
      FROM pg_stat_activity
      WHERE usename = $1
      AND state IS NOT NULL
      ORDER BY backend_start DESC;
    `;
    
    const result = await pool.query(activeConnectionsQuery, [username]);
    
    // Note: PostgreSQL doesn't store historical connection data by default
    // In a production environment, you might want to log this to a separate table
    const connections = result.rows.map(row => ({
      ...row,
      duration: Math.round(row.duration || 0),
      connect_time: row.connect_time,
      status: row.state || 'unknown'
    }));
    
    res.json(connections);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Execute custom query (admin only)
app.post('/api/:env/query', async (req, res) => {
  try {
    const { env } = req.params;
    const { query, readonly = true } = req.body;
    const pool = pools[env];
    
    if (!pool) {
      return res.status(400).json({ error: 'Invalid environment' });
    }
    
    // Security check: only allow SELECT queries for readonly mode
    if (readonly && !query.trim().toLowerCase().startsWith('select')) {
      return res.status(400).json({ 
        error: 'Only SELECT queries are allowed in readonly mode' 
      });
    }
    
    const startTime = Date.now();
    const result = await pool.query(query);
    const executionTime = Date.now() - startTime;
    
    res.json({
      rows: result.rows,
      rowCount: result.rowCount,
      executionTime,
      command: result.command
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Error handling middleware
app.use((error, req, res, next) => {
  console.error('Error:', error);
  res.status(500).json({ 
    error: 'Internal server error',
    message: process.env.NODE_ENV === 'development' ? error.message : undefined
  });
});

// Initialize AI Query Service
const aiQueryService = new AIQueryService();

// AI Assistant endpoints
app.post('/api/:env/ai/natural-language', async (req, res) => {
  try {
    const { env } = req.params;
    const { query } = req.body;

    if (!query || typeof query !== 'string') {
      return res.status(400).json({ error: 'Query text is required' });
    }

    if (!pools[env]) {
      return res.status(400).json({ error: 'Invalid environment' });
    }

    // Process the natural language query
    const result = await aiQueryService.processNaturalLanguage(query);
    
    res.json({
      success: true,
      result: result,
      timestamp: new Date().toISOString()
    });

  } catch (error) {
    console.error('AI Natural Language Processing Error:', error);
    res.status(500).json({ 
      error: 'Failed to process natural language query',
      details: error.message 
    });
  }
});

app.post('/api/:env/ai/execute-query', async (req, res) => {
  try {
    const { env } = req.params;
    const { sql, safetyCheck = true } = req.body;

    if (!sql || typeof sql !== 'string') {
      return res.status(400).json({ error: 'SQL query is required' });
    }

    if (!pools[env]) {
      return res.status(400).json({ error: 'Invalid environment' });
    }

    // Perform safety check if enabled
    if (safetyCheck) {
      const securityCheck = aiQueryService.performSecurityCheck(sql);
      if (!securityCheck.safe) {
        return res.status(400).json({ 
          error: 'Query failed security check',
          warnings: securityCheck.warnings 
        });
      }
    }

    // Execute the query with timeout
    const pool = pools[env];
    const client = await pool.connect();
    
    try {
      // Set statement timeout to 30 seconds
      await client.query('SET statement_timeout = 30000');
      
      const startTime = Date.now();
      const result = await client.query(sql);
      const executionTime = Date.now() - startTime;

      res.json({
        success: true,
        data: result.rows,
        rowCount: result.rowCount,
        executionTime: executionTime,
        fields: result.fields?.map(field => ({
          name: field.name,
          dataTypeID: field.dataTypeID
        })) || [],
        timestamp: new Date().toISOString()
      });

    } finally {
      client.release();
    }

  } catch (error) {
    console.error('AI Query Execution Error:', error);
    res.status(500).json({ 
      error: 'Failed to execute query',
      details: error.message 
    });
  }
});

app.get('/api/:env/ai/optimization-recommendations', async (req, res) => {
  try {
    const { env } = req.params;

    if (!pools[env]) {
      return res.status(400).json({ error: 'Invalid environment' });
    }

    const pool = pools[env];
    const client = await pool.connect();
    
    try {
      // Gather database statistics for optimization recommendations
      const statsQueries = {
        slowQueries: `
          SELECT query, mean_time, calls, total_time
          FROM pg_stat_statements 
          WHERE mean_time > 100 
          ORDER BY mean_time DESC 
          LIMIT 10
        `,
        tableStats: `
          SELECT 
            schemaname,
            tablename,
            n_tup_ins as inserts,
            n_tup_upd as updates,
            n_tup_del as deletes,
            n_live_tup as live_tuples,
            n_dead_tup as dead_tuples
          FROM pg_stat_user_tables
          ORDER BY n_live_tup DESC
          LIMIT 20
        `,
        indexUsage: `
          SELECT 
            schemaname,
            tablename,
            indexname,
            idx_scan,
            idx_tup_read,
            idx_tup_fetch
          FROM pg_stat_user_indexes
          WHERE idx_scan = 0
          ORDER BY schemaname, tablename
        `
      };

      const databaseStats = {};
      
      try {
        const slowQueriesResult = await client.query(statsQueries.slowQueries);
        databaseStats.slowQueries = slowQueriesResult.rows;
      } catch (error) {
        // pg_stat_statements might not be available
        databaseStats.slowQueries = [];
      }

      const tableStatsResult = await client.query(statsQueries.tableStats);
      databaseStats.tableStats = tableStatsResult.rows;

      const indexUsageResult = await client.query(statsQueries.indexUsage);
      databaseStats.unusedIndexes = indexUsageResult.rows;

      // Generate recommendations
      const recommendations = await aiQueryService.generateOptimizationRecommendations(databaseStats);

      res.json({
        success: true,
        recommendations: recommendations,
        databaseStats: databaseStats,
        timestamp: new Date().toISOString()
      });

    } finally {
      client.release();
    }

  } catch (error) {
    console.error('AI Optimization Recommendations Error:', error);
    res.status(500).json({ 
      error: 'Failed to generate optimization recommendations',
      details: error.message 
    });
  }
});

app.get('/api/:env/ai/security-audit', async (req, res) => {
  try {
    const { env } = req.params;

    if (!pools[env]) {
      return res.status(400).json({ error: 'Invalid environment' });
    }

    const pool = pools[env];
    const client = await pool.connect();
    
    try {
      const securityChecks = {
        // Check for users with weak passwords (if we have access to this info)
        userSecurity: `
          SELECT 
            usename as username,
            valuntil as password_expiry,
            usesuper as is_superuser
          FROM pg_user
          WHERE usesuper = true OR valuntil IS NULL OR valuntil < NOW() + INTERVAL '30 days'
        `,
        
        // Check for tables without primary keys
        tablesWithoutPK: `
          SELECT 
            t.table_schema,
            t.table_name
          FROM information_schema.tables t
          LEFT JOIN information_schema.table_constraints tc 
            ON t.table_schema = tc.table_schema 
            AND t.table_name = tc.table_name 
            AND tc.constraint_type = 'PRIMARY KEY'
          WHERE t.table_type = 'BASE TABLE'
            AND t.table_schema NOT IN ('information_schema', 'pg_catalog')
            AND tc.constraint_name IS NULL
        `,
        
        // Check for columns that might contain sensitive data without encryption
        sensitiveColumns: `
          SELECT 
            table_schema,
            table_name,
            column_name,
            data_type
          FROM information_schema.columns
          WHERE table_schema NOT IN ('information_schema', 'pg_catalog')
            AND (
              LOWER(column_name) LIKE '%password%' OR
              LOWER(column_name) LIKE '%ssn%' OR
              LOWER(column_name) LIKE '%credit%' OR
              LOWER(column_name) LIKE '%card%' OR
              LOWER(column_name) LIKE '%secret%'
            )
        `
      };

      const securityResults = {};
      
      const userSecurityResult = await client.query(securityChecks.userSecurity);
      securityResults.userSecurity = userSecurityResult.rows;

      const tablesWithoutPKResult = await client.query(securityChecks.tablesWithoutPK);
      securityResults.tablesWithoutPK = tablesWithoutPKResult.rows;

      const sensitiveColumnsResult = await client.query(securityChecks.sensitiveColumns);
      securityResults.sensitiveColumns = sensitiveColumnsResult.rows;

      // Generate security alerts
      const alerts = [];

      if (securityResults.userSecurity.length > 0) {
        alerts.push({
          id: 'user-security-' + Date.now(),
          severity: 'HIGH',
          title: 'User Security Issues',
          description: `Found ${securityResults.userSecurity.length} users with potential security issues`,
          affected: securityResults.userSecurity.map(u => u.username),
          recommendation: 'Review user privileges and password policies'
        });
      }

      if (securityResults.tablesWithoutPK.length > 0) {
        alerts.push({
          id: 'no-pk-' + Date.now(),
          severity: 'MEDIUM',
          title: 'Tables Without Primary Keys',
          description: `Found ${securityResults.tablesWithoutPK.length} tables without primary keys`,
          affected: securityResults.tablesWithoutPK.map(t => `${t.table_schema}.${t.table_name}`),
          recommendation: 'Add primary keys to ensure data integrity and replication support'
        });
      }

      if (securityResults.sensitiveColumns.length > 0) {
        alerts.push({
          id: 'sensitive-data-' + Date.now(),
          severity: 'CRITICAL',
          title: 'Potentially Unencrypted Sensitive Data',
          description: `Found ${securityResults.sensitiveColumns.length} columns that may contain sensitive data`,
          affected: securityResults.sensitiveColumns.map(c => `${c.table_schema}.${c.table_name}.${c.column_name}`),
          recommendation: 'Ensure sensitive data is properly encrypted and access is restricted'
        });
      }

      res.json({
        success: true,
        alerts: alerts,
        details: securityResults,
        timestamp: new Date().toISOString()
      });

    } finally {
      client.release();
    }

  } catch (error) {
    console.error('AI Security Audit Error:', error);
    res.status(500).json({ 
      error: 'Failed to perform security audit',
      details: error.message 
    });
  }
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({ error: 'Route not found' });
});

// Add error handling for uncaught exceptions
process.on('uncaughtException', (error) => {
  console.error('Uncaught Exception:', error);
  process.exit(1);
});

process.on('unhandledRejection', (reason, promise) => {
  console.error('Unhandled Rejection at:', promise, 'reason:', reason);
  process.exit(1);
});

// Graceful shutdown
process.on('SIGTERM', () => {
  console.log('SIGTERM received, shutting down gracefully');
  
  Object.values(pools).forEach(pool => {
    pool.end();
  });
  
  process.exit(0);
});

app.listen(PORT, () => {
  console.log(`🚀 GameForge DB Admin API running on port ${PORT}`);
  console.log(`📊 Environment: ${process.env.NODE_ENV || 'development'}`);
  console.log(`🔗 Health check: http://localhost:${PORT}/api/health`);
});

module.exports = app;