import axios from 'axios';

const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:5002';

const api = axios.create({
  baseURL: `${API_BASE_URL}/api`,
  timeout: 30000,
});

export interface TableInfo {
  table_name: string;
  table_type: string;
  row_count: number;
  size: string;
}

export interface MigrationInfo {
  version: string;
  description: string;
  applied_at: string;
  applied_by: string;
  execution_time_ms: number | null;
  status: string;
}

export interface UserInfo {
  username: string;
  display_name: string;
  can_create_db: boolean;
  is_superuser: boolean;
  can_replicate: boolean;
  password_expiry: string | null;
}

export interface CreateUserRequest {
  username: string;
  password: string;
  can_create_db?: boolean;
  is_superuser?: boolean;
  can_replicate?: boolean;
}

export interface UpdateUserRequest {
  can_create_db?: boolean;
  is_superuser?: boolean;
  can_replicate?: boolean;
  new_password?: string;
}

export interface DatabaseStatus {
  dev?: {
    connected: boolean;
    database?: string;
    version?: string;
    timestamp?: string;
    error?: string;
  };
  prod?: {
    connected: boolean;
    database?: string;
    version?: string;
    timestamp?: string;
    error?: string;
  };
}

export interface QueryResult {
  rows: any[];
  rowCount: number;
  executionTime: number;
  command: string;
}

export interface DatabaseMetrics {
  timestamp: string;
  connections: {
    active: number;
    idle: number;
    total: number;
    max: number;
  };
  performance: {
    cacheHitRatio: number;
    commits: number;
    rollbacks: number;
    tuplesReturned: number;
    tuplesFetched: number;
    tuplesInserted: number;
    tuplesUpdated: number;
    tuplesDeleted: number;
    conflicts: number;
    deadlocks: number;
    tempFiles: number;
    tempBytes: number;
  };
  storage: {
    databaseSize: number;
    databaseSizeFormatted: string;
    tablespaces: Array<{
      name: string;
      size: string;
      sizeBytes: number;
    }>;
    largestTables: Array<{
      schema: string;
      name: string;
      totalSize: string;
      tableSize: string;
      indexSize: string;
      sizeBytes: number;
    }>;
  };
  slowQueries: Array<{
    query: string;
    calls: number;
    totalTime: number;
    meanTime: number;
    rows: number;
  }>;
}

export const databaseApi = {
  // Health check
  health: () => api.get('/health'),

  // Database status
  getStatus: (): Promise<{ data: DatabaseStatus }> => 
    api.get('/databases/status'),

  // Tables
  getTables: (env: string): Promise<{ data: TableInfo[] }> => 
    api.get(`/${env}/tables`),

  getTableSchema: (env: string, tableName: string): Promise<{ data: any[] }> => 
    api.get(`/${env}/tables/${tableName}/schema`),

  // Migrations
  getMigrations: (env: string): Promise<{ data: MigrationInfo[] }> => 
    api.get(`/${env}/migrations`),

  // Users
  getUsers: (env: string): Promise<{ data: UserInfo[] }> => 
    api.get(`/${env}/users`),

  createUser: (env: string, userData: CreateUserRequest): Promise<{ data: { message: string; username: string } }> =>
    api.post(`/${env}/users`, userData),

  updateUser: (env: string, username: string, updates: UpdateUserRequest): Promise<{ data: { message: string; username: string } }> =>
    api.put(`/${env}/users/${username}`, updates),

  deleteUser: (env: string, username: string): Promise<{ data: { message: string; username: string } }> =>
    api.delete(`/${env}/users/${username}`),

  updateUserDisplayName: (env: string, username: string, display_name: string): Promise<{ data: { message: string; username: string; display_name: string } }> =>
    api.put(`/${env}/users/${username}/display-name`, { display_name }),

  // User Details
  getUserDetails: (env: string, username: string): Promise<{ data: any }> =>
    api.get(`/${env}/users/${username}/details`),

  getUserDatabases: (env: string, username: string): Promise<{ data: any[] }> =>
    api.get(`/${env}/users/${username}/databases`),

  getUserConnectionHistory: (env: string, username: string): Promise<{ data: any[] }> =>
    api.get(`/${env}/users/${username}/connections`),

  // Database metrics
  getMetrics: (env: string): Promise<{ data: DatabaseMetrics }> =>
    api.get(`/${env}/metrics`),

  // Custom queries
  executeQuery: (
    env: string, 
    query: string, 
    readonly: boolean = true
  ): Promise<{ data: QueryResult }> => 
    api.post(`/${env}/query`, { query, readonly }),
};

export default api;