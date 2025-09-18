import React, { useState, useEffect } from 'react';
import {
  Box,
  Grid,
  Card,
  CardContent,
  Typography,
  LinearProgress,
  Alert,
  Chip,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  IconButton,
  Tooltip,
  Switch,
  FormControlLabel,
} from '@mui/material';
import {
  Speed as PerformanceIcon,
  Storage as DatabaseIcon,
  Timeline as MetricsIcon,
  Refresh as RefreshIcon,
  Warning as WarningIcon,
  CheckCircle as HealthyIcon,
} from '@mui/icons-material';
import { useQuery } from '@tanstack/react-query';
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip as RechartsTooltip, ResponsiveContainer, AreaChart, Area } from 'recharts';
import { databaseApi } from '../services/api';
import { useDatabaseContext } from '../contexts/DatabaseContext';

interface HistoricalData {
  timestamp: string;
  connections: number;
  queries: number;
  cpu: number;
  memory: number;
}

const RealTimeMonitoring: React.FC = () => {
  const { currentEnvironment } = useDatabaseContext();
  const [isRealTime, setIsRealTime] = useState(true);
  const [historicalData, setHistoricalData] = useState<HistoricalData[]>([]);
  const refreshInterval = 5000;

  // Fetch current database metrics
  const { 
    data: metrics, 
    error, 
    refetch: refetchMetrics 
  } = useQuery({
    queryKey: ['database-metrics', currentEnvironment],
    queryFn: () => databaseApi.getMetrics(currentEnvironment),
    refetchInterval: isRealTime ? refreshInterval : false,
    refetchIntervalInBackground: true,
  });

  // Fetch slow queries
  const { data: slowQueries } = useQuery({
    queryKey: ['slow-queries', currentEnvironment],
    queryFn: () => databaseApi.executeQuery(currentEnvironment, `
      SELECT 
        query,
        calls,
        total_time,
        mean_time,
        rows
      FROM pg_stat_statements 
      ORDER BY mean_time DESC 
      LIMIT 10;
    `, true),
    refetchInterval: isRealTime ? 30000 : false,
    enabled: currentEnvironment !== 'prod', // Only enable for dev environment
  });

  // Update historical data
  useEffect(() => {
    if (metrics?.data && isRealTime) {
      const newDataPoint: HistoricalData = {
        timestamp: new Date().toLocaleTimeString(),
        connections: metrics.data.connections.active,
        queries: metrics.data.performance.tuplesReturned / 1000, // Approximate queries from tuples
        cpu: Math.random() * 100, // Mock CPU data
        memory: Math.random() * 100, // Mock memory data
      };

      setHistoricalData(prev => {
        const updated = [...prev, newDataPoint];
        return updated.slice(-20); // Keep only last 20 data points
      });
    }
  }, [metrics, isRealTime]);

  const getHealthStatus = () => {
    if (!metrics?.data) return { status: 'unknown', color: 'default' as const };
    
    const connectionUsage = (metrics.data.connections.total / metrics.data.connections.max) * 100;
    const hasSlowQueries = metrics.data.slowQueries.length > 3;
    const lowCacheHit = metrics.data.performance.cacheHitRatio < 90;

    if (connectionUsage > 80 || hasSlowQueries || lowCacheHit) {
      return { status: 'warning', color: 'warning' as const };
    }
    return { status: 'healthy', color: 'success' as const };
  };

  const healthStatus = getHealthStatus();

  if (error) {
    return (
      <Alert severity="error" sx={{ m: 2 }}>
        Failed to load database metrics: {error.message}
      </Alert>
    );
  }

  return (
    <Box sx={{ p: 3 }}>
      <Box display="flex" justifyContent="space-between" alignItems="center" mb={3}>
        <Typography variant="h4">
          Database Monitoring
        </Typography>
        <Box display="flex" alignItems="center" gap={2}>
          <FormControlLabel
            control={
              <Switch
                checked={isRealTime}
                onChange={(e) => setIsRealTime(e.target.checked)}
              />
            }
            label="Real-time"
          />
          <Chip
            icon={healthStatus.status === 'healthy' ? <HealthyIcon /> : <WarningIcon />}
            label={healthStatus.status.toUpperCase()}
            color={healthStatus.color}
          />
          <Tooltip title="Refresh">
            <IconButton onClick={() => refetchMetrics()}>
              <RefreshIcon />
            </IconButton>
          </Tooltip>
        </Box>
      </Box>

      <Grid container spacing={3}>
        {/* Connection Stats */}
        <Grid item xs={12} md={3}>
          <Card>
            <CardContent>
              <Box display="flex" alignItems="center" gap={1} mb={2}>
                <DatabaseIcon color="primary" />
                <Typography variant="h6">Connections</Typography>
              </Box>
              <Typography variant="h3" color="primary">
                {metrics?.data?.connections.active || 0}
              </Typography>
              <Typography variant="body2" color="text.secondary">
                Active connections
              </Typography>
              <LinearProgress
                variant="determinate"
                value={metrics?.data ? (metrics.data.connections.total / metrics.data.connections.max) * 100 : 0}
                sx={{ mt: 2 }}
              />
              <Typography variant="caption" display="block" sx={{ mt: 1 }}>
                {metrics?.data?.connections.total || 0} / {metrics?.data?.connections.max || 0} total
              </Typography>
            </CardContent>
          </Card>
        </Grid>

        {/* Performance Stats */}
        <Grid item xs={12} md={3}>
          <Card>
            <CardContent>
              <Box display="flex" alignItems="center" gap={1} mb={2}>
                <PerformanceIcon color="secondary" />
                <Typography variant="h6">Performance</Typography>
              </Box>
              <Typography variant="h3" color="secondary">
                {((metrics?.data?.performance.tuplesReturned || 0) / 1000).toFixed(1)}
              </Typography>
              <Typography variant="body2" color="text.secondary">
                Tuples/K returned
              </Typography>
              <Box mt={2}>
                <Typography variant="caption" display="block">
                  Cache Hit Ratio: {metrics?.data?.performance.cacheHitRatio.toFixed(1) || 0}%
                </Typography>
                <Typography variant="caption" display="block">
                  Commits: {metrics?.data?.performance.commits || 0}
                </Typography>
              </Box>
            </CardContent>
          </Card>
        </Grid>

        {/* Storage Stats */}
        <Grid item xs={12} md={3}>
          <Card>
            <CardContent>
              <Box display="flex" alignItems="center" gap={1} mb={2}>
                <DatabaseIcon color="info" />
                <Typography variant="h6">Storage</Typography>
              </Box>
              <Typography variant="h3" color="info">
                {metrics?.data?.storage.databaseSizeFormatted || '0 B'}
              </Typography>
              <Typography variant="body2" color="text.secondary">
                Database size
              </Typography>
              <Box mt={2}>
                <Typography variant="caption" display="block">
                  Largest Tables: {metrics?.data?.storage.largestTables.length || 0}
                </Typography>
                <Typography variant="caption" display="block">
                  Tablespaces: {metrics?.data?.storage.tablespaces.length || 0}
                </Typography>
              </Box>
            </CardContent>
          </Card>
        </Grid>

        {/* Activity Stats */}
        <Grid item xs={12} md={3}>
          <Card>
            <CardContent>
              <Box display="flex" alignItems="center" gap={1} mb={2}>
                <MetricsIcon color="warning" />
                <Typography variant="h6">Activity</Typography>
              </Box>
              <Typography variant="h3" color="warning">
                {metrics?.data?.performance.tuplesInserted || 0}
              </Typography>
              <Typography variant="body2" color="text.secondary">
                Inserts
              </Typography>
              <Box mt={2}>
                <Typography variant="caption" display="block">
                  Updates: {metrics?.data?.performance.tuplesUpdated || 0}
                </Typography>
                <Typography variant="caption" display="block">
                  Rollbacks: {metrics?.data?.performance.rollbacks || 0}
                </Typography>
              </Box>
            </CardContent>
          </Card>
        </Grid>

        {/* Historical Performance Chart */}
        <Grid item xs={12} md={8}>
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                Performance Trends
              </Typography>
              <Box height={300}>
                <ResponsiveContainer width="100%" height="100%">
                  <LineChart data={historicalData}>
                    <CartesianGrid strokeDasharray="3 3" />
                    <XAxis dataKey="timestamp" />
                    <YAxis />
                    <RechartsTooltip />
                    <Line type="monotone" dataKey="connections" stroke="#2563eb" name="Connections" />
                    <Line type="monotone" dataKey="queries" stroke="#10b981" name="Queries/sec" />
                  </LineChart>
                </ResponsiveContainer>
              </Box>
            </CardContent>
          </Card>
        </Grid>

        {/* Resource Usage */}
        <Grid item xs={12} md={4}>
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                Resource Usage
              </Typography>
              <Box height={300}>
                <ResponsiveContainer width="100%" height="100%">
                  <AreaChart data={historicalData}>
                    <CartesianGrid strokeDasharray="3 3" />
                    <XAxis dataKey="timestamp" />
                    <YAxis />
                    <RechartsTooltip />
                    <Area type="monotone" dataKey="cpu" stackId="1" stroke="#f59e0b" fill="#fbbf24" name="CPU %" />
                    <Area type="monotone" dataKey="memory" stackId="1" stroke="#ef4444" fill="#f87171" name="Memory %" />
                  </AreaChart>
                </ResponsiveContainer>
              </Box>
            </CardContent>
          </Card>
        </Grid>

        {/* Slow Queries */}
        {slowQueries?.data?.rows && slowQueries.data.rows.length > 0 && (
          <Grid item xs={12}>
            <Card>
              <CardContent>
                <Typography variant="h6" gutterBottom>
                  Slow Queries
                </Typography>
                <TableContainer>
                  <Table size="small">
                    <TableHead>
                      <TableRow>
                        <TableCell>Query</TableCell>
                        <TableCell align="right">Calls</TableCell>
                        <TableCell align="right">Avg Time (ms)</TableCell>
                        <TableCell align="right">Total Time (ms)</TableCell>
                      </TableRow>
                    </TableHead>
                    <TableBody>
                      {slowQueries.data.rows.slice(0, 5).map((query: any, index: number) => (
                        <TableRow key={index}>
                          <TableCell>
                            <Typography variant="body2" noWrap sx={{ maxWidth: 400 }}>
                              {query.query.substring(0, 100)}...
                            </Typography>
                          </TableCell>
                          <TableCell align="right">{query.calls}</TableCell>
                          <TableCell align="right">{Number(query.mean_time).toFixed(2)}</TableCell>
                          <TableCell align="right">{Number(query.total_time).toFixed(2)}</TableCell>
                        </TableRow>
                      ))}
                    </TableBody>
                  </Table>
                </TableContainer>
              </CardContent>
            </Card>
          </Grid>
        )}
      </Grid>
    </Box>
  );
};

export default RealTimeMonitoring;