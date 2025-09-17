const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const rateLimit = require('express-rate-limit');
const { Pool } = require('pg');
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
        usename as username,
        usecreatedb as can_create_db,
        usesuper as is_superuser,
        userepl as can_replicate,
        valuntil as password_expiry
      FROM pg_user
      ORDER BY usename;
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