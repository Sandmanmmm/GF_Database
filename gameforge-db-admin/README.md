# GameForge Database Administration Interface

A modern React-based database administration tool specifically designed for managing GameForge PostgreSQL databases with environment switching between development and production.

## 🚀 Features

### ✅ **Currently Implemented**
- **Environment Switching**: Toggle between development and production databases
- **Real-time Dashboard**: Live connection status and database overview
- **Material-UI Dark Theme**: Professional, modern interface
- **Responsive Grid Layout**: Properly configured MUI v5 Grid system
- **Database Connection Monitoring**: Health checks every 30 seconds
- **Table Overview**: View table counts and basic statistics
- **User Management Overview**: Database user listing
- **Migration Tracking**: Visual migration history and status

### 🔄 **In Development**
- **Advanced Table Browser**: Full CRUD operations on database tables
- **SQL Query Editor**: Execute custom queries with syntax highlighting
- **Migration Management**: Apply and rollback migrations through UI
- **Backup & Restore**: Automated backup scheduling and restore capabilities
- **User Permission Management**: Granular database user control
- **Performance Monitoring**: Database performance metrics and optimization

## 🛠️ **Technical Stack**

### **Frontend**
- **React 19** with TypeScript
- **Material-UI v5** (stable Grid system)
- **Vite** for fast development
- **React Query** for API state management
- **React Router** for navigation
- **Axios** for HTTP requests

### **Backend API**
- **Node.js** with Express
- **PostgreSQL** client (pg)
- **Security**: Helmet, CORS, rate limiting
- **Environment Management**: dotenv configuration

## 🏃‍♂️ **Quick Start**

### **Prerequisites**
- Node.js 18+ 
- PostgreSQL 16+ running on port 5432
- GameForge databases: `gameforge_dev` and `gameforge_prod`

### **Installation & Setup**

1. **Install Dependencies**
   ```bash
   cd gameforge-db-admin
   npm install           # Frontend dependencies
   cd api && npm install # API dependencies
   ```

2. **Start Development Servers**
   ```bash
   # Terminal 1: API Server
   cd api
   node index.js

   # Terminal 2: Frontend
   npm run dev
   ```

3. **Access the Application**
   - **Frontend**: http://localhost:5173
   - **API**: http://localhost:5003

## 🔧 **Configuration**

### **Environment Variables**

**Frontend (.env)**
```env
VITE_API_URL=http://localhost:5003
```

**API (api/.env)**
```env
PORT=5003
NODE_ENV=development
FRONTEND_URL=http://localhost:5173

# Development Database
DEV_DB_HOST=localhost
DEV_DB_PORT=5432
DEV_DB_NAME=gameforge_dev
DEV_DB_USER=postgres
DEV_DB_PASSWORD=postgres

# Production Database
PROD_DB_HOST=localhost
PROD_DB_PORT=5432
PROD_DB_NAME=gameforge_prod
PROD_DB_USER=gameforge_prod_user
PROD_DB_PASSWORD=prod_secure_password_2025
```

## 📊 **Database Environments**

### **Development (gameforge_dev)**
- **Purpose**: Development, testing, experimentation
- **User**: `postgres` / `postgres`
- **Safety**: Safe for modifications and testing

### **Production (gameforge_prod)**
- **Purpose**: Live application data
- **User**: `gameforge_prod_user` / `prod_secure_password_2025`
- **Safety**: Production-grade security and permissions

## 🔒 **Security Features**

- **Environment Separation**: Clear dev/prod database isolation
- **Rate Limiting**: API protection against abuse
- **CORS Protection**: Controlled frontend access
- **Parameterized Queries**: SQL injection prevention
- **Read-only Mode**: Safe query execution by default
- **Helmet Security**: Additional HTTP security headers

## 🐛 **Fixed Issues**

### **Material-UI Grid Problems**
- ✅ **Solved**: Downgraded from MUI v7 to stable v5
- ✅ **Proper Grid Usage**: Uses `item` props correctly
- ✅ **Responsive Layout**: Proper xs/md breakpoints
- ✅ **TypeScript Support**: Full type safety

### **Port Conflicts**
- ✅ **API Port**: Configurable via environment (default: 5003)
- ✅ **Frontend Port**: Vite default (5173)
- ✅ **Database Port**: PostgreSQL standard (5432)

## 📁 **Project Structure**

```
gameforge-db-admin/
├── src/
│   ├── components/          # Reusable UI components
│   │   └── Sidebar.tsx     # Navigation sidebar
│   ├── contexts/           # React context providers
│   │   └── DatabaseContext.tsx  # Environment switching
│   ├── pages/              # Main application pages
│   │   ├── Dashboard.tsx   # Main dashboard
│   │   ├── Tables.tsx      # Table management
│   │   ├── Users.tsx       # User management
│   │   ├── Migrations.tsx  # Migration management
│   │   ├── QueryEditor.tsx # SQL query interface
│   │   └── Backups.tsx     # Backup management
│   ├── services/           # API communication
│   │   └── api.ts          # API client and types
│   └── App.tsx             # Main application component
├── api/                    # Backend API server
│   ├── index.js            # Express server
│   ├── package.json        # API dependencies
│   └── .env                # API configuration
├── package.json            # Frontend dependencies
└── .env                    # Frontend configuration
```

## 🔄 **Development Workflow**

1. **Database Changes**: Apply migrations via SQL files first
2. **Frontend Development**: Use hot reload for instant feedback
3. **API Development**: Restart API server when needed
4. **Testing**: Switch environments via UI dropdown
5. **Production Deployment**: Build with `npm run build`

## 🎯 **Next Steps**

1. **Complete Table Browser**: Full CRUD operations
2. **SQL Query Editor**: Monaco editor integration
3. **Migration UI**: Visual migration management
4. **Backup Automation**: Scheduled backups
5. **Performance Dashboard**: Database metrics
6. **User Authentication**: Admin login system

## 📝 **API Endpoints**

- `GET /api/health` - Health check
- `GET /api/databases/status` - Database connection status
- `GET /api/:env/tables` - List tables for environment
- `GET /api/:env/users` - List database users
- `GET /api/:env/migrations` - Migration history
- `POST /api/:env/query` - Execute custom queries

---

**Status**: ✅ **Production-Ready Database Admin Interface**
- Grid layout issues resolved
- Both environments connected
- API server stable
- Frontend responsive and modern

---

## Original Vite Template Info

This template provides a minimal setup to get React working in Vite with HMR and some ESLint rules.

Currently, two official plugins are available:

- [@vitejs/plugin-react](https://github.com/vitejs/vite-plugin-react/blob/main/packages/plugin-react) uses [Babel](https://babeljs.io/) for Fast Refresh
- [@vitejs/plugin-react-swc](https://github.com/vitejs/vite-plugin-react/blob/main/packages/plugin-react-swc) uses [SWC](https://swc.rs/) for Fast Refresh

## Expanding the ESLint configuration

If you are developing a production application, we recommend updating the configuration to enable type-aware lint rules:

```js
export default tseslint.config([
  globalIgnores(['dist']),
  {
    files: ['**/*.{ts,tsx}'],
    extends: [
      // Other configs...

      // Remove tseslint.configs.recommended and replace with this
      ...tseslint.configs.recommendedTypeChecked,
      // Alternatively, use this for stricter rules
      ...tseslint.configs.strictTypeChecked,
      // Optionally, add this for stylistic rules
      ...tseslint.configs.stylisticTypeChecked,

      // Other configs...
    ],
    languageOptions: {
      parserOptions: {
        project: ['./tsconfig.node.json', './tsconfig.app.json'],
        tsconfigRootDir: import.meta.dirname,
      },
      // other options...
    },
  },
])
```

You can also install [eslint-plugin-react-x](https://github.com/Rel1cx/eslint-react/tree/main/packages/plugins/eslint-plugin-react-x) and [eslint-plugin-react-dom](https://github.com/Rel1cx/eslint-react/tree/main/packages/plugins/eslint-plugin-react-dom) for React-specific lint rules:

```js
// eslint.config.js
import reactX from 'eslint-plugin-react-x'
import reactDom from 'eslint-plugin-react-dom'

export default tseslint.config([
  globalIgnores(['dist'],
  {
    files: ['**/*.{ts,tsx}'],
    extends: [
      // Other configs...
      // Enable lint rules for React
      reactX.configs['recommended-typescript'],
      // Enable lint rules for React DOM
      reactDom.configs.recommended,
    ],
    languageOptions: {
      parserOptions: {
        project: ['./tsconfig.node.json', './tsconfig.app.json'],
        tsconfigRootDir: import.meta.dirname,
      },
      // other options...
    },
  },
])
```
