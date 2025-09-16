# 🔗 Connect Existing GameForge-2.0 Backend to Database

## 🎯 Overview

You have an existing backend in GameForge-2.0 that needs to connect to the PostgreSQL database we've set up. This guide will walk you through the configuration steps.

## ✅ Database Ready Status
- **PostgreSQL 17.4**: Running on `localhost:5432`
- **Database**: `gameforge_dev` 
- **Tables**: 22 tables confirmed and accessible
- **Performance**: Optimized (pending restart for full effect)
- **Schema**: Complete with all required relationships

## 📋 Connection Information

### Database Connection Details
```
Host: localhost
Port: 5432
Database: gameforge_dev
Username: postgres
Password: [your-postgres-password]
Connection URL: postgresql://postgres:[password]@localhost:5432/gameforge_dev
```

### Available Tables (22 tables confirmed)
- **Users & Auth**: `users`, `user_permissions`, `user_preferences`, `user_sessions`, `access_tokens`
- **Projects**: `projects`, `project_collaborators`, `project_stats`
- **Assets**: `assets`, `presigned_urls`, `storage_configs`
- **AI/ML**: `ai_requests`, `ml_models`, `datasets`
- **System**: `api_keys`, `audit_logs`, `compliance_events`, `game_templates`, `system_config`
- **Migration**: `migration_status`, `schema_migrations`

## 🔧 Backend Configuration Steps

### Step 1: Identify Your Backend Type

First, let's determine what type of backend you have. Common types:

**Node.js/Express:**
- Look for `package.json`, `server.js`, `app.js`, or `index.js`
- Dependencies like `express`, `nodejs`

**Python/FastAPI or Flask:**
- Look for `requirements.txt`, `main.py`, `app.py`
- Dependencies like `fastapi`, `flask`, `uvicorn`

**Python/Django:**
- Look for `manage.py`, `settings.py`
- Django project structure

**Other:**
- Java/Spring Boot, .NET, etc.

### Step 2: Environment Configuration

#### For Node.js Backend

Create or update `.env` file in your backend directory:
```bash
# Database Configuration
DB_HOST=localhost
DB_PORT=5432
DB_NAME=gameforge_dev
DB_USER=postgres
DB_PASSWORD=your-postgres-password-here
DATABASE_URL=postgresql://postgres:your-password@localhost:5432/gameforge_dev

# Server Configuration  
PORT=8080
NODE_ENV=development

# Security
JWT_SECRET=your-jwt-secret-key-here
SESSION_SECRET=your-session-secret-here

# CORS (for frontend connection)
CORS_ORIGIN=http://localhost:3000,http://localhost:5173
```

#### For Python Backend

Create or update `.env` file:
```bash
# Database Configuration
DATABASE_HOST=localhost
DATABASE_PORT=5432
DATABASE_NAME=gameforge_dev
DATABASE_USER=postgres
DATABASE_PASSWORD=your-postgres-password-here
DATABASE_URL=postgresql://postgres:your-password@localhost:5432/gameforge_dev

# Server Configuration
PORT=8080
HOST=0.0.0.0
DEBUG=True

# Security
SECRET_KEY=your-secret-key-here
JWT_SECRET=your-jwt-secret-here
```

### Step 3: Install Database Dependencies

#### For Node.js Backend
```bash
# If using npm
npm install pg pg-pool dotenv

# If using yarn
yarn add pg pg-pool dotenv
```

#### For Python Backend
```bash
# For PostgreSQL with SQLAlchemy
pip install psycopg2-binary sqlalchemy python-dotenv

# For FastAPI
pip install fastapi uvicorn psycopg2-binary sqlalchemy python-dotenv

# For Django
pip install psycopg2-binary python-dotenv
```

### Step 4: Database Connection Code

#### Node.js/Express Example
```javascript
// database.js or db.js
const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
  host: process.env.DB_HOST || 'localhost',
  port: process.env.DB_PORT || 5432,
  database: process.env.DB_NAME || 'gameforge_dev',
  user: process.env.DB_USER || 'postgres',
  password: process.env.DB_PASSWORD,
  max: 20, // max number of clients in pool
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 2000,
});

// Test connection
pool.connect((err, client, release) => {
  if (err) {
    console.error('❌ Database connection failed:', err);
  } else {
    console.log('✅ Database connected successfully');
    release();
  }
});

module.exports = pool;
```

#### Python/FastAPI Example
```python
# database.py
import os
from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker
from dotenv import load_dotenv

load_dotenv()

DATABASE_URL = os.getenv(
    "DATABASE_URL", 
    f"postgresql://{os.getenv('DATABASE_USER', 'postgres')}:{os.getenv('DATABASE_PASSWORD')}@{os.getenv('DATABASE_HOST', 'localhost')}:{os.getenv('DATABASE_PORT', '5432')}/{os.getenv('DATABASE_NAME', 'gameforge_dev')}"
)

engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# Test connection
def test_connection():
    try:
        with engine.connect() as connection:
            result = connection.execute(text("SELECT version()"))
            print("✅ Database connected successfully")
            print(f"📊 PostgreSQL version: {result.fetchone()[0]}")
    except Exception as e:
        print(f"❌ Database connection failed: {e}")
```

### Step 5: Update Your Backend Routes

#### Authentication Route Example (Node.js)
```javascript
// auth.js or in your main server file
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const pool = require('./database'); // your database connection

app.post('/api/v1/auth/login', async (req, res) => {
  const { email, password } = req.body;
  
  try {
    const result = await pool.query(
      `SELECT u.id, u.email, u.password_hash, u.role, u.name, u.created_at,
              array_agg(DISTINCT up.permission) as permissions
       FROM users u
       LEFT JOIN user_permissions up ON u.id = up.user_id
       WHERE u.email = $1 AND u.is_active = true
       GROUP BY u.id, u.email, u.password_hash, u.role, u.name, u.created_at`,
      [email.toLowerCase()]
    );
    
    if (result.rows.length === 0) {
      return res.status(401).json({
        success: false,
        error: { message: 'Invalid credentials' }
      });
    }
    
    const user = result.rows[0];
    
    // Verify password
    const isValid = await bcrypt.compare(password, user.password_hash);
    if (!isValid) {
      return res.status(401).json({
        success: false,
        error: { message: 'Invalid credentials' }
      });
    }
    
    // Generate JWT
    const token = jwt.sign(
      { userId: user.id, email: user.email, role: user.role },
      process.env.JWT_SECRET,
      { expiresIn: '24h' }
    );
    
    res.json({
      success: true,
      data: {
        token,
        user: {
          id: user.id,
          email: user.email,
          name: user.name,
          role: user.role,
          permissions: user.permissions.filter(p => p !== null)
        }
      }
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: { message: 'Login failed', details: error.message }
    });
  }
});
```

### Step 6: Test the Connection

#### Add Health Check Endpoint
```javascript
// Node.js example
app.get('/api/v1/health', async (req, res) => {
  try {
    const result = await pool.query('SELECT NOW(), COUNT(*) FROM users');
    res.json({
      success: true,
      message: 'Database connected successfully',
      timestamp: result.rows[0].now,
      userCount: result.rows[0].count,
      database: process.env.DB_NAME
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: { message: 'Database connection failed', details: error.message }
    });
  }
});
```

## 🧪 Testing Steps

### 1. Test Database Connection
```powershell
# First, verify direct database access
psql -h localhost -U postgres -d gameforge_dev -c "SELECT COUNT(*) FROM users;"
```

### 2. Start Your Backend
```bash
# Navigate to your backend directory and start it
# Node.js example:
npm start
# or
node server.js

# Python example:
python main.py
# or
uvicorn main:app --reload --port 8080
```

### 3. Test Health Endpoint
```powershell
curl http://localhost:8080/api/v1/health
```

Expected response:
```json
{
  "success": true,
  "message": "Database connected successfully",
  "timestamp": "2025-09-16T...",
  "userCount": "0",
  "database": "gameforge_dev"
}
```

### 4. Test Authentication
```powershell
# Create a test user first (if needed)
psql -h localhost -U postgres -d gameforge_dev -c "
INSERT INTO users (email, password_hash, name, role, is_active) 
VALUES ('test@example.com', '$2a$12$hash', 'Test User', 'basic_user', true);"

# Test login endpoint
curl -X POST http://localhost:8080/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password123"}'
```

## 🚨 Common Issues & Solutions

### Issue 1: "Connection Refused"
```bash
# Check PostgreSQL service
Get-Service postgresql*

# Start if not running
Start-Service postgresql-x64-17
```

### Issue 2: "Authentication Failed"
- Verify password in `.env` file
- Check username is `postgres`
- Ensure database name is `gameforge_dev`

### Issue 3: "Database Does Not Exist"
```sql
-- Verify database exists
psql -U postgres -l | findstr gameforge
```

### Issue 4: "Permission Denied"
- Ensure PostgreSQL allows local connections
- Check `pg_hba.conf` for local authentication settings

### Issue 5: CORS Errors
- Add your frontend URL to CORS origins
- Ensure backend is running on correct port (8080)

## 📊 Database Schema Reference

Your backend can now access these key tables:

### Users & Authentication
```sql
-- Main user table
SELECT * FROM users WHERE email = 'user@example.com';

-- User permissions
SELECT permission FROM user_permissions WHERE user_id = 'user-uuid';

-- User sessions
SELECT * FROM user_sessions WHERE user_id = 'user-uuid';
```

### Projects & Assets
```sql
-- User projects
SELECT * FROM projects WHERE user_id = 'user-uuid';

-- Project collaborators
SELECT * FROM project_collaborators WHERE project_id = 'project-uuid';

-- Project assets
SELECT * FROM assets WHERE project_id = 'project-uuid';
```

## ✅ Success Checklist

- [ ] Environment variables configured
- [ ] Database dependencies installed
- [ ] Connection pool/client configured
- [ ] Backend starts without errors
- [ ] Health endpoint returns 200 OK
- [ ] Can query users table
- [ ] Authentication endpoints work
- [ ] Frontend can connect to backend

## 🎯 Next Steps

Once your backend is connected:

1. **Test all API endpoints** that interact with the database
2. **Verify user authentication flow** works end-to-end
3. **Test CRUD operations** for projects, assets, etc.
4. **Complete PostgreSQL service restart** for full performance optimization
5. **Implement remaining security features** as needed

Your database is production-ready with 22 tables, proper relationships, optimized performance settings, and comprehensive schema. The backend just needs the connection configuration to start using it immediately!

---

**Created**: September 16, 2025  
**Purpose**: Connect existing GameForge-2.0 backend to database  
**Database**: PostgreSQL 17.4 gameforge_dev (22 tables ready)