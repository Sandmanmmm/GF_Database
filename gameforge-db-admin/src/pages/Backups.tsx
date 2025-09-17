import React, { useState } from 'react';
import {
  Box,
  Typography,
  Card,
  CardContent,
  Button,
  Grid,
  Alert,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Paper,
  Chip,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  TextField,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  IconButton,
} from '@mui/material';
import {
  Backup as BackupIcon,
  Restore as RestoreIcon,
  Download as DownloadIcon,
  Add as AddIcon,
  Delete as DeleteIcon,
  Schedule as ScheduleIcon,
  CloudUpload as CloudIcon,
} from '@mui/icons-material';

import { useDatabaseContext } from '../contexts/DatabaseContext';

const Backups: React.FC = () => {
  const { currentEnvironment } = useDatabaseContext();
  const [createBackupOpen, setCreateBackupOpen] = useState(false);
  const [backupName, setBackupName] = useState('');
  const [backupType, setBackupType] = useState('full');

  // Mock backup data - in a real implementation, this would come from the API
  const mockBackups = [
    {
      id: 1,
      name: 'daily_backup_2025_09_17',
      type: 'Scheduled',
      size: '234 MB',
      created_at: '2025-09-17T08:00:00Z',
      status: 'Success',
      environment: currentEnvironment,
    },
    {
      id: 2,
      name: 'pre_migration_backup',
      type: 'Manual',
      size: '189 MB',
      created_at: '2025-09-16T14:30:00Z',
      status: 'Success',
      environment: currentEnvironment,
    },
    {
      id: 3,
      name: 'weekly_backup_2025_09_15',
      type: 'Scheduled',
      size: '298 MB',
      created_at: '2025-09-15T02:00:00Z',
      status: 'Success',
      environment: currentEnvironment,
    },
  ];

  const handleCreateBackup = () => {
    // In a real implementation, this would call the API
    console.log('Creating backup:', { name: backupName, type: backupType, environment: currentEnvironment });
    setCreateBackupOpen(false);
    setBackupName('');
    setBackupType('full');
  };

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleString();
  };

  const getStatusColor = (status: string) => {
    switch (status.toLowerCase()) {
      case 'success':
        return 'success';
      case 'failed':
        return 'error';
      case 'in_progress':
        return 'warning';
      default:
        return 'default';
    }
  };

  return (
    <Box>
      <Box sx={{ mb: 4 }}>
        <Typography variant="h4" sx={{ fontWeight: 600, mb: 1 }}>
          Database Backups
        </Typography>
        <Typography variant="body1" sx={{ opacity: 0.8 }}>
          Manage backups and restore points for the {currentEnvironment === 'dev' ? 'Development' : 'Production'} database
        </Typography>
      </Box>

      {/* Quick Actions */}
      <Grid container spacing={2} sx={{ mb: 3 }}>
        <Grid item xs={12} md={3}>
          <Button
            variant="contained"
            startIcon={<AddIcon />}
            onClick={() => setCreateBackupOpen(true)}
            fullWidth
          >
            Create Backup
          </Button>
        </Grid>
        <Grid item xs={12} md={3}>
          <Button
            variant="outlined"
            startIcon={<ScheduleIcon />}
            fullWidth
          >
            Schedule Backup
          </Button>
        </Grid>
        <Grid item xs={12} md={3}>
          <Button
            variant="outlined"
            startIcon={<RestoreIcon />}
            fullWidth
          >
            Restore Database
          </Button>
        </Grid>
        <Grid item xs={12} md={3}>
          <Button
            variant="outlined"
            startIcon={<CloudIcon />}
            fullWidth
          >
            Cloud Storage
          </Button>
        </Grid>
      </Grid>

      {/* Backup Status Alert */}
      <Alert severity="info" sx={{ mb: 3 }}>
        <Typography variant="body2">
          <strong>Note:</strong> Backup functionality is currently in development. 
          The interface shown here demonstrates the planned features for database backup management.
        </Typography>
      </Alert>

      {/* Backup Statistics */}
      <Grid container spacing={2} sx={{ mb: 3 }}>
        <Grid item xs={12} md={4}>
          <Card>
            <CardContent>
              <Box sx={{ display: 'flex', alignItems: 'center', mb: 1 }}>
                <BackupIcon sx={{ mr: 1, color: 'primary.main' }} />
                <Typography variant="h6">Total Backups</Typography>
              </Box>
              <Typography variant="h3" sx={{ fontWeight: 600 }}>
                {mockBackups.length}
              </Typography>
              <Typography variant="body2" sx={{ opacity: 0.7 }}>
                Available backups
              </Typography>
            </CardContent>
          </Card>
        </Grid>

        <Grid item xs={12} md={4}>
          <Card>
            <CardContent>
              <Box sx={{ display: 'flex', alignItems: 'center', mb: 1 }}>
                <ScheduleIcon sx={{ mr: 1, color: 'secondary.main' }} />
                <Typography variant="h6">Last Backup</Typography>
              </Box>
              <Typography variant="h5" sx={{ fontWeight: 600 }}>
                2 hours ago
              </Typography>
              <Typography variant="body2" sx={{ opacity: 0.7 }}>
                Automatic daily backup
              </Typography>
            </CardContent>
          </Card>
        </Grid>

        <Grid item xs={12} md={4}>
          <Card>
            <CardContent>
              <Box sx={{ display: 'flex', alignItems: 'center', mb: 1 }}>
                <CloudIcon sx={{ mr: 1, color: 'info.main' }} />
                <Typography variant="h6">Storage Used</Typography>
              </Box>
              <Typography variant="h5" sx={{ fontWeight: 600 }}>
                721 MB
              </Typography>
              <Typography variant="body2" sx={{ opacity: 0.7 }}>
                Total backup size
              </Typography>
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      {/* Backups List */}
      <Card>
        <CardContent>
          <Box sx={{ display: 'flex', alignItems: 'center', mb: 2 }}>
            <BackupIcon sx={{ mr: 1 }} />
            <Typography variant="h6">
              Recent Backups
            </Typography>
          </Box>

          <TableContainer component={Paper} variant="outlined">
            <Table>
              <TableHead>
                <TableRow>
                  <TableCell>Backup Name</TableCell>
                  <TableCell>Type</TableCell>
                  <TableCell>Size</TableCell>
                  <TableCell>Created</TableCell>
                  <TableCell>Status</TableCell>
                  <TableCell align="right">Actions</TableCell>
                </TableRow>
              </TableHead>
              <TableBody>
                {mockBackups.map((backup) => (
                  <TableRow key={backup.id} hover>
                    <TableCell>
                      <Box sx={{ display: 'flex', alignItems: 'center' }}>
                        <BackupIcon fontSize="small" sx={{ mr: 1, opacity: 0.7 }} />
                        {backup.name}
                      </Box>
                    </TableCell>
                    <TableCell>
                      <Chip
                        label={backup.type}
                        size="small"
                        variant="outlined"
                        color={backup.type === 'Scheduled' ? 'primary' : 'secondary'}
                      />
                    </TableCell>
                    <TableCell>{backup.size}</TableCell>
                    <TableCell>{formatDate(backup.created_at)}</TableCell>
                    <TableCell>
                      <Chip
                        label={backup.status}
                        size="small"
                        color={getStatusColor(backup.status) as any}
                      />
                    </TableCell>
                    <TableCell align="right">
                      <IconButton size="small" title="Download">
                        <DownloadIcon fontSize="small" />
                      </IconButton>
                      <IconButton size="small" title="Restore">
                        <RestoreIcon fontSize="small" />
                      </IconButton>
                      <IconButton size="small" title="Delete" color="error">
                        <DeleteIcon fontSize="small" />
                      </IconButton>
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </TableContainer>
        </CardContent>
      </Card>

      {/* Create Backup Dialog */}
      <Dialog open={createBackupOpen} onClose={() => setCreateBackupOpen(false)} maxWidth="sm" fullWidth>
        <DialogTitle>Create New Backup</DialogTitle>
        <DialogContent>
          <Box sx={{ pt: 1 }}>
            <TextField
              fullWidth
              label="Backup Name"
              value={backupName}
              onChange={(e) => setBackupName(e.target.value)}
              placeholder={`backup_${currentEnvironment}_${new Date().toISOString().split('T')[0]}`}
              sx={{ mb: 2 }}
            />
            <FormControl fullWidth sx={{ mb: 2 }}>
              <InputLabel>Backup Type</InputLabel>
              <Select
                value={backupType}
                onChange={(e) => setBackupType(e.target.value)}
                label="Backup Type"
              >
                <MenuItem value="full">Full Backup</MenuItem>
                <MenuItem value="schema">Schema Only</MenuItem>
                <MenuItem value="data">Data Only</MenuItem>
              </Select>
            </FormControl>
            <Alert severity="info">
              This backup will include all data from the {currentEnvironment === 'dev' ? 'Development' : 'Production'} environment.
            </Alert>
          </Box>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setCreateBackupOpen(false)}>Cancel</Button>
          <Button 
            onClick={handleCreateBackup} 
            variant="contained"
            disabled={!backupName.trim()}
          >
            Create Backup
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
};

export default Backups;