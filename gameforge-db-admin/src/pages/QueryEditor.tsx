import React, { useState } from 'react';
import {
  Box,
  Typography,
  Card,
  CardContent,
  TextField,
  Button,
  Alert,
  CircularProgress,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Paper,
  Grid,
  FormControlLabel,
  Switch,
  Chip,
} from '@mui/material';
import {
  PlayArrow as ExecuteIcon,
  Clear as ClearIcon,
  Code as QueryIcon,
  Timer as TimerIcon,
} from '@mui/icons-material';
import { useMutation } from '@tanstack/react-query';

import { databaseApi } from '../services/api';
import { useDatabaseContext } from '../contexts/DatabaseContext';

const QueryEditor: React.FC = () => {
  const { currentEnvironment } = useDatabaseContext();
  const [query, setQuery] = useState('SELECT * FROM information_schema.tables LIMIT 10;');
  const [readonly, setReadonly] = useState(true);
  const [results, setResults] = useState<any>(null);
  const [error, setError] = useState<string | null>(null);

  const executeQueryMutation = useMutation({
    mutationFn: (queryData: { query: string; readonly: boolean }) =>
      databaseApi.executeQuery(currentEnvironment, queryData.query, queryData.readonly),
    onSuccess: (data) => {
      setResults(data.data);
      setError(null);
    },
    onError: (error: any) => {
      setError(error.response?.data?.error || error.message);
      setResults(null);
    },
  });

  const handleExecuteQuery = () => {
    if (!query.trim()) {
      setError('Please enter a query');
      return;
    }
    executeQueryMutation.mutate({ query: query.trim(), readonly });
  };

  const handleClearQuery = () => {
    setQuery('');
    setResults(null);
    setError(null);
  };

  const sampleQueries = [
    'SELECT * FROM information_schema.tables LIMIT 10;',
    'SELECT table_name, table_type FROM information_schema.tables WHERE table_schema = \'public\';',
    'SELECT usename, usecreatedb, usesuper FROM pg_user;',
    'SELECT version();',
    'SELECT current_database(), current_user, now();',
  ];

  return (
    <Box>
      <Box sx={{ mb: 4 }}>
        <Typography variant="h4" sx={{ fontWeight: 600, mb: 1 }}>
          SQL Query Editor
        </Typography>
        <Typography variant="body1" sx={{ opacity: 0.8 }}>
          Execute SQL queries against the {currentEnvironment === 'dev' ? 'Development' : 'Production'} database
        </Typography>
      </Box>

      {/* Query Input */}
      <Card sx={{ mb: 3 }}>
        <CardContent>
          <Box sx={{ display: 'flex', alignItems: 'center', mb: 2 }}>
            <QueryIcon sx={{ mr: 1 }} />
            <Typography variant="h6">Query</Typography>
          </Box>

          <TextField
            fullWidth
            multiline
            rows={8}
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            placeholder="Enter your SQL query here..."
            variant="outlined"
            sx={{
              mb: 2,
              '& .MuiInputBase-input': {
                fontFamily: 'monospace',
                fontSize: '14px',
              },
            }}
          />

          <Grid container spacing={2} alignItems="center">
            <Grid item>
              <FormControlLabel
                control={
                  <Switch
                    checked={readonly}
                    onChange={(e) => setReadonly(e.target.checked)}
                    color="primary"
                  />
                }
                label="Read-only mode"
              />
            </Grid>
            <Grid item>
              <Button
                variant="contained"
                startIcon={<ExecuteIcon />}
                onClick={handleExecuteQuery}
                disabled={executeQueryMutation.isPending}
              >
                {executeQueryMutation.isPending ? 'Executing...' : 'Execute Query'}
              </Button>
            </Grid>
            <Grid item>
              <Button
                variant="outlined"
                startIcon={<ClearIcon />}
                onClick={handleClearQuery}
              >
                Clear
              </Button>
            </Grid>
          </Grid>

          {readonly && (
            <Alert severity="info" sx={{ mt: 2 }}>
              Read-only mode is enabled. Only SELECT queries are allowed for safety.
            </Alert>
          )}
        </CardContent>
      </Card>

      {/* Sample Queries */}
      <Card sx={{ mb: 3 }}>
        <CardContent>
          <Typography variant="h6" sx={{ mb: 2 }}>
            Sample Queries
          </Typography>
          <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 1 }}>
            {sampleQueries.map((sampleQuery, index) => (
              <Chip
                key={index}
                label={sampleQuery.substring(0, 50) + (sampleQuery.length > 50 ? '...' : '')}
                variant="outlined"
                onClick={() => setQuery(sampleQuery)}
                sx={{ cursor: 'pointer' }}
              />
            ))}
          </Box>
        </CardContent>
      </Card>

      {/* Loading */}
      {executeQueryMutation.isPending && (
        <Card sx={{ mb: 3 }}>
          <CardContent sx={{ display: 'flex', justifyContent: 'center', py: 4 }}>
            <CircularProgress />
          </CardContent>
        </Card>
      )}

      {/* Error */}
      {error && (
        <Card sx={{ mb: 3 }}>
          <CardContent>
            <Alert severity="error">
              <Typography variant="body2" sx={{ fontFamily: 'monospace' }}>
                {error}
              </Typography>
            </Alert>
          </CardContent>
        </Card>
      )}

      {/* Results */}
      {results && (
        <Card>
          <CardContent>
            <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', mb: 2 }}>
              <Typography variant="h6">Query Results</Typography>
              <Box sx={{ display: 'flex', gap: 2 }}>
                <Chip
                  icon={<TimerIcon fontSize="small" />}
                  label={`${results.executionTime}ms`}
                  size="small"
                  variant="outlined"
                />
                <Chip
                  label={`${results.rowCount} rows`}
                  size="small"
                  color="primary"
                />
              </Box>
            </Box>

            {results.rows.length > 0 ? (
              <TableContainer component={Paper} variant="outlined" sx={{ maxHeight: 400 }}>
                <Table stickyHeader>
                  <TableHead>
                    <TableRow>
                      {Object.keys(results.rows[0]).map((column) => (
                        <TableCell key={column} sx={{ fontWeight: 600 }}>
                          {column}
                        </TableCell>
                      ))}
                    </TableRow>
                  </TableHead>
                  <TableBody>
                    {results.rows.map((row: any, index: number) => (
                      <TableRow key={index}>
                        {Object.values(row).map((value: any, cellIndex: number) => (
                          <TableCell key={cellIndex}>
                            <Typography
                              variant="body2"
                              sx={{
                                fontFamily: typeof value === 'string' && value.length > 50 ? 'monospace' : 'inherit',
                                maxWidth: 200,
                                overflow: 'hidden',
                                textOverflow: 'ellipsis',
                                whiteSpace: 'nowrap',
                              }}
                              title={String(value)}
                            >
                              {value === null ? (
                                <em style={{ opacity: 0.6 }}>NULL</em>
                              ) : (
                                String(value)
                              )}
                            </Typography>
                          </TableCell>
                        ))}
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
              </TableContainer>
            ) : (
              <Alert severity="info">
                Query executed successfully but returned no rows.
              </Alert>
            )}
          </CardContent>
        </Card>
      )}
    </Box>
  );
};

export default QueryEditor;