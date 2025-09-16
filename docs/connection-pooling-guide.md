# GameForge Database Connection Pooling Configuration Guide

## Overview
Connection pooling is critical for production database performance. This guide provides configuration recommendations for different technology stacks used with the GameForge database.

## Application-Level Connection Pooling (Recommended)

### Python (SQLAlchemy + asyncpg)
```python
# For gameforge/core/database.py
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker
import os

# Production-optimized connection configuration
DATABASE_URL = os.getenv("DATABASE_URL", 
    "postgresql+asyncpg://gameforge_user:password@localhost:5432/gameforge_prod"
)

# Connection pool settings optimized for 16GB RAM / 4 CPU system
engine = create_async_engine(
    DATABASE_URL,
    
    # Pool configuration
    pool_size=20,              # Base connection pool size
    max_overflow=30,           # Additional connections when needed
    pool_recycle=3600,         # Recycle connections every hour
    pool_pre_ping=True,        # Validate connections before use
    
    # Connection timeouts
    pool_timeout=30,           # Wait 30s for connection from pool
    connect_args={
        "command_timeout": 60,
        "server_settings": {
            "application_name": "gameforge_app",
            "jit": "off"       # Disable JIT for predictable performance
        }
    },
    
    # Performance settings
    echo=False,                # Don't log SQL in production
    future=True,               # Use SQLAlchemy 2.0 style
)

# Session factory
async_session = sessionmaker(
    engine, 
    class_=AsyncSession, 
    expire_on_commit=False
)

# Health check function
async def check_database_health():
    try:
        async with async_session() as session:
            result = await session.execute(text("SELECT 1"))
            return result.scalar() == 1
    except Exception as e:
        logger.error(f"Database health check failed: {e}")
        return False
```

### Node.js (pg-pool)
```javascript
// For Node.js applications
const { Pool } = require('pg');

const pool = new Pool({
    // Connection details
    host: 'localhost',
    port: 5432,
    database: 'gameforge_prod',
    user: 'gameforge_user',
    password: process.env.DB_PASSWORD,
    
    // Pool configuration
    max: 20,                    // Maximum connections
    min: 5,                     // Minimum connections
    idleTimeoutMillis: 30000,   // Close idle connections after 30s
    connectionTimeoutMillis: 5000, // Wait 5s for new connection
    
    // Performance settings
    application_name: 'gameforge_node_app',
    statement_timeout: 60000,   // 60s statement timeout
    query_timeout: 60000,       // 60s query timeout
});

// Health check
async function checkDatabaseHealth() {
    try {
        const client = await pool.connect();
        const result = await client.query('SELECT 1');
        client.release();
        return result.rows[0] && result.rows[0]['?column?'] === 1;
    } catch (error) {
        console.error('Database health check failed:', error);
        return false;
    }
}

module.exports = { pool, checkDatabaseHealth };
```

### Java (HikariCP)
```java
// For Java Spring Boot applications
import com.zaxxer.hikari.HikariConfig;
import com.zaxxer.hikari.HikariDataSource;

@Configuration
public class DatabaseConfig {
    
    @Bean
    @Primary
    public DataSource dataSource() {
        HikariConfig config = new HikariConfig();
        
        // Connection details
        config.setJdbcUrl("jdbc:postgresql://localhost:5432/gameforge_prod");
        config.setUsername("gameforge_user");
        config.setPassword(System.getenv("DB_PASSWORD"));
        
        // Pool configuration
        config.setMaximumPoolSize(20);      // Maximum connections
        config.setMinimumIdle(5);           // Minimum idle connections
        config.setIdleTimeout(600000);      // 10 minutes idle timeout
        config.setConnectionTimeout(30000); // 30s connection timeout
        config.setMaxLifetime(1800000);     // 30 minutes max lifetime
        
        // Performance settings
        config.setLeakDetectionThreshold(60000); // Detect leaks after 60s
        config.addDataSourceProperty("cachePrepStmts", "true");
        config.addDataSourceProperty("prepStmtCacheSize", "250");
        config.addDataSourceProperty("prepStmtCacheSqlLimit", "2048");
        config.addDataSourceProperty("useServerPrepStmts", "true");
        config.addDataSourceProperty("applicationName", "gameforge_java_app");
        
        return new HikariDataSource(config);
    }
}
```

## Database-Level Connection Pooling (pgBouncer)

### pgBouncer Configuration
```ini
# /etc/pgbouncer/pgbouncer.ini

[databases]
gameforge_prod = host=localhost port=5432 dbname=gameforge_prod
gameforge_dev = host=localhost port=5432 dbname=gameforge_dev

[pgbouncer]
# Connection pooling mode
pool_mode = transaction          # Best performance for stateless apps
# pool_mode = session            # Use for applications requiring session state

# Connection limits
max_client_conn = 200           # Maximum client connections
default_pool_size = 25          # Connections per database
reserve_pool_size = 5           # Emergency connections
reserve_pool_timeout = 5       # Seconds to wait for emergency connection

# Timeouts
server_connect_timeout = 15     # Seconds to connect to PostgreSQL
server_login_retry = 15         # Seconds between login attempts
client_login_timeout = 60       # Seconds for client to login
query_timeout = 3600           # Seconds for query execution
query_wait_timeout = 120       # Seconds to wait for slot

# Performance settings
server_reset_query = DISCARD ALL
server_check_query = SELECT 1
server_fast_close = 1
tcp_keepalive = 1
tcp_keepcnt = 3
tcp_keepidle = 600
tcp_keepintvl = 30

# Logging
log_connections = 1
log_disconnections = 1
log_pooler_errors = 1
stats_period = 60

# Authentication
auth_type = scram-sha-256
auth_file = /etc/pgbouncer/userlist.txt

# Listen settings
listen_addr = 127.0.0.1
listen_port = 6432
unix_socket_dir = /tmp
```

### pgBouncer User Configuration
```
# /etc/pgbouncer/userlist.txt
"gameforge_user" "SCRAM-SHA-256$4096:salt$hash:hash"
```

## Connection Pool Monitoring

### Database Connection Monitoring Script
```sql
-- Monitor active connections
SELECT 
    datname,
    usename,
    application_name,
    client_addr,
    state,
    COUNT(*) as connection_count
FROM pg_stat_activity 
WHERE datname LIKE 'gameforge%'
GROUP BY datname, usename, application_name, client_addr, state
ORDER BY connection_count DESC;

-- Check connection pool health
SELECT 
    'Total Connections' as metric,
    COUNT(*) as value
FROM pg_stat_activity
WHERE datname = 'gameforge_prod'
UNION ALL
SELECT 
    'Active Connections' as metric,
    COUNT(*) as value
FROM pg_stat_activity
WHERE datname = 'gameforge_prod' AND state = 'active'
UNION ALL
SELECT 
    'Idle Connections' as metric,
    COUNT(*) as value
FROM pg_stat_activity
WHERE datname = 'gameforge_prod' AND state = 'idle';
```

## Production Deployment Recommendations

### Environment Variables
```bash
# Database connection
DATABASE_URL=postgresql://gameforge_user:password@localhost:5432/gameforge_prod
DATABASE_POOL_SIZE=20
DATABASE_MAX_OVERFLOW=30
DATABASE_POOL_RECYCLE=3600

# Connection monitoring
DATABASE_HEALTH_CHECK_INTERVAL=30
DATABASE_CONNECTION_TIMEOUT=30
DATABASE_QUERY_TIMEOUT=60
```

### Application Configuration
```python
# Production connection pool configuration
PRODUCTION_POOL_CONFIG = {
    "pool_size": int(os.getenv("DATABASE_POOL_SIZE", 20)),
    "max_overflow": int(os.getenv("DATABASE_MAX_OVERFLOW", 30)),
    "pool_recycle": int(os.getenv("DATABASE_POOL_RECYCLE", 3600)),
    "pool_pre_ping": True,
    "pool_timeout": int(os.getenv("DATABASE_CONNECTION_TIMEOUT", 30)),
}
```

### Connection Pool Sizing Guidelines

| Application Type | Recommended Pool Size | Max Overflow | Notes |
|-----------------|----------------------|--------------|-------|
| Web API (FastAPI/Flask) | 20 | 30 | For typical web applications |
| Background Workers | 10 | 20 | For async task processing |
| Data Analytics | 5 | 10 | For long-running queries |
| Microservices | 10 | 15 | Per service instance |

### Monitoring and Alerting

1. **Connection Pool Exhaustion**
   - Alert when active connections > 80% of pool size
   - Monitor connection wait times

2. **Connection Health**
   - Regular health checks every 30 seconds
   - Alert on connection failures

3. **Query Performance**
   - Monitor slow queries (>1000ms)
   - Track connection pool hit ratios

## Best Practices

1. **Connection Lifecycle Management**
   - Always close connections properly
   - Use connection context managers
   - Implement connection retry logic

2. **Pool Configuration**
   - Start with conservative pool sizes
   - Monitor and adjust based on usage patterns
   - Consider application architecture (sync vs async)

3. **Error Handling**
   - Implement proper connection error handling
   - Use circuit breaker patterns for resilience
   - Log connection pool metrics

4. **Testing**
   - Load test with realistic connection patterns
   - Test connection pool exhaustion scenarios
   - Validate failover behavior

This configuration provides production-ready connection pooling for the GameForge database with optimal performance for a 16GB RAM, 4-core system.