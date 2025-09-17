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
} from '@mui/material';
import {
  Search as SearchIcon,
  Upgrade as MigrationIcon,
  Refresh as RefreshIcon,
  CheckCircle as SuccessIcon,
  Error as ErrorIcon,
  Schedule as PendingIcon,
} from '@mui/icons-material';
import { useQuery } from '@tanstack/react-query';

import { databaseApi } from '../services/api';
import { useDatabaseContext } from '../contexts/DatabaseContext';

const Migrations: React.FC = () => {
  const { currentEnvironment } = useDatabaseContext();
  const [searchTerm, setSearchTerm] = useState('');

  const { 
    data: migrations, 
    isLoading, 
    error, 
    refetch 
  } = useQuery({
    queryKey: ['migrations', currentEnvironment],
    queryFn: () => databaseApi.getMigrations(currentEnvironment),
    refetchInterval: 60000, // Refresh every minute
  });

  const filteredMigrations = migrations?.data?.filter(migration =>
    migration.version.toLowerCase().includes(searchTerm.toLowerCase()) ||
    migration.description.toLowerCase().includes(searchTerm.toLowerCase())
  ) || [];

  const getStatusIcon = (status: string) => {
    switch (status.toLowerCase()) {
      case 'success':
      case 'applied':
        return <SuccessIcon fontSize="small" />;
      case 'error':
      case 'failed':
        return <ErrorIcon fontSize="small" />;
      default:
        return <PendingIcon fontSize="small" />;
    }
  };

  const getStatusColor = (status: string) => {
    switch (status.toLowerCase()) {
      case 'success':
      case 'applied':
        return 'success';
      case 'error':
      case 'failed':
        return 'error';
      default:
        return 'warning';
    }
  };

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleString();
  };

  const formatExecutionTime = (timeMs: number | null) => {
    if (!timeMs) return 'N/A';
    if (timeMs < 1000) return `${timeMs}ms`;
    return `${(timeMs / 1000).toFixed(2)}s`;
  };

  return (
    <Box>
      <Box sx={{ mb: 4 }}>
        <Typography variant="h4" sx={{ fontWeight: 600, mb: 1 }}>
          Database Migrations
        </Typography>
        <Typography variant="body1" sx={{ opacity: 0.8 }}>
          Track and manage database schema migrations in the {currentEnvironment === 'dev' ? 'Development' : 'Production'} environment
        </Typography>
      </Box>

      {/* Search and Actions */}
      <Grid container spacing={2} sx={{ mb: 3 }}>
        <Grid item xs={12} md={8}>
          <TextField
            fullWidth
            placeholder="Search migrations..."
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
        <Grid item xs={12} md={4}>
          <Button
            variant="outlined"
            startIcon={<RefreshIcon />}
            onClick={() => refetch()}
            fullWidth
          >
            Refresh
          </Button>
        </Grid>
      </Grid>

      {/* Migrations List */}
      <Card>
        <CardContent>
          <Box sx={{ display: 'flex', alignItems: 'center', mb: 2 }}>
            <MigrationIcon sx={{ mr: 1 }} />
            <Typography variant="h6">
              Migrations ({filteredMigrations.length})
            </Typography>
          </Box>

          {error && (
            <Alert severity="error" sx={{ mb: 2 }}>
              Failed to load migrations: {error.message}
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
                    <TableCell>Version</TableCell>
                    <TableCell>Description</TableCell>
                    <TableCell>Status</TableCell>
                    <TableCell>Applied By</TableCell>
                    <TableCell>Applied At</TableCell>
                    <TableCell align="right">Execution Time</TableCell>
                  </TableRow>
                </TableHead>
                <TableBody>
                  {filteredMigrations.map((migration) => (
                    <TableRow 
                      key={migration.version}
                      hover
                    >
                      <TableCell>
                        <Box sx={{ display: 'flex', alignItems: 'center' }}>
                          <MigrationIcon fontSize="small" sx={{ mr: 1, opacity: 0.7 }} />
                          <Typography variant="body2" sx={{ fontFamily: 'monospace' }}>
                            {migration.version}
                          </Typography>
                        </Box>
                      </TableCell>
                      <TableCell>
                        <Typography variant="body2">
                          {migration.description}
                        </Typography>
                      </TableCell>
                      <TableCell>
                        <Chip
                          icon={getStatusIcon(migration.status)}
                          label={migration.status}
                          color={getStatusColor(migration.status) as any}
                          size="small"
                        />
                      </TableCell>
                      <TableCell>
                        <Typography variant="body2">
                          {migration.applied_by || 'Unknown'}
                        </Typography>
                      </TableCell>
                      <TableCell>
                        <Typography variant="body2">
                          {formatDate(migration.applied_at)}
                        </Typography>
                      </TableCell>
                      <TableCell align="right">
                        <Typography variant="body2" sx={{ fontFamily: 'monospace' }}>
                          {formatExecutionTime(migration.execution_time_ms)}
                        </Typography>
                      </TableCell>
                    </TableRow>
                  ))}
                  {filteredMigrations.length === 0 && !isLoading && (
                    <TableRow>
                      <TableCell colSpan={6} align="center" sx={{ py: 4 }}>
                        <Typography variant="body2" sx={{ opacity: 0.7 }}>
                          {searchTerm ? 'No migrations match your search' : 'No migrations found'}
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
    </Box>
  );
};

export default Migrations;