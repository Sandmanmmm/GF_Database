# 🔗 GameForge Database Connection Configuration

## 📋 Database Connection Details

```
Host: localhost
Port: 5432
Database: gameforge_dev
Username: postgres
Password: [your-postgres-password]
Connection URL: postgresql://postgres:[password]@localhost:5432/gameforge_dev
```

## 🔧 Environment Variables

### .env File Configuration
Create or update your backend's `.env` file:

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

# CORS Origins (adjust for your frontend URLs)
CORS_ORIGIN=http://localhost:3000,http://localhost:5173,http://localhost:4173
```

## 📦 Required Dependencies

### Node.js/Express
```bash
npm install pg pg-pool dotenv bcryptjs jsonwebtoken cors
```

### Python/FastAPI
```bash
pip install psycopg2-binary sqlalchemy python-dotenv fastapi uvicorn
```

### Python/Django
```bash
pip install psycopg2-binary python-dotenv django
```

## 💻 Connection Code Examples

### Node.js Database Connection
```javascript
// database.js
const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
  host: process.env.DB_HOST || 'localhost',
  port: process.env.DB_PORT || 5432,
  database: process.env.DB_NAME || 'gameforge_dev',
  user: process.env.DB_USER || 'postgres',
  password: process.env.DB_PASSWORD,
  max: 20,
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

### Python/SQLAlchemy Database Connection
```python
# database.py
import os
from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker
from dotenv import load_dotenv

load_dotenv()

DATABASE_URL = os.getenv(
    "DATABASE_URL", 
    f"postgresql://{os.getenv('DB_USER', 'postgres')}:{os.getenv('DB_PASSWORD')}@{os.getenv('DB_HOST', 'localhost')}:{os.getenv('DB_PORT', '5432')}/{os.getenv('DB_NAME', 'gameforge_dev')}"
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

## 🛡️ Authentication Implementation

### Node.js Login Endpoint
```javascript
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const pool = require('./database');

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
    const isValid = await bcrypt.compare(password, user.password_hash);
    
    if (!isValid) {
      return res.status(401).json({
        success: false,
        error: { message: 'Invalid credentials' }
      });
    }
    
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

### Python/FastAPI Login Endpoint
```python
from fastapi import FastAPI, HTTPException, Depends
from sqlalchemy.orm import Session
from passlib.context import CryptContext
import jwt
from datetime import datetime, timedelta

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

@app.post("/api/v1/auth/login")
async def login(credentials: dict, db: Session = Depends(get_db)):
    email = credentials.get("email")
    password = credentials.get("password")
    
    # Query user with permissions
    result = db.execute(text("""
        SELECT u.id, u.email, u.password_hash, u.role, u.name, u.created_at,
               array_agg(DISTINCT up.permission) as permissions
        FROM users u
        LEFT JOIN user_permissions up ON u.id = up.user_id
        WHERE u.email = :email AND u.is_active = true
        GROUP BY u.id, u.email, u.password_hash, u.role, u.name, u.created_at
    """), {"email": email.lower()})
    
    user = result.fetchone()
    if not user or not pwd_context.verify(password, user.password_hash):
        raise HTTPException(status_code=401, detail="Invalid credentials")
    
    # Generate JWT token
    token_data = {"userId": str(user.id), "email": user.email, "role": user.role}
    token = jwt.encode(
        {**token_data, "exp": datetime.utcnow() + timedelta(hours=24)},
        os.getenv("JWT_SECRET"),
        algorithm="HS256"
    )
    
    return {
        "success": True,
        "data": {
            "token": token,
            "user": {
                "id": str(user.id),
                "email": user.email,
                "name": user.name,
                "role": user.role,
                "permissions": [p for p in user.permissions if p]
            }
        }
    }
```

## 🚀 Server Setup Examples

### Node.js/Express Server
```javascript
// server.js
const express = require('express');
const cors = require('cors');
require('dotenv').config();

const app = express();
const port = process.env.PORT || 8080;

// Middleware
app.use(cors({
  origin: process.env.CORS_ORIGIN?.split(',') || ['http://localhost:3000'],
  credentials: true
}));
app.use(express.json());

// Health check
app.get('/api/v1/health', async (req, res) => {
  try {
    const pool = require('./database');
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

// Start server
app.listen(port, () => {
  console.log(`🚀 GameForge Backend running on http://localhost:${port}/api/v1`);
  console.log(`📊 Database: ${process.env.DB_NAME} on ${process.env.DB_HOST}:${process.env.DB_PORT}`);
});
```

### Python/FastAPI Server
```python
# main.py
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import os
from dotenv import load_dotenv

load_dotenv()

app = FastAPI(title="GameForge API", version="2.0.0")

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=os.getenv("CORS_ORIGIN", "http://localhost:3000").split(","),
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/api/v1/health")
async def health_check():
    try:
        from database import engine
        with engine.connect() as conn:
            result = conn.execute(text("SELECT NOW(), COUNT(*) FROM users"))
            row = result.fetchone()
            return {
                "success": True,
                "message": "Database connected successfully",
                "timestamp": row[0].isoformat(),
                "userCount": row[1],
                "database": os.getenv("DB_NAME")
            }
    except Exception as e:
        raise HTTPException(status_code=500, detail={
            "success": False,
            "error": {"message": "Database connection failed", "details": str(e)}
        })

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=int(os.getenv("PORT", "8080")))
```

## 📊 Database Schema Information

### Available Tables (22 tables)
```sql
-- Core tables your backend can use:
users                 -- User accounts and authentication
user_permissions      -- Role-based permissions
user_sessions         -- Active user sessions
projects              -- User projects
project_collaborators -- Project sharing
assets                -- Project assets/files
ai_requests           -- AI generation requests
audit_logs            -- Security audit trail
api_keys              -- API authentication
storage_configs       -- File storage settings
presigned_urls        -- Secure file access
compliance_events     -- GDPR/CCPA compliance
```

### Key Relationships
```sql
-- User -> Projects (one-to-many)
SELECT * FROM projects WHERE user_id = 'user-uuid';

-- User -> Permissions (many-to-many)
SELECT permission FROM user_permissions WHERE user_id = 'user-uuid';

-- Project -> Assets (one-to-many)
SELECT * FROM assets WHERE project_id = 'project-uuid';

-- Project -> Collaborators (many-to-many)
SELECT * FROM project_collaborators WHERE project_id = 'project-uuid';
```

## 🧪 Testing Commands

### Test Database Connection
```bash
# Direct database test
psql -h localhost -U postgres -d gameforge_dev -c "SELECT COUNT(*) FROM users;"

# Backend health check
curl http://localhost:8080/api/v1/health

# Expected response:
# {
#   "success": true,
#   "message": "Database connected successfully",
#   "timestamp": "2025-09-16T...",
#   "userCount": "0",
#   "database": "gameforge_dev"
# }
```

### Test Authentication
```bash
# Create test user
psql -h localhost -U postgres -d gameforge_dev -c "
INSERT INTO users (email, password_hash, name, role, is_active) 
VALUES ('test@example.com', '\$2a\$12\$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/lewQ5JKKyUOhzjC4.', 'Test User', 'basic_user', true);"

# Test login
curl -X POST http://localhost:8080/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password123"}'
```

## ⚙️ Configuration Checklist

- [ ] `.env` file created with database credentials
- [ ] Database dependencies installed
- [ ] Connection pool/client configured  
- [ ] CORS origins set for frontend URLs
- [ ] JWT secret configured
- [ ] Health endpoint implemented
- [ ] Authentication endpoints implemented
- [ ] Error handling added

## 🚨 Troubleshooting

### Connection Issues
```bash
# Check PostgreSQL service
Get-Service postgresql*

# Test direct connection
psql -h localhost -U postgres -d gameforge_dev

# Check port availability
netstat -ano | findstr :8080
```

### Common Errors
- **"Connection refused"**: PostgreSQL service not running
- **"Authentication failed"**: Wrong password in .env
- **"Database not found"**: Wrong database name
- **"Port in use"**: Another service using port 8080

## 🎯 Next Steps

1. **Configure your backend** using the code examples above
2. **Test the health endpoint** to verify database connection
3. **Implement authentication** using the provided examples
4. **Add your API endpoints** for projects, assets, etc.
5. **Test frontend-backend integration**

Your database is ready with optimized performance settings and complete schema!

---

**Database**: PostgreSQL 17.4 on localhost:5432  
**Schema**: gameforge_dev (22 tables, production-ready)  
**Performance**: Optimized (restart pending for full effect)  
**Security**: Role-based permissions system ready