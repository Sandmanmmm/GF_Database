import React from 'react';
import {
  Box,
  Typography,
  Grid,
  Card,
  CardContent,
  Chip,
  Alert,
  CircularProgress,
  List,
  ListItem,
  ListItemText,
  ListItemIcon,
} from '@mui/material';
import {
  CheckCircle as ConnectedIcon,
  Error as ErrorIcon,
  Storage as DatabaseIcon,
  TableChart as TableIcon,
  People as UsersIcon,
  Upgrade as MigrationIcon,
} from '@mui/icons-material';
import { useQuery } from '@tanstack/react-query';

import { databaseApi } from '../services/api';
import { useDatabaseContext } from '../contexts/DatabaseContext';

const Dashboard: React.FC = () => {
  const { currentEnvironment } = useDatabaseContext();

  const { data: status, isLoading: statusLoading } = useQuery({
    queryKey: ['database-status'],
    queryFn: () => databaseApi.getStatus(),
    refetchInterval: 30000, // Refresh every 30 seconds
  });

  const { data: tables, isLoading: tablesLoading } = useQuery({
    queryKey: ['tables', currentEnvironment],
    queryFn: () => databaseApi.getTables(currentEnvironment),
  });

  const { data: users, isLoading: usersLoading } = useQuery({
    queryKey: ['users', currentEnvironment],
    queryFn: () => databaseApi.getUsers(currentEnvironment),
  });

  const { data: migrations, isLoading: migrationsLoading } = useQuery({
    queryKey: ['migrations', currentEnvironment],
    queryFn: () => databaseApi.getMigrations(currentEnvironment),
  });

  const currentEnvStatus = status?.data?.[currentEnvironment];
  const isConnected = currentEnvStatus?.connected;

  return (
    <Box>
      <Box sx={{ mb: 4 }}>
        <Typography variant="h4" sx={{ fontWeight: 600, mb: 1 }}>
          Database Dashboard
        </Typography>
        <Typography variant="body1" sx={{ opacity: 0.8 }}>
          Monitor and manage your GameForge database environments
        </Typography>
      </Box>

      {/* Connection Status */}
      <Card sx={{ mb: 3 }}>
        <CardContent>
          <Box sx={{ display: 'flex', alignItems: 'center', mb: 2 }}>
            <DatabaseIcon sx={{ mr: 1 }} />
            <Typography variant="h6">Connection Status</Typography>
          </Box>
          
          {statusLoading ? (
            <CircularProgress size={24} />
          ) : (
            <Grid container spacing={2}>
              {Object.entries(status?.data || {}).map(([env, envStatus]) => (
                <Grid item xs={12} md={6} key={env}>
                  <Card variant="outlined">
                    <CardContent>
                      <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', mb: 1 }}>
                        <Typography variant="subtitle1" sx={{ textTransform: 'capitalize' }}>
                          {env === 'dev' ? 'Development' : 'Production'}
                        </Typography>
                        <Chip
                          icon={envStatus.connected ? <ConnectedIcon /> : <ErrorIcon />}
                          label={envStatus.connected ? 'Connected' : 'Error'}
                          color={envStatus.connected ? 'success' : 'error'}
                          size="small"
                        />
                      </Box>
                      
                      {envStatus.connected ? (
                        <List dense>
                          <ListItem disablePadding>
                            <ListItemText 
                              primary="Database" 
                              secondary={envStatus.database}
                              primaryTypographyProps={{ variant: 'body2' }}
                              secondaryTypographyProps={{ variant: 'caption' }}
                            />
                          </ListItem>
                          <ListItem disablePadding>
                            <ListItemText 
                              primary="PostgreSQL Version" 
                              secondary={envStatus.version?.split(',')[0]}
                              primaryTypographyProps={{ variant: 'body2' }}
                              secondaryTypographyProps={{ variant: 'caption' }}
                            />
                          </ListItem>
                        </List>
                      ) : (
                        <Alert severity="error" sx={{ mt: 1 }}>
                          {envStatus.error || 'Connection failed'}
                        </Alert>
                      )}
                    </CardContent>
                  </Card>
                </Grid>
              ))}
            </Grid>
          )}
        </CardContent>
      </Card>

      {/* Current Environment Overview */}
      <Grid container spacing={3} sx={{ mb: 3 }}>
        <Grid item xs={12} md={3}>
          <Card>
            <CardContent>
              <Box sx={{ display: 'flex', alignItems: 'center', mb: 1 }}>
                <TableIcon sx={{ mr: 1, color: 'primary.main' }} />
                <Typography variant="h6">Tables</Typography>
              </Box>
              {tablesLoading ? (
                <CircularProgress size={24} />
              ) : (
                <Typography variant="h3" sx={{ fontWeight: 600 }}>
                  {tables?.data?.length || 0}
                </Typography>
              )}
              <Typography variant="body2" sx={{ opacity: 0.7 }}>
                Database tables
              </Typography>
            </CardContent>
          </Card>
        </Grid>

        <Grid item xs={12} md={3}>
          <Card>
            <CardContent>
              <Box sx={{ display: 'flex', alignItems: 'center', mb: 1 }}>
                <UsersIcon sx={{ mr: 1, color: 'secondary.main' }} />
                <Typography variant="h6">Users</Typography>
              </Box>
              {usersLoading ? (
                <CircularProgress size={24} />
              ) : (
                <Typography variant="h3" sx={{ fontWeight: 600 }}>
                  {users?.data?.length || 0}
                </Typography>
              )}
              <Typography variant="body2" sx={{ opacity: 0.7 }}>
                Database users
              </Typography>
            </CardContent>
          </Card>
        </Grid>

        <Grid item xs={12} md={3}>
          <Card>
            <CardContent>
              <Box sx={{ display: 'flex', alignItems: 'center', mb: 1 }}>
                <MigrationIcon sx={{ mr: 1, color: 'warning.main' }} />
                <Typography variant="h6">Migrations</Typography>
              </Box>
              {migrationsLoading ? (
                <CircularProgress size={24} />
              ) : (
                <Typography variant="h3" sx={{ fontWeight: 600 }}>
                  {migrations?.data?.length || 0}
                </Typography>
              )}
              <Typography variant="body2" sx={{ opacity: 0.7 }}>
                Applied migrations
              </Typography>
            </CardContent>
          </Card>
        </Grid>

        <Grid item xs={12} md={3}>
          <Card>
            <CardContent>
              <Box sx={{ display: 'flex', alignItems: 'center', mb: 1 }}>
                <DatabaseIcon sx={{ mr: 1, color: 'info.main' }} />
                <Typography variant="h6">Status</Typography>
              </Box>
              <Chip
                label={isConnected ? 'Online' : 'Offline'}
                color={isConnected ? 'success' : 'error'}
                sx={{ fontWeight: 600 }}
              />
              <Typography variant="body2" sx={{ opacity: 0.7, mt: 1 }}>
                {currentEnvironment === 'dev' ? 'Development' : 'Production'} environment
              </Typography>
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      {/* Recent Tables */}
      <Card>
        <CardContent>
          <Typography variant="h6" sx={{ mb: 2 }}>
            Database Tables ({currentEnvironment.toUpperCase()})
          </Typography>
          
          {tablesLoading ? (
            <CircularProgress />
          ) : (
            <List>
              {tables?.data?.slice(0, 10).map((table) => (
                <ListItem key={table.table_name} divider>
                  <ListItemIcon>
                    <TableIcon fontSize="small" />
                  </ListItemIcon>
                  <ListItemText
                    primary={table.table_name}
                    secondary={`${table.row_count} rows • ${table.size}`}
                  />
                  <Chip
                    label={table.table_type}
                    size="small"
                    variant="outlined"
                  />
                </ListItem>
              ))}
            </List>
          )}
        </CardContent>
      </Card>
    </Box>
  );
};

export default Dashboard;