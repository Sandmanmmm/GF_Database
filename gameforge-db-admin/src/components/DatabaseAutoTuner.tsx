import React, { useState, useEffect } from 'react';
import {
  Box,
  Card,
  CardContent,
  Typography,
  Grid,
  Button,
  Alert,
  LinearProgress,
  Chip,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Paper,
  Switch,
  FormControlLabel,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  List,
  ListItem,
  ListItemText,
  ListItemIcon,
  IconButton,
  Tooltip,
} from '@mui/material';
import {
  Speed as PerformanceIcon,
  TrendingUp as OptimizeIcon,
  Assessment as AnalyticsIcon,
  AutoFixHigh as AutoTuneIcon,
  Schedule as ScheduleIcon,
  PlayArrow as ExecuteIcon,
  Pause as PauseIcon,
  Settings as ConfigIcon,
  Warning as WarningIcon,
  CheckCircle as SuccessIcon,
  Info as InfoIcon,
} from '@mui/icons-material';
import { useQuery, useMutation } from '@tanstack/react-query';
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, AreaChart, Area } from 'recharts';
import { databaseApi } from '../services/api';
import { useDatabaseContext } from '../contexts/DatabaseContext';

interface PerformanceMetric {
  name: string;
  current: number;
  optimal: number;
  unit: string;
  status: 'good' | 'warning' | 'critical';
  recommendation?: string;
}

interface AutoTuningTask {
  id: string;
  name: string;
  description: string;
  category: 'index' | 'query' | 'memory' | 'vacuum' | 'analyze';
  priority: 'low' | 'medium' | 'high' | 'critical';
  estimatedImpact: string;
  estimatedTime: string;
  status: 'pending' | 'running' | 'completed' | 'failed';
  progress?: number;
  sql?: string;
  scheduledFor?: string;
}

interface QueryPlan {
  query: string;
  executionTime: number;
  cost: number;
  improvement: string;
  newPlan: string;
}

const DatabaseAutoTuner: React.FC = () => {
  const { currentEnvironment } = useDatabaseContext();
  const [autoTuningEnabled, setAutoTuningEnabled] = useState(false);
  const [selectedTask, setSelectedTask] = useState<AutoTuningTask | null>(null);
  const [tuningHistory, setTuningHistory] = useState<any[]>([]);

  const { data: performanceMetrics } = useQuery({
    queryKey: ['performance-metrics', currentEnvironment],
    queryFn: () => databaseApi.getPerformanceMetrics(currentEnvironment),
    refetchInterval: 30000,
  });

  const { data: autoTuningTasks, refetch: refetchTasks } = useQuery({
    queryKey: ['auto-tuning-tasks', currentEnvironment],
    queryFn: () => getMockAutoTuningTasks(),
    refetchInterval: autoTuningEnabled ? 5000 : false,
  });

  // Mock data generator
  const getMockAutoTuningTasks = (): AutoTuningTask[] => [
    {
      id: '1',
      name: 'Create Missing Index',
      description: 'Create composite index on users(email, status) for faster authentication',
      category: 'index',
      priority: 'high',
      estimatedImpact: '45% query time reduction',
      estimatedTime: '2 minutes',
      status: 'pending',
      sql: 'CREATE INDEX CONCURRENTLY idx_users_email_status ON users(email, status);'
    },
    {
      id: '2',
      name: 'Optimize Query Plan',
      description: 'Rewrite subquery in game_scores aggregation for better performance',
      category: 'query',
      priority: 'medium',
      estimatedImpact: '30% faster aggregations',
      estimatedTime: '1 minute',
      status: 'pending',
      sql: 'ALTER TABLE game_scores ADD INDEX idx_user_created (user_id, created_at);'
    },
    {
      id: '3',
      name: 'Auto VACUUM Analysis',
      description: 'Update table statistics for better query planning',
      category: 'analyze',
      priority: 'medium',
      estimatedImpact: '20% better query plans',
      estimatedTime: '5 minutes',
      status: 'running',
      progress: 65
    }
  ];

  const getMockPerformanceMetrics = (): PerformanceMetric[] => [
    {
      name: 'Query Response Time',
      current: 250,
      optimal: 100,
      unit: 'ms',
      status: 'warning',
      recommendation: 'Add indexes to frequently queried columns'
    },
    {
      name: 'Index Usage Ratio',
      current: 78,
      optimal: 95,
      unit: '%',
      status: 'warning',
      recommendation: 'Review and optimize existing indexes'
    },
    {
      name: 'Buffer Hit Ratio',
      current: 94,
      optimal: 99,
      unit: '%',
      status: 'good'
    },
    {
      name: 'Connection Pool Usage',
      current: 65,
      optimal: 80,
      unit: '%',
      status: 'good'
    }
  ];

  const executeTaskMutation = useMutation({
    mutationFn: async (task: AutoTuningTask) => {
      // Mock execution
      await new Promise(resolve => setTimeout(resolve, 2000));
      return { success: true, message: 'Task executed successfully' };
    },
    onSuccess: () => {
      refetchTasks();
    }
  });

  const startAutoTuningMutation = useMutation({
    mutationFn: async () => {
      setAutoTuningEnabled(true);
      // Mock auto-tuning start
      await new Promise(resolve => setTimeout(resolve, 1000));
      return { success: true };
    }
  });

  const getStatusIcon = (status: string) => {
    switch (status) {
      case 'completed': return <SuccessIcon color="success" />;
      case 'running': return <AutoTuneIcon color="primary" />;
      case 'failed': return <WarningIcon color="error" />;
      default: return <InfoIcon color="info" />;
    }
  };

  const getPriorityColor = (priority: string) => {
    switch (priority) {
      case 'critical': return 'error';
      case 'high': return 'warning';
      case 'medium': return 'info';
      case 'low': return 'success';
      default: return 'default';
    }
  };

  const getMetricStatus = (metric: PerformanceMetric) => {
    const percentage = (metric.current / metric.optimal) * 100;
    if (percentage >= 90) return 'success';
    if (percentage >= 70) return 'warning';
    return 'error';
  };

  // Mock performance history data
  const performanceHistory = [
    { time: '00:00', queryTime: 300, indexHit: 75, bufferHit: 92 },
    { time: '04:00', queryTime: 280, indexHit: 78, bufferHit: 93 },
    { time: '08:00', queryTime: 320, indexHit: 76, bufferHit: 91 },
    { time: '12:00', queryTime: 250, indexHit: 82, bufferHit: 94 },
    { time: '16:00', queryTime: 240, indexHit: 85, bufferHit: 95 },
    { time: '20:00', queryTime: 220, indexHit: 88, bufferHit: 96 },
  ];

  return (
    <Box>
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 3 }}>
        <Typography variant="h4" sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
          <AutoTuneIcon color="primary" />
          Database Auto-Tuner
        </Typography>
        
        <Box sx={{ display: 'flex', gap: 2, alignItems: 'center' }}>
          <FormControlLabel
            control={
              <Switch
                checked={autoTuningEnabled}
                onChange={(e) => setAutoTuningEnabled(e.target.checked)}
              />
            }
            label="Auto-Tuning"
          />
          {!autoTuningEnabled && (
            <Button
              variant="contained"
              startIcon={<AutoTuneIcon />}
              onClick={() => startAutoTuningMutation.mutate()}
              disabled={startAutoTuningMutation.isPending}
            >
              Start Auto-Tuning
            </Button>
          )}
        </Box>
      </Box>

      <Grid container spacing={3}>
        {/* Performance Metrics */}
        <Grid item xs={12} lg={8}>
          <Card>
            <CardContent>
              <Typography variant="h6" sx={{ mb: 2 }}>
                Real-time Performance Metrics
              </Typography>
              
              <Grid container spacing={2}>
                {getMockPerformanceMetrics().map((metric) => (
                  <Grid item xs={12} md={6} key={metric.name}>
                    <Card variant="outlined">
                      <CardContent sx={{ pb: 2 }}>
                        <Typography variant="subtitle2" sx={{ mb: 1 }}>
                          {metric.name}
                        </Typography>
                        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mb: 1 }}>
                          <Typography variant="h6">
                            {metric.current}{metric.unit}
                          </Typography>
                          <Chip
                            size="small"
                            label={metric.status}
                            color={getMetricStatus(metric) as any}
                          />
                        </Box>
                        <Typography variant="caption" sx={{ opacity: 0.7 }}>
                          Target: {metric.optimal}{metric.unit}
                        </Typography>
                        <LinearProgress
                          variant="determinate"
                          value={(metric.current / metric.optimal) * 100}
                          color={getMetricStatus(metric) as any}
                          sx={{ mt: 1 }}
                        />
                        {metric.recommendation && (
                          <Typography variant="caption" sx={{ display: 'block', mt: 1, color: 'warning.main' }}>
                            💡 {metric.recommendation}
                          </Typography>
                        )}
                      </CardContent>
                    </Card>
                  </Grid>
                ))}
              </Grid>
            </CardContent>
          </Card>
        </Grid>

        {/* Auto-Tuning Status */}
        <Grid item xs={12} lg={4}>
          <Card>
            <CardContent>
              <Typography variant="h6" sx={{ mb: 2 }}>
                Auto-Tuning Status
              </Typography>
              
              {autoTuningEnabled ? (
                <Alert severity="success" sx={{ mb: 2 }}>
                  Auto-tuning is active and monitoring your database performance.
                </Alert>
              ) : (
                <Alert severity="info" sx={{ mb: 2 }}>
                  Auto-tuning is disabled. Enable it to automatically optimize your database.
                </Alert>
              )}

              <Box sx={{ mb: 2 }}>
                <Typography variant="subtitle2" sx={{ mb: 1 }}>
                  Optimization Summary
                </Typography>
                <Typography variant="body2" sx={{ mb: 1 }}>
                  📈 3 optimizations pending
                </Typography>
                <Typography variant="body2" sx={{ mb: 1 }}>
                  ⚡ 45% average performance improvement
                </Typography>
                <Typography variant="body2">
                  🕒 Last optimization: 2 hours ago
                </Typography>
              </Box>

              <Button
                variant="outlined"
                startIcon={<ScheduleIcon />}
                fullWidth
                sx={{ mb: 1 }}
              >
                Schedule Maintenance
              </Button>
              <Button
                variant="outlined"
                startIcon={<ConfigIcon />}
                fullWidth
              >
                Tuning Settings
              </Button>
            </CardContent>
          </Card>
        </Grid>

        {/* Performance Trends */}
        <Grid item xs={12}>
          <Card>
            <CardContent>
              <Typography variant="h6" sx={{ mb: 2 }}>
                Performance Trends (24 Hours)
              </Typography>
              <Box sx={{ height: 300 }}>
                <ResponsiveContainer width="100%" height="100%">
                  <LineChart data={performanceHistory}>
                    <CartesianGrid strokeDasharray="3 3" />
                    <XAxis dataKey="time" />
                    <YAxis />
                    <Tooltip />
                    <Line type="monotone" dataKey="queryTime" stroke="#2563eb" name="Query Time (ms)" />
                    <Line type="monotone" dataKey="indexHit" stroke="#16a34a" name="Index Hit Rate (%)" />
                    <Line type="monotone" dataKey="bufferHit" stroke="#dc2626" name="Buffer Hit Rate (%)" />
                  </LineChart>
                </ResponsiveContainer>
              </Box>
            </CardContent>
          </Card>
        </Grid>

        {/* Auto-Tuning Tasks */}
        <Grid item xs={12}>
          <Card>
            <CardContent>
              <Typography variant="h6" sx={{ mb: 2 }}>
                Auto-Tuning Tasks
              </Typography>
              
              <TableContainer>
                <Table>
                  <TableHead>
                    <TableRow>
                      <TableCell>Status</TableCell>
                      <TableCell>Task</TableCell>
                      <TableCell>Category</TableCell>
                      <TableCell>Priority</TableCell>
                      <TableCell>Impact</TableCell>
                      <TableCell>ETA</TableCell>
                      <TableCell>Actions</TableCell>
                    </TableRow>
                  </TableHead>
                  <TableBody>
                    {autoTuningTasks?.map((task) => (
                      <TableRow key={task.id}>
                        <TableCell>
                          <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                            {getStatusIcon(task.status)}
                            {task.status === 'running' && task.progress && (
                              <Box sx={{ width: 60 }}>
                                <LinearProgress variant="determinate" value={task.progress} />
                              </Box>
                            )}
                          </Box>
                        </TableCell>
                        <TableCell>
                          <Typography variant="subtitle2">{task.name}</Typography>
                          <Typography variant="caption" sx={{ opacity: 0.7 }}>
                            {task.description}
                          </Typography>
                        </TableCell>
                        <TableCell>
                          <Chip size="small" label={task.category} />
                        </TableCell>
                        <TableCell>
                          <Chip 
                            size="small" 
                            label={task.priority} 
                            color={getPriorityColor(task.priority) as any}
                          />
                        </TableCell>
                        <TableCell>{task.estimatedImpact}</TableCell>
                        <TableCell>{task.estimatedTime}</TableCell>
                        <TableCell>
                          <Tooltip title="Execute Task">
                            <IconButton
                              size="small"
                              onClick={() => setSelectedTask(task)}
                              disabled={task.status === 'running' || task.status === 'completed'}
                            >
                              <ExecuteIcon />
                            </IconButton>
                          </Tooltip>
                        </TableCell>
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
              </TableContainer>
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      {/* Execute Task Dialog */}
      <Dialog open={!!selectedTask} onClose={() => setSelectedTask(null)}>
        <DialogTitle>Execute Auto-Tuning Task</DialogTitle>
        <DialogContent>
          {selectedTask && (
            <Box>
              <Typography variant="h6" sx={{ mb: 1 }}>
                {selectedTask.name}
              </Typography>
              <Typography variant="body2" sx={{ mb: 2 }}>
                {selectedTask.description}
              </Typography>
              
              <Alert severity="info" sx={{ mb: 2 }}>
                <Typography variant="body2">
                  <strong>Estimated Impact:</strong> {selectedTask.estimatedImpact}<br />
                  <strong>Estimated Time:</strong> {selectedTask.estimatedTime}
                </Typography>
              </Alert>

              {selectedTask.sql && (
                <Box sx={{ bgcolor: 'background.paper', p: 2, borderRadius: 1, mb: 2 }}>
                  <Typography variant="caption" sx={{ opacity: 0.8 }}>SQL to be executed:</Typography>
                  <Typography variant="body2" component="pre" sx={{ fontFamily: 'monospace', mt: 1 }}>
                    {selectedTask.sql}
                  </Typography>
                </Box>
              )}
            </Box>
          )}
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setSelectedTask(null)}>Cancel</Button>
          <Button 
            variant="contained" 
            onClick={() => {
              if (selectedTask) {
                executeTaskMutation.mutate(selectedTask);
                setSelectedTask(null);
              }
            }}
            disabled={executeTaskMutation.isPending}
          >
            Execute
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
};

export default DatabaseAutoTuner;