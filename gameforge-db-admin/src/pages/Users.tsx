import React, { useState } from 'react';
import {
  Box,
  Typography,
  Card,
  CardContent,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Paper,
  CircularProgress,
  Alert,
  Chip,
  Button,
  TextField,
  InputAdornment,
  Grid,
  Avatar,
  IconButton,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  FormControlLabel,
  Switch,
  Snackbar,
  Tooltip,
  Menu,
  MenuItem,
  ListItemIcon,
  ListItemText,
} from '@mui/material';
import {
  Search as SearchIcon,
  Person as PersonIcon,
  Refresh as RefreshIcon,
  AdminPanelSettings as AdminIcon,
  Storage as DatabaseIcon,
  ContentCopy as ReplicateIcon,
  Add as AddIcon,
  Edit as EditIcon,
  Delete as DeleteIcon,
  MoreVert as MoreVertIcon,
} from '@mui/icons-material';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';

import { databaseApi } from '../services/api';
import type { CreateUserRequest, UpdateUserRequest } from '../services/api';
import { useDatabaseContext } from '../contexts/DatabaseContext';
import UserDetailsDialog from '../components/UserDetailsDialog';

const Users: React.FC = () => {
  const { currentEnvironment } = useDatabaseContext();
  const queryClient = useQueryClient();
  const [searchTerm, setSearchTerm] = useState('');
  const [createDialogOpen, setCreateDialogOpen] = useState(false);
  const [editDialogOpen, setEditDialogOpen] = useState(false);
  const [selectedUser, setSelectedUser] = useState<any>(null);
  const [anchorEl, setAnchorEl] = useState<null | HTMLElement>(null);
  const [userDetailsOpen, setUserDetailsOpen] = useState(false);
  const [userDetailsData, setUserDetailsData] = useState<any>(null);
  const [snackbar, setSnackbar] = useState<{ open: boolean; message: string; severity: 'success' | 'error' }>({
    open: false,
    message: '',
    severity: 'success'
  });

  // Form states
  const [createForm, setCreateForm] = useState<CreateUserRequest>({
    username: '',
    password: '',
    can_create_db: false,
    is_superuser: false,
    can_replicate: false,
  });

  const [editForm, setEditForm] = useState<UpdateUserRequest & { username: string }>({
    username: '',
    can_create_db: false,
    is_superuser: false,
    can_replicate: false,
    new_password: '',
  });

  const { 
    data: users, 
    isLoading, 
    error, 
    refetch 
  } = useQuery({
    queryKey: ['users', currentEnvironment],
    queryFn: () => databaseApi.getUsers(currentEnvironment),
    refetchInterval: 60000, // Refresh every minute
  });

  // Mutations
  const createUserMutation = useMutation({
    mutationFn: (userData: CreateUserRequest) => databaseApi.createUser(currentEnvironment, userData),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['users', currentEnvironment] });
      setCreateDialogOpen(false);
      setCreateForm({ username: '', password: '', can_create_db: false, is_superuser: false, can_replicate: false });
      setSnackbar({ open: true, message: 'User created successfully', severity: 'success' });
    },
    onError: (error: any) => {
      setSnackbar({ open: true, message: error.response?.data?.error || 'Failed to create user', severity: 'error' });
    }
  });

  const updateUserMutation = useMutation({
    mutationFn: ({ username, ...updates }: UpdateUserRequest & { username: string }) => 
      databaseApi.updateUser(currentEnvironment, username, updates),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['users', currentEnvironment] });
      setEditDialogOpen(false);
      setSnackbar({ open: true, message: 'User updated successfully', severity: 'success' });
    },
    onError: (error: any) => {
      setSnackbar({ open: true, message: error.response?.data?.error || 'Failed to update user', severity: 'error' });
    }
  });

  const deleteUserMutation = useMutation({
    mutationFn: (username: string) => databaseApi.deleteUser(currentEnvironment, username),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['users', currentEnvironment] });
      setSnackbar({ open: true, message: 'User deleted successfully', severity: 'success' });
    },
    onError: (error: any) => {
      setSnackbar({ open: true, message: error.response?.data?.error || 'Failed to delete user', severity: 'error' });
    }
  });

  const filteredUsers = users?.data?.filter(user =>
    user.username.toLowerCase().includes(searchTerm.toLowerCase())
  ) || [];

  const formatDate = (dateString: string | null) => {
    if (!dateString) return 'Never';
    return new Date(dateString).toLocaleDateString();
  };

  const handleCreateUser = () => {
    createUserMutation.mutate(createForm);
  };

  const handleEditUser = (user: any) => {
    setSelectedUser(user);
    setEditForm({
      username: user.username,
      can_create_db: user.can_create_db,
      is_superuser: user.is_superuser,
      can_replicate: user.can_replicate,
      new_password: '',
    });
    setEditDialogOpen(true);
    setAnchorEl(null);
  };

  const handleUpdateUser = () => {
    const updates: UpdateUserRequest = {};
    if (editForm.can_create_db !== selectedUser.can_create_db) updates.can_create_db = editForm.can_create_db;
    if (editForm.is_superuser !== selectedUser.is_superuser) updates.is_superuser = editForm.is_superuser;
    if (editForm.can_replicate !== selectedUser.can_replicate) updates.can_replicate = editForm.can_replicate;
    if (editForm.new_password) updates.new_password = editForm.new_password;

    updateUserMutation.mutate({ username: editForm.username, ...updates });
  };

  const handleDeleteUser = (username: string) => {
    if (confirm(`Are you sure you want to delete user "${username}"?`)) {
      deleteUserMutation.mutate(username);
    }
    setAnchorEl(null);
  };

  const handleUserRowClick = (user: any) => {
    setUserDetailsData(user);
    setUserDetailsOpen(true);
  };

  return (
    <Box>
      <Box sx={{ mb: 4 }}>
        <Typography variant="h4" sx={{ fontWeight: 600, mb: 1 }}>
          Database Users
        </Typography>
        <Typography variant="body1" sx={{ opacity: 0.8 }}>
          Manage users and permissions in the {currentEnvironment === 'dev' ? 'Development' : 'Production'} database
        </Typography>
      </Box>

      {/* Search and Actions */}
      <Grid container spacing={2} sx={{ mb: 3 }}>
        <Grid item xs={12} md={6}>
          <TextField
            fullWidth
            placeholder="Search users..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            InputProps={{
              startAdornment: (
                <InputAdornment position="start">
                  <SearchIcon />
                </InputAdornment>
              ),
            }}
          />
        </Grid>
        <Grid item xs={12} md={3}>
          <Button
            variant="outlined"
            startIcon={<RefreshIcon />}
            onClick={() => refetch()}
            fullWidth
          >
            Refresh
          </Button>
        </Grid>
        <Grid item xs={12} md={3}>
          <Button
            variant="contained"
            startIcon={<AddIcon />}
            onClick={() => setCreateDialogOpen(true)}
            fullWidth
          >
            Create User
          </Button>
        </Grid>
      </Grid>

      {/* Users List */}
      <Card>
        <CardContent>
          <Box sx={{ display: 'flex', alignItems: 'center', mb: 2 }}>
            <PersonIcon sx={{ mr: 1 }} />
            <Typography variant="h6">
              Users ({filteredUsers.length})
            </Typography>
          </Box>

          {error && (
            <Alert severity="error" sx={{ mb: 2 }}>
              Failed to load users: {error.message}
            </Alert>
          )}

          {isLoading ? (
            <Box sx={{ display: 'flex', justifyContent: 'center', py: 4 }}>
              <CircularProgress />
            </Box>
          ) : (
            <TableContainer component={Paper} variant="outlined">
              <Table>
                <TableHead>
                  <TableRow>
                    <TableCell>User</TableCell>
                    <TableCell>Permissions</TableCell>
                    <TableCell>Password Expiry</TableCell>
                    <TableCell align="right">Actions</TableCell>
                  </TableRow>
                </TableHead>
                <TableBody>
                  {filteredUsers.map((user) => (
                    <TableRow 
                      key={user.username}
                      hover
                      onClick={() => handleUserRowClick(user)}
                      sx={{ 
                        cursor: 'pointer',
                        '&:hover': {
                          backgroundColor: 'action.hover'
                        }
                      }}
                    >
                      <TableCell>
                        <Box sx={{ display: 'flex', alignItems: 'center' }}>
                          <Avatar sx={{ mr: 2, width: 32, height: 32 }}>
                            <PersonIcon fontSize="small" />
                          </Avatar>
                          <Box>
                            <Typography variant="body1" sx={{ fontWeight: 500 }}>
                              {user.display_name || user.username}
                            </Typography>
                            {user.display_name && user.display_name !== user.username && (
                              <Typography variant="body2" sx={{ color: 'text.secondary', fontSize: '0.875rem' }}>
                                @{user.username}
                              </Typography>
                            )}
                          </Box>
                        </Box>
                      </TableCell>
                      <TableCell>
                        <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 0.5 }}>
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
                              label="Create DB"
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
                              label="Standard"
                              variant="outlined"
                              size="small"
                            />
                          )}
                        </Box>
                      </TableCell>
                      <TableCell>
                        <Typography 
                          variant="body2" 
                          sx={{ 
                            color: user.password_expiry ? 'text.primary' : 'text.secondary',
                            fontStyle: user.password_expiry ? 'normal' : 'italic'
                          }}
                        >
                          {formatDate(user.password_expiry)}
                        </Typography>
                      </TableCell>
                      <TableCell align="right">
                        <Tooltip title="User actions">
                          <IconButton
                            onClick={(e) => {
                              e.stopPropagation(); // Prevent row click when clicking actions
                              setSelectedUser(user);
                              setAnchorEl(e.currentTarget);
                            }}
                          >
                            <MoreVertIcon />
                          </IconButton>
                        </Tooltip>
                      </TableCell>
                    </TableRow>
                  ))}
                  {filteredUsers.length === 0 && !isLoading && (
                    <TableRow>
                      <TableCell colSpan={4} align="center" sx={{ py: 4 }}>
                        <Typography variant="body2" sx={{ opacity: 0.7 }}>
                          {searchTerm ? 'No users match your search' : 'No users found'}
                        </Typography>
                      </TableCell>
                    </TableRow>
                  )}
                </TableBody>
              </Table>
            </TableContainer>
          )}
        </CardContent>
      </Card>

      {/* User Actions Menu */}
      <Menu
        anchorEl={anchorEl}
        open={Boolean(anchorEl)}
        onClose={() => setAnchorEl(null)}
      >
        <MenuItem onClick={() => handleEditUser(selectedUser)}>
          <ListItemIcon>
            <EditIcon fontSize="small" />
          </ListItemIcon>
          <ListItemText>Edit User</ListItemText>
        </MenuItem>
        <MenuItem onClick={() => handleDeleteUser(selectedUser?.username)}>
          <ListItemIcon>
            <DeleteIcon fontSize="small" />
          </ListItemIcon>
          <ListItemText>Delete User</ListItemText>
        </MenuItem>
      </Menu>

      {/* Create User Dialog */}
      <Dialog open={createDialogOpen} onClose={() => setCreateDialogOpen(false)} maxWidth="sm" fullWidth>
        <DialogTitle>Create New User</DialogTitle>
        <DialogContent>
          <Box sx={{ pt: 1 }}>
            <TextField
              fullWidth
              label="Username"
              value={createForm.username}
              onChange={(e) => setCreateForm({ ...createForm, username: e.target.value })}
              sx={{ mb: 2 }}
            />
            <TextField
              fullWidth
              label="Password"
              type="password"
              value={createForm.password}
              onChange={(e) => setCreateForm({ ...createForm, password: e.target.value })}
              sx={{ mb: 2 }}
            />
            <Box sx={{ display: 'flex', flexDirection: 'column', gap: 1 }}>
              <FormControlLabel
                control={
                  <Switch
                    checked={createForm.can_create_db || false}
                    onChange={(e) => setCreateForm({ ...createForm, can_create_db: e.target.checked })}
                  />
                }
                label="Can Create Databases"
              />
              <FormControlLabel
                control={
                  <Switch
                    checked={createForm.is_superuser || false}
                    onChange={(e) => setCreateForm({ ...createForm, is_superuser: e.target.checked })}
                  />
                }
                label="Superuser"
              />
              <FormControlLabel
                control={
                  <Switch
                    checked={createForm.can_replicate || false}
                    onChange={(e) => setCreateForm({ ...createForm, can_replicate: e.target.checked })}
                  />
                }
                label="Replication"
              />
            </Box>
          </Box>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setCreateDialogOpen(false)}>Cancel</Button>
          <Button 
            onClick={handleCreateUser} 
            variant="contained"
            disabled={!createForm.username || !createForm.password || createUserMutation.isPending}
          >
            {createUserMutation.isPending ? 'Creating...' : 'Create User'}
          </Button>
        </DialogActions>
      </Dialog>

      {/* Edit User Dialog */}
      <Dialog open={editDialogOpen} onClose={() => setEditDialogOpen(false)} maxWidth="sm" fullWidth>
        <DialogTitle>Edit User: {editForm.username}</DialogTitle>
        <DialogContent>
          <Box sx={{ pt: 1 }}>
            <TextField
              fullWidth
              label="New Password (optional)"
              type="password"
              value={editForm.new_password || ''}
              onChange={(e) => setEditForm({ ...editForm, new_password: e.target.value })}
              sx={{ mb: 2 }}
              helperText="Leave empty to keep current password"
            />
            <Box sx={{ display: 'flex', flexDirection: 'column', gap: 1 }}>
              <FormControlLabel
                control={
                  <Switch
                    checked={editForm.can_create_db || false}
                    onChange={(e) => setEditForm({ ...editForm, can_create_db: e.target.checked })}
                  />
                }
                label="Can Create Databases"
              />
              <FormControlLabel
                control={
                  <Switch
                    checked={editForm.is_superuser || false}
                    onChange={(e) => setEditForm({ ...editForm, is_superuser: e.target.checked })}
                  />
                }
                label="Superuser"
              />
              <FormControlLabel
                control={
                  <Switch
                    checked={editForm.can_replicate || false}
                    onChange={(e) => setEditForm({ ...editForm, can_replicate: e.target.checked })}
                  />
                }
                label="Replication"
              />
            </Box>
          </Box>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setEditDialogOpen(false)}>Cancel</Button>
          <Button 
            onClick={handleUpdateUser} 
            variant="contained"
            disabled={updateUserMutation.isPending}
          >
            {updateUserMutation.isPending ? 'Updating...' : 'Update User'}
          </Button>
        </DialogActions>
      </Dialog>

      {/* Snackbar for notifications */}
      <Snackbar
        open={snackbar.open}
        autoHideDuration={6000}
        onClose={() => setSnackbar({ ...snackbar, open: false })}
      >
        <Alert 
          onClose={() => setSnackbar({ ...snackbar, open: false })} 
          severity={snackbar.severity}
          sx={{ width: '100%' }}
        >
          {snackbar.message}
        </Alert>
      </Snackbar>

      {/* User Details Dialog */}
      <UserDetailsDialog
        open={userDetailsOpen}
        onClose={() => setUserDetailsOpen(false)}
        user={userDetailsData}
        environment={currentEnvironment}
      />
    </Box>
  );
};

export default Users;