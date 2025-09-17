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
  TableChart as TableIcon,
  Refresh as RefreshIcon,
} from '@mui/icons-material';
import { useQuery } from '@tanstack/react-query';

import { databaseApi } from '../services/api';
import { useDatabaseContext } from '../contexts/DatabaseContext';

const Tables: React.FC = () => {
  const { currentEnvironment } = useDatabaseContext();
  const [searchTerm, setSearchTerm] = useState('');

  const { 
    data: tables, 
    isLoading, 
    error, 
    refetch 
  } = useQuery({
    queryKey: ['tables', currentEnvironment],
    queryFn: () => databaseApi.getTables(currentEnvironment),
    refetchInterval: 60000, // Refresh every minute
  });

  const filteredTables = tables?.data?.filter(table =>
    table.table_name.toLowerCase().includes(searchTerm.toLowerCase())
  ) || [];

  return (
    <Box>
      <Box sx={{ mb: 4 }}>
        <Typography variant="h4" sx={{ fontWeight: 600, mb: 1 }}>
          Database Tables
        </Typography>
        <Typography variant="body1" sx={{ opacity: 0.8 }}>
          Browse and manage tables in the {currentEnvironment === 'dev' ? 'Development' : 'Production'} database
        </Typography>
      </Box>

      {/* Search and Actions */}
      <Grid container spacing={2} sx={{ mb: 3 }}>
        <Grid item xs={12} md={8}>
          <TextField
            fullWidth
            placeholder="Search tables..."
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

      {/* Tables List */}
      <Card>
        <CardContent>
          <Box sx={{ display: 'flex', alignItems: 'center', mb: 2 }}>
            <TableIcon sx={{ mr: 1 }} />
            <Typography variant="h6">
              Tables ({filteredTables.length})
            </Typography>
          </Box>

          {error && (
            <Alert severity="error" sx={{ mb: 2 }}>
              Failed to load tables: {error.message}
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
                    <TableCell>Table Name</TableCell>
                    <TableCell>Type</TableCell>
                    <TableCell align="right">Rows</TableCell>
                    <TableCell align="right">Size</TableCell>
                  </TableRow>
                </TableHead>
                <TableBody>
                  {filteredTables.map((table) => (
                    <TableRow 
                      key={table.table_name}
                      hover
                      sx={{ cursor: 'pointer' }}
                    >
                      <TableCell>
                        <Box sx={{ display: 'flex', alignItems: 'center' }}>
                          <TableIcon fontSize="small" sx={{ mr: 1, opacity: 0.7 }} />
                          {table.table_name}
                        </Box>
                      </TableCell>
                      <TableCell>
                        <Chip
                          label={table.table_type}
                          size="small"
                          variant="outlined"
                        />
                      </TableCell>
                      <TableCell align="right">
                        {table.row_count?.toLocaleString() || '0'}
                      </TableCell>
                      <TableCell align="right">
                        {table.size || 'N/A'}
                      </TableCell>
                    </TableRow>
                  ))}
                  {filteredTables.length === 0 && !isLoading && (
                    <TableRow>
                      <TableCell colSpan={4} align="center" sx={{ py: 4 }}>
                        <Typography variant="body2" sx={{ opacity: 0.7 }}>
                          {searchTerm ? 'No tables match your search' : 'No tables found'}
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

export default Tables;