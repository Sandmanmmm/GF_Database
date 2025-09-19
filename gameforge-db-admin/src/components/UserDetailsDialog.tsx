import React, { useState } from 'react';
import {
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Button,
  Typography,
  Box,
  Grid,
  Card,
  CardContent,
  Chip,
  Avatar,
  List,
  ListItem,
  ListItemText,
  ListItemIcon,
  Tab,
  Tabs,
  CircularProgress,
  Alert,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Paper,
  IconButton,
} from '@mui/material';
import {
  Person as PersonIcon,
  AdminPanelSettings as AdminIcon,
  Storage as DatabaseIcon,
  ContentCopy as ReplicateIcon,
  Security as SecurityIcon,
  History as HistoryIcon,
  Assignment as PermissionsIcon,
  Close as CloseIcon,
  AccessTime as TimeIcon,
  Lock as LockIcon,
  CheckCircle as ActiveIcon,
  Cancel as InactiveIcon,
  VpnKey as KeyIcon,
  Event as EventIcon,
} from '@mui/icons-material';
import { useQuery } from '@tanstack/react-query';
import { databaseApi } from '../services/api';

interface UserDetailsDialogProps {
  open: boolean;
  onClose: () => void;
  user: any;
  environment: string;
}

interface TabPanelProps {
  children?: React.ReactNode;
  index: number;
  value: number;
}

function TabPanel(props: TabPanelProps) {
  const { children, value, index, ...other } = props;

  return (
    <div
      role="tabpanel"
      hidden={value !== index}
      id={`user-tabpanel-${index}`}
      aria-labelledby={`user-tab-${index}`}
      {...other}
    >
      {value === index && (
        <Box sx={{ p: 3 }}>
          {children}
        </Box>
      )}
    </div>
  );
}

const UserDetailsDialog: React.FC<UserDetailsDialogProps> = ({
  open,
  onClose,
  user,
  environment,
}) => {
  const [currentTab, setCurrentTab] = useState(0);

  // Fetch detailed user information
  const { data: userDetails, isLoading: isLoadingDetails } = useQuery({
    queryKey: ['userDetails', user?.username, environment],
    queryFn: () => databaseApi.getUserDetails(environment, user?.username),
    enabled: open && !!user?.username,
  });

  // Fetch user's database ownership
  const { data: ownedDatabases, isLoading: isLoadingDatabases } = useQuery({
    queryKey: ['userDatabases', user?.username, environment],
    queryFn: () => databaseApi.getUserDatabases(environment, user?.username),
    enabled: open && !!user?.username,
  });

  // Fetch user's connection history
  const { data: connectionHistory, isLoading: isLoadingHistory } = useQuery({
    queryKey: ['userConnections', user?.username, environment],
    queryFn: () => databaseApi.getUserConnectionHistory(environment, user?.username),
    enabled: open && !!user?.username,
  });

  const handleTabChange = (_event: React.SyntheticEvent, newValue: number) => {
    setCurrentTab(newValue);
  };

  const formatDate = (dateString: string | null) => {
    if (!dateString) return 'Never';
    return new Date(dateString).toLocaleString();
  };

  const formatDuration = (seconds: number | null) => {
    if (!seconds) return '0s';
    const hours = Math.floor(seconds / 3600);
    const minutes = Math.floor((seconds % 3600) / 60);
    const secs = seconds % 60;
    
    if (hours > 0) return `${hours}h ${minutes}m ${secs}s`;
    if (minutes > 0) return `${minutes}m ${secs}s`;
    return `${secs}s`;
  };

  if (!user) return null;

  return (
    <Dialog
      open={open}
      onClose={onClose}
      maxWidth="lg"
      fullWidth
      PaperProps={{
        sx: {
          minHeight: '80vh',
          maxHeight: '90vh',
        },
      }}
    >
      <DialogTitle sx={{ m: 0, p: 2, display: 'flex', alignItems: 'center' }}>
        <Avatar sx={{ mr: 2 }}>
          <PersonIcon />
        </Avatar>
        <Box sx={{ flexGrow: 1 }}>
          <Typography variant="h5" component="div">
            {user.display_name || user.username}
          </Typography>
          <Typography variant="body2" color="text.secondary">
            {user.display_name && user.display_name !== user.username ? `@${user.username} • ` : ''}User Details & Permissions
          </Typography>
        </Box>
        <IconButton
          aria-label="close"
          onClick={onClose}
          sx={{
            position: 'absolute',
            right: 8,
            top: 8,
            color: (theme) => theme.palette.grey[500],
          }}
        >
          <CloseIcon />
        </IconButton>
      </DialogTitle>

      <DialogContent dividers>
        {/* User Overview Card */}
        <Card sx={{ mb: 3 }}>
          <CardContent>
            <Grid container spacing={3}>
              <Grid item xs={12} md={6}>
                <Box sx={{ display: 'flex', alignItems: 'center', mb: 2 }}>
                  <SecurityIcon sx={{ mr: 1, color: 'primary.main' }} />
                  <Typography variant="h6">Security Status</Typography>
                </Box>
                <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 1, mb: 2 }}>
                  {user.is_superuser && (
                    <Chip
                      icon={<AdminIcon fontSize="small" />}
                      label="Superuser"
                      color="error"
                      size="small"
                    />
                  )}
                  {user.can_create_db && (
                    <Chip
                      icon={<DatabaseIcon fontSize="small" />}
                      label="Create Databases"
                      color="primary"
                      size="small"
                    />
                  )}
                  {user.can_replicate && (
                    <Chip
                      icon={<ReplicateIcon fontSize="small" />}
                      label="Replication"
                      color="secondary"
                      size="small"
                    />
                  )}
                  {!user.is_superuser && !user.can_create_db && !user.can_replicate && (
                    <Chip
                      label="Standard User"
                      variant="outlined"
                      size="small"
                    />
                  )}
                </Box>
                <List dense>
                  <ListItem>
                    <ListItemIcon>
                      <LockIcon fontSize="small" />
                    </ListItemIcon>
                    <ListItemText
                      primary="Password Expiry"
                      secondary={formatDate(user.password_expiry)}
                    />
                  </ListItem>
                  <ListItem>
                    <ListItemIcon>
                      <EventIcon fontSize="small" />
                    </ListItemIcon>
                    <ListItemText
                      primary="Account Created"
                      secondary={formatDate(user.created_at)}
                    />
                  </ListItem>
                </List>
              </Grid>
              <Grid item xs={12} md={6}>
                <Box sx={{ display: 'flex', alignItems: 'center', mb: 2 }}>
                  <HistoryIcon sx={{ mr: 1, color: 'secondary.main' }} />
                  <Typography variant="h6">Activity Overview</Typography>
                </Box>
                {isLoadingDetails ? (
                  <CircularProgress size={24} />
                ) : userDetails?.data ? (
                  <List dense>
                    <ListItem>
                      <ListItemIcon>
                        <TimeIcon fontSize="small" />
                      </ListItemIcon>
                      <ListItemText
                        primary="Last Login"
                        secondary={formatDate(userDetails.data.last_login)}
                      />
                    </ListItem>
                    <ListItem>
                      <ListItemIcon>
                        {userDetails.data.is_active ? (
                          <ActiveIcon fontSize="small" color="success" />
                        ) : (
                          <InactiveIcon fontSize="small" color="error" />
                        )}
                      </ListItemIcon>
                      <ListItemText
                        primary="Status"
                        secondary={userDetails.data.is_active ? 'Active' : 'Inactive'}
                      />
                    </ListItem>
                    <ListItem>
                      <ListItemIcon>
                        <KeyIcon fontSize="small" />
                      </ListItemIcon>
                      <ListItemText
                        primary="Connection Count"
                        secondary={`${userDetails.data.connection_count || 0} total connections`}
                      />
                    </ListItem>
                  </List>
                ) : (
                  <Alert severity="info">No activity data available</Alert>
                )}
              </Grid>
            </Grid>
          </CardContent>
        </Card>

        {/* Tabs for detailed information */}
        <Box sx={{ borderBottom: 1, borderColor: 'divider' }}>
          <Tabs value={currentTab} onChange={handleTabChange} aria-label="user details tabs">
            <Tab label="Permissions" icon={<PermissionsIcon />} />
            <Tab label="Owned Databases" icon={<DatabaseIcon />} />
            <Tab label="Connection History" icon={<HistoryIcon />} />
          </Tabs>
        </Box>

        <TabPanel value={currentTab} index={0}>
          <Typography variant="h6" gutterBottom>
            Database Permissions
          </Typography>
          {isLoadingDetails ? (
            <CircularProgress />
          ) : userDetails?.data?.permissions ? (
            <TableContainer component={Paper} variant="outlined">
              <Table size="small">
                <TableHead>
                  <TableRow>
                    <TableCell>Database</TableCell>
                    <TableCell>Schema</TableCell>
                    <TableCell>Object Type</TableCell>
                    <TableCell>Permissions</TableCell>
                  </TableRow>
                </TableHead>
                <TableBody>
                  {userDetails.data.permissions.map((permission: any, index: number) => (
                    <TableRow key={index}>
                      <TableCell>{permission.database || 'All'}</TableCell>
                      <TableCell>{permission.schema || 'All'}</TableCell>
                      <TableCell>{permission.object_type}</TableCell>
                      <TableCell>
                        <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 0.5 }}>
                          {permission.privileges?.map((privilege: string) => (
                            <Chip
                              key={privilege}
                              label={privilege}
                              size="small"
                              variant="outlined"
                            />
                          ))}
                        </Box>
                      </TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            </TableContainer>
          ) : (
            <Alert severity="info">No specific permissions found. User inherits default permissions.</Alert>
          )}
        </TabPanel>

        <TabPanel value={currentTab} index={1}>
          <Typography variant="h6" gutterBottom>
            Owned Databases
          </Typography>
          {isLoadingDatabases ? (
            <CircularProgress />
          ) : ownedDatabases?.data && ownedDatabases.data.length > 0 ? (
            <Grid container spacing={2}>
              {ownedDatabases.data.map((database: any) => (
                <Grid item xs={12} md={6} key={database.name}>
                  <Card variant="outlined">
                    <CardContent>
                      <Box sx={{ display: 'flex', alignItems: 'center', mb: 1 }}>
                        <DatabaseIcon sx={{ mr: 1, color: 'primary.main' }} />
                        <Typography variant="h6">{database.name}</Typography>
                      </Box>
                      <Typography variant="body2" color="text.secondary" gutterBottom>
                        Created: {formatDate(database.created_at)}
                      </Typography>
                      <Typography variant="body2">
                        Size: {database.size || 'Unknown'}
                      </Typography>
                      <Typography variant="body2">
                        Tables: {database.table_count || 0}
                      </Typography>
                    </CardContent>
                  </Card>
                </Grid>
              ))}
            </Grid>
          ) : (
            <Alert severity="info">User does not own any databases.</Alert>
          )}
        </TabPanel>

        <TabPanel value={currentTab} index={2}>
          <Typography variant="h6" gutterBottom>
            Recent Connection History
          </Typography>
          {isLoadingHistory ? (
            <CircularProgress />
          ) : connectionHistory?.data && connectionHistory.data.length > 0 ? (
            <TableContainer component={Paper} variant="outlined">
              <Table size="small">
                <TableHead>
                  <TableRow>
                    <TableCell>Connection Time</TableCell>
                    <TableCell>Client IP</TableCell>
                    <TableCell>Database</TableCell>
                    <TableCell>Duration</TableCell>
                    <TableCell>Status</TableCell>
                  </TableRow>
                </TableHead>
                <TableBody>
                  {connectionHistory.data.slice(0, 20).map((connection: any, index: number) => (
                    <TableRow key={index}>
                      <TableCell>{formatDate(connection.connect_time)}</TableCell>
                      <TableCell>{connection.client_addr || 'Local'}</TableCell>
                      <TableCell>{connection.database}</TableCell>
                      <TableCell>{formatDuration(connection.duration)}</TableCell>
                      <TableCell>
                        <Chip
                          label={connection.state || 'Connected'}
                          color={connection.state === 'active' ? 'success' : 'default'}
                          size="small"
                        />
                      </TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            </TableContainer>
          ) : (
            <Alert severity="info">No connection history available.</Alert>
          )}
        </TabPanel>
      </DialogContent>

      <DialogActions>
        <Button onClick={onClose} variant="outlined">
          Close
        </Button>
      </DialogActions>
    </Dialog>
  );
};

export default UserDetailsDialog;