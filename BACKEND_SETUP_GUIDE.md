# 🚀 GameForge-2.0 Backend Setup Guide

## 🎯 Immediate Action Required

Your GameForge-2.0 frontend is configured to connect to `http://localhost:8080/api/v1` but needs a backend server. Here's how to set it up quickly:

## ✅ Current Database Status
- **PostgreSQL 17.4**: Running on `localhost:5432`
- **Database**: `gameforge_dev` (19 tables, ready)
- **Performance**: Optimized (restart pending for full effect)
- **Schema**: Complete with users, projects, assets, permissions

## 🚀 Quick Backend Setup

### Step 1: Create Backend Directory
```powershell
# Navigate to your GameForge-2.0 project
cd "d:\GameForge_2.0\GameForge-2.0"

# Create backend directory
mkdir backend
cd backend

# Initialize Node.js project
npm init -y
```

### Step 2: Install Dependencies
```powershell
npm install express cors pg dotenv bcryptjs jsonwebtoken
npm install -D nodemon
```

### Step 3: Create Environment File
Create `.env` file in the backend directory:
```bash
# Database Configuration
DB_HOST=localhost
DB_PORT=5432
DB_NAME=gameforge_dev
DB_USER=postgres
DB_PASSWORD=your-postgres-password-here

# Server Configuration
PORT=8080
NODE_ENV=development

# JWT Secret (change for production)
JWT_SECRET=your-super-secret-jwt-key-here
```

### Step 4: Create Server File
Create `server.js` in the backend directory:

```javascript
const express = require('express');
const cors = require('cors');
const { Pool } = require('pg');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
require('dotenv').config();

const app = express();
const port = process.env.PORT || 8080;

// Database connection pool
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

// Test database connection
pool.connect((err, client, release) => {
  if (err) {
    console.error('❌ Database connection failed:', err.stack);
    process.exit(1);
  } else {
    console.log('✅ Database connected successfully');
    client.query('SELECT COUNT(*) FROM users', (err, result) => {
      release();
      if (!err) {
        console.log(`📊 Database has ${result.rows[0].count} users`);
      }
    });
  }
});

// Middleware
app.use(cors({
  origin: ['http://localhost:3000', 'http://localhost:5173'],
  credentials: true
}));
app.use(express.json());

// Health check endpoint
app.get('/api/v1/health', async (req, res) => {
  try {
    const client = await pool.connect();
    const result = await client.query('SELECT NOW()');
    client.release();
    
    res.json({
      success: true,
      message: 'Database connected successfully',
      timestamp: result.rows[0].now,
      database: process.env.DB_NAME
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: { message: 'Database connection failed', details: error.message }
    });
  }
});

// Authentication - Login
app.post('/api/v1/auth/login', async (req, res) => {
  const { email, password } = req.body;
  
  try {
    const client = await pool.connect();
    const userQuery = `
      SELECT u.id, u.email, u.password_hash, u.role, u.name, u.created_at,
             array_agg(DISTINCT up.permission) as permissions
      FROM users u
      LEFT JOIN user_permissions up ON u.id = up.user_id
      WHERE u.email = $1 AND u.is_active = true
      GROUP BY u.id, u.email, u.password_hash, u.role, u.name, u.created_at
    `;
    const result = await client.query(userQuery, [email.toLowerCase()]);
    client.release();
    
    if (result.rows.length === 0) {
      return res.status(401).json({
        success: false,
        error: { message: 'Invalid credentials' }
      });
    }
    
    const user = result.rows[0];
    
    // Verify password (assuming passwords are hashed)
    const isValidPassword = await bcrypt.compare(password, user.password_hash);
    if (!isValidPassword) {
      return res.status(401).json({
        success: false,
        error: { message: 'Invalid credentials' }
      });
    }
    
    // Generate JWT token
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

// Authentication - Register
app.post('/api/v1/auth/register', async (req, res) => {
  const { email, password, name } = req.body;
  
  try {
    const client = await pool.connect();
    
    // Check if user exists
    const existingUser = await client.query('SELECT id FROM users WHERE email = $1', [email.toLowerCase()]);
    if (existingUser.rows.length > 0) {
      client.release();
      return res.status(409).json({
        success: false,
        error: { message: 'User already exists' }
      });
    }
    
    // Hash password
    const passwordHash = await bcrypt.hash(password, 12);
    
    // Create user
    const insertQuery = `
      INSERT INTO users (email, password_hash, name, role, is_active)
      VALUES ($1, $2, $3, $4, $5)
      RETURNING id, email, name, role, created_at
    `;
    const result = await client.query(insertQuery, [
      email.toLowerCase(),
      passwordHash,
      name || email.split('@')[0],
      'basic_user',
      true
    ]);
    
    const newUser = result.rows[0];
    client.release();
    
    // Generate JWT token
    const token = jwt.sign(
      { userId: newUser.id, email: newUser.email, role: newUser.role },
      process.env.JWT_SECRET,
      { expiresIn: '24h' }
    );
    
    res.status(201).json({
      success: true,
      data: {
        token,
        user: newUser
      }
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: { message: 'Registration failed', details: error.message }
    });
  }
});

// JWT Authentication middleware
const authenticateToken = async (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];
  
  if (!token) {
    return res.status(401).json({
      success: false,
      error: { message: 'Access token required' }
    });
  }
  
  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    
    // Get user from database
    const client = await pool.connect();
    const userQuery = `
      SELECT u.id, u.email, u.role, u.name,
             array_agg(DISTINCT up.permission) as permissions
      FROM users u
      LEFT JOIN user_permissions up ON u.id = up.user_id
      WHERE u.id = $1 AND u.is_active = true
      GROUP BY u.id, u.email, u.role, u.name
    `;
    const result = await client.query(userQuery, [decoded.userId]);
    client.release();
    
    if (result.rows.length === 0) {
      return res.status(401).json({
        success: false,
        error: { message: 'User not found' }
      });
    }
    
    req.user = {
      ...result.rows[0],
      permissions: result.rows[0].permissions.filter(p => p !== null)
    };
    next();
  } catch (error) {
    return res.status(403).json({
      success: false,
      error: { message: 'Invalid token' }
    });
  }
};

// Protected routes
app.get('/api/v1/auth/me', authenticateToken, (req, res) => {
  res.json({
    success: true,
    data: { user: req.user }
  });
});

// Projects endpoints
app.get('/api/v1/projects', authenticateToken, async (req, res) => {
  try {
    const client = await pool.connect();
    const query = `
      SELECT p.*, u.name as owner_name
      FROM projects p
      JOIN users u ON p.user_id = u.id
      WHERE p.user_id = $1
      ORDER BY p.updated_at DESC
    `;
    const result = await client.query(query, [req.user.id]);
    client.release();
    
    res.json({
      success: true,
      data: result.rows
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: { message: 'Failed to fetch projects' }
    });
  }
});

app.post('/api/v1/projects', authenticateToken, async (req, res) => {
  const { name, description, config } = req.body;
  
  try {
    const client = await pool.connect();
    const query = `
      INSERT INTO projects (name, description, config, user_id, status)
      VALUES ($1, $2, $3, $4, $5)
      RETURNING *
    `;
    const result = await client.query(query, [
      name,
      description || '',
      config || {},
      req.user.id,
      'active'
    ]);
    client.release();
    
    res.status(201).json({
      success: true,
      data: result.rows[0]
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: { message: 'Failed to create project' }
    });
  }
});

// Start server
app.listen(port, () => {
  console.log(`🚀 GameForge Backend running on http://localhost:${port}/api/v1`);
  console.log(`📊 Database: ${process.env.DB_NAME} on ${process.env.DB_HOST}:${process.env.DB_PORT}`);
  console.log(`🔗 Frontend should use: http://localhost:${port}/api/v1`);
});

// Graceful shutdown
process.on('SIGINT', async () => {
  console.log('\\n🛑 Shutting down...');
  await pool.end();
  process.exit(0);
});
```

### Step 5: Update package.json Scripts
Add to your `package.json`:
```json
{
  "scripts": {
    "start": "node server.js",
    "dev": "nodemon server.js"
  }
}
```

### Step 6: Start Backend Server
```powershell
# From the backend directory
npm run dev
```

Expected output:
```
✅ Database connected successfully
📊 Database has X users
🚀 GameForge Backend running on http://localhost:8080/api/v1
📊 Database: gameforge_dev on localhost:5432
🔗 Frontend should use: http://localhost:8080/api/v1
```

## 🧪 Testing the Connection

### 1. Test Health Endpoint
```powershell
curl http://localhost:8080/api/v1/health
```

Expected response:
```json
{
  "success": true,
  "message": "Database connected successfully",
  "timestamp": "2025-09-16T...",
  "database": "gameforge_dev"
}
```

### 2. Test from Frontend
In your browser console or frontend code:
```javascript
// Test API connection
fetch('http://localhost:8080/api/v1/health')
  .then(response => response.json())
  .then(data => console.log('✅ Backend connected:', data))
  .catch(error => console.error('❌ Connection failed:', error));
```

### 3. Test Authentication
```javascript
// Test user registration
fetch('http://localhost:8080/api/v1/auth/register', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    email: 'test@example.com',
    password: 'password123',
    name: 'Test User'
  })
})
.then(response => response.json())
.then(data => console.log('Registration:', data));
```

## 🔧 Frontend Environment Check

Ensure your GameForge-2.0 `.env` file contains:
```bash
VITE_GAMEFORGE_API_URL=http://localhost:8080/api/v1
```

## 🚨 Troubleshooting

### Backend won't start
1. Check PostgreSQL service: `Get-Service postgresql*`
2. Verify database exists: `psql -U postgres -l | findstr gameforge`
3. Check port 8080 availability: `netstat -ano | findstr :8080`

### Database connection fails
1. Test direct connection: `psql -h localhost -U postgres -d gameforge_dev`
2. Verify credentials in `.env` file
3. Check firewall settings

### CORS errors
- Ensure frontend URL is in CORS origins
- Check browser console for specific CORS error details

## ✅ Success Indicators

- [ ] Backend starts without errors
- [ ] Database connection successful
- [ ] Health endpoint returns 200 OK
- [ ] Frontend can call `/api/v1/health`
- [ ] User registration works
- [ ] Authentication returns JWT token

## 🎯 Next Steps

Once connected:
1. **Test user registration/login** from your frontend
2. **Create/fetch projects** to verify full data flow
3. **Complete PostgreSQL service restart** for performance optimization
4. **Implement additional API endpoints** as needed

Your database is production-ready with 19 tables, proper relationships, and performance optimizations. This backend setup will immediately connect your frontend to the database!

---

**Created**: September 16, 2025  
**Purpose**: Quick backend setup for GameForge-2.0  
**Database**: PostgreSQL 17.4 gameforge_dev (ready)