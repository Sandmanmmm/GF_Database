import React, { useState } from 'react';
import {
  Box,
  Card,
  CardContent,
  Typography,
  Grid,
  Button,
  Stepper,
  Step,
  StepLabel,
  StepContent,
  TextField,
  Select,
  MenuItem,
  FormControl,
  InputLabel,
  Alert,
  LinearProgress,
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
  IconButton,
  Tooltip,
  List,
  ListItem,
  ListItemText,
  ListItemIcon,
} from '@mui/material';
import {
  CloudUpload as ImportIcon,
  Transform as TransformIcon,
  Storage as DatabaseIcon,
  PlayArrow as ExecuteIcon,
  Visibility as PreviewIcon,
  Edit as EditIcon,
  Delete as DeleteIcon,
  Add as AddIcon,
  Schedule as ScheduleIcon,
  History as HistoryIcon,
  CheckCircle as SuccessIcon,
  Error as ErrorIcon,
  Warning as WarningIcon,
} from '@mui/icons-material';
import { useMutation, useQuery } from '@tanstack/react-query';
import { databaseApi } from '../services/api';
import { useDatabaseContext } from '../contexts/DatabaseContext';

interface DataSource {
  id: string;
  name: string;
  type: 'csv' | 'json' | 'xml' | 'api' | 'database' | 'excel';
  connection: string;
  status: 'connected' | 'disconnected' | 'error';
  lastSync?: string;
  recordCount?: number;
}

interface TransformationRule {
  id: string;
  field: string;
  operation: 'rename' | 'convert' | 'filter' | 'aggregate' | 'join' | 'calculate';
  parameters: Record<string, any>;
  description: string;
}

interface MigrationPipeline {
  id: string;
  name: string;
  description: string;
  source: DataSource;
  target: {
    table: string;
    environment: 'dev' | 'prod';
  };
  transformations: TransformationRule[];
  schedule?: {
    frequency: 'once' | 'hourly' | 'daily' | 'weekly';
    time?: string;
  };
  status: 'draft' | 'active' | 'paused' | 'completed' | 'failed';
  lastRun?: {
    timestamp: string;
    recordsProcessed: number;
    success: boolean;
    errors?: string[];
  };
}

const SmartDataMigration: React.FC = () => {
  const { currentEnvironment } = useDatabaseContext();
  const [activeStep, setActiveStep] = useState(0);
  const [selectedPipeline, setSelectedPipeline] = useState<MigrationPipeline | null>(null);
  const [previewDialogOpen, setPreviewDialogOpen] = useState(false);
  const [previewData, setPreviewData] = useState<any[]>([]);

  // Pipeline creation states
  const [pipelineName, setPipelineName] = useState('');
  const [pipelineDescription, setPipelineDescription] = useState('');
  const [selectedSource, setSelectedSource] = useState<DataSource | null>(null);
  const [targetTable, setTargetTable] = useState('');
  const [transformations, setTransformations] = useState<TransformationRule[]>([]);
  const [scheduleConfig, setScheduleConfig] = useState({
    frequency: 'once' as const,
    time: ''
  });

  // Mock data
  const mockDataSources: DataSource[] = [
    {
      id: '1',
      name: 'Legacy User Data CSV',
      type: 'csv',
      connection: '/uploads/legacy_users.csv',
      status: 'connected',
      lastSync: '2025-09-18T10:30:00Z',
      recordCount: 15000
    },
    {
      id: '2',
      name: 'Game Analytics API',
      type: 'api',
      connection: 'https://analytics.gameforge.com/api/v1/events',
      status: 'connected',
      recordCount: 250000
    },
    {
      id: '3',
      name: 'External Payment System',
      type: 'database',
      connection: 'postgresql://payments.external.com:5432/payments',
      status: 'connected',
      recordCount: 50000
    }
  ];

  const mockPipelines: MigrationPipeline[] = [
    {
      id: '1',
      name: 'Legacy User Migration',
      description: 'Migrate user data from legacy CSV files to users table',
      source: mockDataSources[0],
      target: { table: 'users', environment: 'dev' },
      transformations: [
        {
          id: '1',
          field: 'email',
          operation: 'convert',
          parameters: { to: 'lowercase' },
          description: 'Convert email to lowercase'
        },
        {
          id: '2',
          field: 'created_date',
          operation: 'convert',
          parameters: { from: 'MM/DD/YYYY', to: 'YYYY-MM-DD' },
          description: 'Convert date format'
        }
      ],
      schedule: { frequency: 'once' },
      status: 'active',
      lastRun: {
        timestamp: '2025-09-18T10:30:00Z',
        recordsProcessed: 14850,
        success: true
      }
    }
  ];

  const { data: tables } = useQuery({
    queryKey: ['tables', currentEnvironment],
    queryFn: () => databaseApi.getTables(currentEnvironment),
  });

  const executePipelineMutation = useMutation({
    mutationFn: async (pipeline: MigrationPipeline) => {
      // Mock pipeline execution
      await new Promise(resolve => setTimeout(resolve, 3000));
      return { 
        success: true, 
        recordsProcessed: pipeline.source.recordCount || 0,
        duration: '2.5 minutes'
      };
    }
  });

  const previewDataMutation = useMutation({
    mutationFn: async (source: DataSource) => {
      // Mock data preview
      await new Promise(resolve => setTimeout(resolve, 1000));
      return [
        { id: 1, email: 'USER@EXAMPLE.COM', name: 'John Doe', created_date: '01/15/2023' },
        { id: 2, email: 'JANE@EXAMPLE.COM', name: 'Jane Smith', created_date: '02/20/2023' },
        { id: 3, email: 'BOB@EXAMPLE.COM', name: 'Bob Johnson', created_date: '03/10/2023' }
      ];
    },
    onSuccess: (data) => {
      setPreviewData(data);
      setPreviewDialogOpen(true);
    }
  });

  const getStatusIcon = (status: string) => {
    switch (status) {
      case 'completed':
      case 'connected':
        return <SuccessIcon color="success" />;
      case 'failed':
      case 'error':
        return <ErrorIcon color="error" />;
      case 'active':
      case 'paused':
        return <WarningIcon color="warning" />;
      default:
        return <SuccessIcon color="info" />;
    }
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'completed':
      case 'connected':
        return 'success';
      case 'failed':
      case 'error':
        return 'error';
      case 'active':
        return 'primary';
      case 'paused':
        return 'warning';
      default:
        return 'default';
    }
  };

  const addTransformation = () => {
    const newTransformation: TransformationRule = {
      id: Date.now().toString(),
      field: '',
      operation: 'rename',
      parameters: {},
      description: ''
    };
    setTransformations([...transformations, newTransformation]);
  };

  const removeTransformation = (id: string) => {
    setTransformations(transformations.filter(t => t.id !== id));
  };

  const steps = [
    'Select Data Source',
    'Configure Transformations', 
    'Set Target & Schedule',
    'Review & Execute'
  ];

  return (
    <Box>
      <Typography variant="h4" sx={{ mb: 3, display: 'flex', alignItems: 'center', gap: 1 }}>
        <TransformIcon color="primary" />
        Smart Data Migration & ETL
      </Typography>

      <Grid container spacing={3}>
        {/* Data Sources */}
        <Grid item xs={12} lg={4}>
          <Card>
            <CardContent>
              <Typography variant="h6" sx={{ mb: 2, display: 'flex', alignItems: 'center', gap: 1 }}>
                <DatabaseIcon />
                Data Sources
              </Typography>
              
              <List dense>
                {mockDataSources.map((source) => (
                  <ListItem key={source.id} divider>
                    <ListItemIcon>
                      {getStatusIcon(source.status)}
                    </ListItemIcon>
                    <ListItemText
                      primary={source.name}
                      secondary={
                        <Box>
                          <Typography variant="caption" display="block">
                            Type: {source.type.toUpperCase()}
                          </Typography>
                          <Typography variant="caption" display="block">
                            Records: {source.recordCount?.toLocaleString()}
                          </Typography>
                          {source.lastSync && (
                            <Typography variant="caption" display="block">
                              Last sync: {new Date(source.lastSync).toLocaleString()}
                            </Typography>
                          )}
                        </Box>
                      }
                    />
                    <Tooltip title="Preview Data">
                      <IconButton 
                        size="small"
                        onClick={() => previewDataMutation.mutate(source)}
                        disabled={previewDataMutation.isPending}
                      >
                        <PreviewIcon />
                      </IconButton>
                    </Tooltip>
                  </ListItem>
                ))}
              </List>
              
              <Button
                variant="outlined"
                startIcon={<AddIcon />}
                fullWidth
                sx={{ mt: 2 }}
              >
                Add Data Source
              </Button>
            </CardContent>
          </Card>
        </Grid>

        {/* Pipeline Creation */}
        <Grid item xs={12} lg={8}>
          <Card>
            <CardContent>
              <Typography variant="h6" sx={{ mb: 2 }}>
                Create Migration Pipeline
              </Typography>
              
              <Stepper activeStep={activeStep} orientation="vertical">
                {steps.map((label, index) => (
                  <Step key={label}>
                    <StepLabel>{label}</StepLabel>
                    <StepContent>
                      {index === 0 && (
                        <Box sx={{ mb: 2 }}>
                          <FormControl fullWidth sx={{ mb: 2 }}>
                            <InputLabel>Select Data Source</InputLabel>
                            <Select
                              value={selectedSource?.id || ''}
                              onChange={(e) => {
                                const source = mockDataSources.find(s => s.id === e.target.value);
                                setSelectedSource(source || null);
                              }}
                            >
                              {mockDataSources.map((source) => (
                                <MenuItem key={source.id} value={source.id}>
                                  {source.name} ({source.type})
                                </MenuItem>
                              ))}
                            </Select>
                          </FormControl>
                          
                          {selectedSource && (
                            <Alert severity="info">
                              Selected: {selectedSource.name} with {selectedSource.recordCount?.toLocaleString()} records
                            </Alert>
                          )}
                        </Box>
                      )}

                      {index === 1 && (
                        <Box sx={{ mb: 2 }}>
                          <Typography variant="subtitle2" sx={{ mb: 2 }}>
                            Data Transformations
                          </Typography>
                          
                          {transformations.map((transformation, idx) => (
                            <Card key={transformation.id} variant="outlined" sx={{ mb: 2 }}>
                              <CardContent sx={{ pb: 2 }}>
                                <Grid container spacing={2} alignItems="center">
                                  <Grid item xs={3}>
                                    <TextField
                                      size="small"
                                      label="Field"
                                      value={transformation.field}
                                      onChange={(e) => {
                                        const newTransformations = [...transformations];
                                        newTransformations[idx].field = e.target.value;
                                        setTransformations(newTransformations);
                                      }}
                                      fullWidth
                                    />
                                  </Grid>
                                  <Grid item xs={3}>
                                    <FormControl size="small" fullWidth>
                                      <InputLabel>Operation</InputLabel>
                                      <Select
                                        value={transformation.operation}
                                        onChange={(e) => {
                                          const newTransformations = [...transformations];
                                          newTransformations[idx].operation = e.target.value as any;
                                          setTransformations(newTransformations);
                                        }}
                                      >
                                        <MenuItem value="rename">Rename</MenuItem>
                                        <MenuItem value="convert">Convert</MenuItem>
                                        <MenuItem value="filter">Filter</MenuItem>
                                        <MenuItem value="aggregate">Aggregate</MenuItem>
                                        <MenuItem value="join">Join</MenuItem>
                                        <MenuItem value="calculate">Calculate</MenuItem>
                                      </Select>
                                    </FormControl>
                                  </Grid>
                                  <Grid item xs={4}>
                                    <TextField
                                      size="small"
                                      label="Description"
                                      value={transformation.description}
                                      onChange={(e) => {
                                        const newTransformations = [...transformations];
                                        newTransformations[idx].description = e.target.value;
                                        setTransformations(newTransformations);
                                      }}
                                      fullWidth
                                    />
                                  </Grid>
                                  <Grid item xs={2}>
                                    <IconButton
                                      size="small"
                                      onClick={() => removeTransformation(transformation.id)}
                                      color="error"
                                    >
                                      <DeleteIcon />
                                    </IconButton>
                                  </Grid>
                                </Grid>
                              </CardContent>
                            </Card>
                          ))}
                          
                          <Button
                            variant="outlined"
                            startIcon={<AddIcon />}
                            onClick={addTransformation}
                            size="small"
                          >
                            Add Transformation
                          </Button>
                        </Box>
                      )}

                      {index === 2 && (
                        <Box sx={{ mb: 2 }}>
                          <Grid container spacing={2}>
                            <Grid item xs={6}>
                              <TextField
                                fullWidth
                                label="Pipeline Name"
                                value={pipelineName}
                                onChange={(e) => setPipelineName(e.target.value)}
                                sx={{ mb: 2 }}
                              />
                              <FormControl fullWidth sx={{ mb: 2 }}>
                                <InputLabel>Target Table</InputLabel>
                                <Select
                                  value={targetTable}
                                  onChange={(e) => setTargetTable(e.target.value)}
                                >
                                  {tables?.data?.map((table) => (
                                    <MenuItem key={table.table_name} value={table.table_name}>
                                      {table.table_name}
                                    </MenuItem>
                                  ))}
                                </Select>
                              </FormControl>
                            </Grid>
                            <Grid item xs={6}>
                              <TextField
                                fullWidth
                                label="Description"
                                multiline
                                rows={3}
                                value={pipelineDescription}
                                onChange={(e) => setPipelineDescription(e.target.value)}
                                sx={{ mb: 2 }}
                              />
                              <FormControl fullWidth>
                                <InputLabel>Schedule</InputLabel>
                                <Select
                                  value={scheduleConfig.frequency}
                                  onChange={(e) => setScheduleConfig({
                                    ...scheduleConfig,
                                    frequency: e.target.value as any
                                  })}
                                >
                                  <MenuItem value="once">Run Once</MenuItem>
                                  <MenuItem value="hourly">Hourly</MenuItem>
                                  <MenuItem value="daily">Daily</MenuItem>
                                  <MenuItem value="weekly">Weekly</MenuItem>
                                </Select>
                              </FormControl>
                            </Grid>
                          </Grid>
                        </Box>
                      )}

                      {index === 3 && (
                        <Box sx={{ mb: 2 }}>
                          <Alert severity="info" sx={{ mb: 2 }}>
                            Ready to create pipeline: {pipelineName}
                          </Alert>
                          <Typography variant="body2" sx={{ mb: 1 }}>
                            Source: {selectedSource?.name}
                          </Typography>
                          <Typography variant="body2" sx={{ mb: 1 }}>
                            Target: {targetTable} ({currentEnvironment})
                          </Typography>
                          <Typography variant="body2" sx={{ mb: 1 }}>
                            Transformations: {transformations.length}
                          </Typography>
                          <Typography variant="body2">
                            Schedule: {scheduleConfig.frequency}
                          </Typography>
                        </Box>
                      )}

                      <Box sx={{ mb: 1 }}>
                        <Button
                          variant="contained"
                          onClick={() => {
                            if (index === steps.length - 1) {
                              // Create pipeline
                              setActiveStep(0);
                            } else {
                              setActiveStep(activeStep + 1);
                            }
                          }}
                          sx={{ mr: 1 }}
                          disabled={
                            (index === 0 && !selectedSource) ||
                            (index === 2 && (!pipelineName || !targetTable))
                          }
                        >
                          {index === steps.length - 1 ? 'Create Pipeline' : 'Continue'}
                        </Button>
                        <Button
                          disabled={index === 0}
                          onClick={() => setActiveStep(activeStep - 1)}
                        >
                          Back
                        </Button>
                      </Box>
                    </StepContent>
                  </Step>
                ))}
              </Stepper>
            </CardContent>
          </Card>
        </Grid>

        {/* Existing Pipelines */}
        <Grid item xs={12}>
          <Card>
            <CardContent>
              <Typography variant="h6" sx={{ mb: 2, display: 'flex', alignItems: 'center', gap: 1 }}>
                <HistoryIcon />
                Migration Pipelines
              </Typography>
              
              <TableContainer>
                <Table>
                  <TableHead>
                    <TableRow>
                      <TableCell>Status</TableCell>
                      <TableCell>Pipeline</TableCell>
                      <TableCell>Source → Target</TableCell>
                      <TableCell>Schedule</TableCell>
                      <TableCell>Last Run</TableCell>
                      <TableCell>Actions</TableCell>
                    </TableRow>
                  </TableHead>
                  <TableBody>
                    {mockPipelines.map((pipeline) => (
                      <TableRow key={pipeline.id}>
                        <TableCell>
                          <Chip
                            icon={getStatusIcon(pipeline.status)}
                            label={pipeline.status}
                            color={getStatusColor(pipeline.status) as any}
                            size="small"
                          />
                        </TableCell>
                        <TableCell>
                          <Typography variant="subtitle2">{pipeline.name}</Typography>
                          <Typography variant="caption" sx={{ opacity: 0.7 }}>
                            {pipeline.description}
                          </Typography>
                        </TableCell>
                        <TableCell>
                          {pipeline.source.name} → {pipeline.target.table}
                        </TableCell>
                        <TableCell>
                          <Chip size="small" label={pipeline.schedule?.frequency || 'Manual'} />
                        </TableCell>
                        <TableCell>
                          {pipeline.lastRun && (
                            <Box>
                              <Typography variant="caption" display="block">
                                {new Date(pipeline.lastRun.timestamp).toLocaleString()}
                              </Typography>
                              <Typography variant="caption" display="block">
                                {pipeline.lastRun.recordsProcessed.toLocaleString()} records
                              </Typography>
                            </Box>
                          )}
                        </TableCell>
                        <TableCell>
                          <Tooltip title="Execute Pipeline">
                            <IconButton
                              size="small"
                              onClick={() => executePipelineMutation.mutate(pipeline)}
                              disabled={executePipelineMutation.isPending}
                            >
                              <ExecuteIcon />
                            </IconButton>
                          </Tooltip>
                          <Tooltip title="Edit Pipeline">
                            <IconButton size="small">
                              <EditIcon />
                            </IconButton>
                          </Tooltip>
                          <Tooltip title="Schedule">
                            <IconButton size="small">
                              <ScheduleIcon />
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

      {/* Data Preview Dialog */}
      <Dialog open={previewDialogOpen} onClose={() => setPreviewDialogOpen(false)} maxWidth="md" fullWidth>
        <DialogTitle>Data Preview</DialogTitle>
        <DialogContent>
          <TableContainer component={Paper}>
            <Table size="small">
              <TableHead>
                <TableRow>
                  {previewData.length > 0 && Object.keys(previewData[0]).map((key) => (
                    <TableCell key={key}>{key}</TableCell>
                  ))}
                </TableRow>
              </TableHead>
              <TableBody>
                {previewData.map((row, index) => (
                  <TableRow key={index}>
                    {Object.values(row).map((value, idx) => (
                      <TableCell key={idx}>{String(value)}</TableCell>
                    ))}
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </TableContainer>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setPreviewDialogOpen(false)}>Close</Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
};

export default SmartDataMigration;