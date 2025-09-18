import React, { useState } from 'react';
import {
  Box,
  Grid,
  Card,
  CardContent,
  Typography,
  Button,
  TextField,
  Select,
  MenuItem,
  FormControl,
  InputLabel,
  Stepper,
  Step,
  StepLabel,
  Alert,
  LinearProgress,
  List,
  ListItem,
  ListItemText,
  ListItemIcon,
  Chip,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Paper,
  IconButton,
  Tooltip,
} from '@mui/material';
import {
  CloudUpload as ImportIcon,
  CloudDownload as ExportIcon,
  Delete as DeleteIcon,
  Edit as UpdateIcon,
  PlayArrow as ExecuteIcon,
  CheckCircle as SuccessIcon,
  Error as ErrorIcon,
  Warning as WarningIcon,
  Visibility as PreviewIcon,
  Cancel as CancelIcon,
} from '@mui/icons-material';
import { useQuery, useMutation } from '@tanstack/react-query';
import { databaseApi } from '../services/api';
import { useDatabaseContext } from '../contexts/DatabaseContext';

interface BulkOperation {
  id: string;
  type: 'import' | 'export' | 'update' | 'delete';
  table: string;
  status: 'pending' | 'running' | 'completed' | 'failed';
  progress: number;
  recordsProcessed: number;
  totalRecords: number;
  errors: string[];
  createdAt: Date;
}

interface ImportConfig {
  table: string;
  file: File | null;
  format: 'csv' | 'json' | 'sql';
  hasHeaders: boolean;
  delimiter: string;
  onConflict: 'skip' | 'update' | 'replace';
}

interface ExportConfig {
  table: string;
  format: 'csv' | 'json' | 'sql';
  columns: string[];
  whereClause: string;
  limit: number;
}

const BulkOperations: React.FC = () => {
  const { currentEnvironment } = useDatabaseContext();
  const [activeStep, setActiveStep] = useState(0);
  const [operationType, setOperationType] = useState<'import' | 'export' | 'update' | 'delete'>('import');
  const [importConfig, setImportConfig] = useState<ImportConfig>({
    table: '',
    file: null,
    format: 'csv',
    hasHeaders: true,
    delimiter: ',',
    onConflict: 'skip',
  });
  const [exportConfig, setExportConfig] = useState<ExportConfig>({
    table: '',
    format: 'csv',
    columns: [],
    whereClause: '',
    limit: 1000,
  });
  const [operations, setOperations] = useState<BulkOperation[]>([]);
  const [previewData, setPreviewData] = useState<any[]>([]);
  const [showPreview, setShowPreview] = useState(false);

  // Fetch available tables
  const { data: tables } = useQuery({
    queryKey: ['tables', currentEnvironment],
    queryFn: () => databaseApi.getTables(currentEnvironment),
  });

  // Fetch table schema for selected table
  const { data: tableSchema } = useQuery({
    queryKey: ['table-schema', currentEnvironment, importConfig.table || exportConfig.table],
    queryFn: () => {
      const table = operationType === 'import' ? importConfig.table : exportConfig.table;
      return table ? databaseApi.getTableSchema(currentEnvironment, table) : null;
    },
    enabled: !!(importConfig.table || exportConfig.table),
  });

  const steps = ['Configure', 'Preview', 'Execute'];

  const handleFileUpload = (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    if (file) {
      setImportConfig({ ...importConfig, file });
      // Parse file for preview
      parseFilePreview(file);
    }
  };

  const parseFilePreview = (file: File) => {
    const reader = new FileReader();
    reader.onload = (e) => {
      const content = e.target?.result as string;
      let preview: any[] = [];

      try {
        if (importConfig.format === 'csv') {
          const lines = content.split('\n').slice(0, 5); // First 5 lines
          preview = lines.map(line => {
            const values = line.split(importConfig.delimiter);
            return values.reduce((obj, val, index) => {
              obj[`column_${index + 1}`] = val.trim();
              return obj;
            }, {} as any);
          });
        } else if (importConfig.format === 'json') {
          const parsed = JSON.parse(content);
          preview = Array.isArray(parsed) ? parsed.slice(0, 5) : [parsed];
        }
        setPreviewData(preview);
      } catch (error) {
        console.error('Error parsing file:', error);
      }
    };
    reader.readAsText(file);
  };

  const executeImport = useMutation({
    mutationFn: async () => {
      // Mock implementation - would call actual import API
      const newOperation: BulkOperation = {
        id: Date.now().toString(),
        type: 'import',
        table: importConfig.table,
        status: 'running',
        progress: 0,
        recordsProcessed: 0,
        totalRecords: previewData.length * 100, // Mock total
        errors: [],
        createdAt: new Date(),
      };

      setOperations(prev => [...prev, newOperation]);

      // Simulate progress
      for (let i = 0; i <= 100; i += 10) {
        await new Promise(resolve => setTimeout(resolve, 200));
        setOperations(prev => prev.map(op => 
          op.id === newOperation.id 
            ? { ...op, progress: i, recordsProcessed: Math.floor((i / 100) * op.totalRecords) }
            : op
        ));
      }

      setOperations(prev => prev.map(op => 
        op.id === newOperation.id ? { ...op, status: 'completed' as const } : op
      ));

      return newOperation;
    },
  });

  const executeExport = useMutation({
    mutationFn: async () => {
      // Mock implementation - would call actual export API
      const query = `SELECT ${exportConfig.columns.join(', ') || '*'} FROM ${exportConfig.table}${
        exportConfig.whereClause ? ` WHERE ${exportConfig.whereClause}` : ''
      } LIMIT ${exportConfig.limit}`;

      const result = await databaseApi.executeQuery(currentEnvironment, query, true);
      
      // Create downloadable file
      const blob = new Blob([JSON.stringify(result.data.rows, null, 2)], {
        type: 'application/json',
      });
      const url = URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = `${exportConfig.table}_export.${exportConfig.format}`;
      a.click();
      URL.revokeObjectURL(url);

      return result;
    },
  });

  const handleNext = () => {
    if (activeStep === 0 && operationType === 'import' && !importConfig.file) {
      alert('Please select a file first');
      return;
    }
    if (activeStep === 0 && !importConfig.table && !exportConfig.table) {
      alert('Please select a table first');
      return;
    }
    setActiveStep(prev => prev + 1);
  };

  const handleBack = () => setActiveStep(prev => prev - 1);

  const handleExecute = () => {
    if (operationType === 'import') {
      executeImport.mutate();
    } else if (operationType === 'export') {
      executeExport.mutate();
    }
    setActiveStep(0);
  };

  const getStatusIcon = (status: BulkOperation['status']) => {
    switch (status) {
      case 'completed':
        return <SuccessIcon color="success" />;
      case 'failed':
        return <ErrorIcon color="error" />;
      case 'running':
        return <LinearProgress sx={{ width: 20 }} />;
      default:
        return <WarningIcon color="warning" />;
    }
  };

  const tableOptions = tables?.data?.map(table => table.table_name) || [];
  const columnOptions = tableSchema?.data?.map((col: any) => col.column_name) || [];

  return (
    <Box sx={{ p: 3 }}>
      <Typography variant="h4" gutterBottom>
        Bulk Operations
      </Typography>

      <Grid container spacing={3}>
        {/* Operation Configuration */}
        <Grid item xs={12} lg={8}>
          <Card>
            <CardContent>
              <Box display="flex" justifyContent="space-between" alignItems="center" mb={3}>
                <Typography variant="h6">Configure Operation</Typography>
                <FormControl size="small" sx={{ minWidth: 150 }}>
                  <InputLabel>Operation Type</InputLabel>
                  <Select
                    value={operationType}
                    onChange={(e) => setOperationType(e.target.value as any)}
                    label="Operation Type"
                  >
                    <MenuItem value="import">Import Data</MenuItem>
                    <MenuItem value="export">Export Data</MenuItem>
                    <MenuItem value="update">Bulk Update</MenuItem>
                    <MenuItem value="delete">Bulk Delete</MenuItem>
                  </Select>
                </FormControl>
              </Box>

              <Stepper activeStep={activeStep} sx={{ mb: 3 }}>
                {steps.map((label) => (
                  <Step key={label}>
                    <StepLabel>{label}</StepLabel>
                  </Step>
                ))}
              </Stepper>

              {/* Step Content */}
              {activeStep === 0 && (
                <Box>
                  <Grid container spacing={2}>
                    <Grid item xs={12} md={6}>
                      <FormControl fullWidth>
                        <InputLabel>Target Table</InputLabel>
                        <Select
                          value={operationType === 'import' ? importConfig.table : exportConfig.table}
                          onChange={(e) => {
                            if (operationType === 'import') {
                              setImportConfig({ ...importConfig, table: e.target.value });
                            } else {
                              setExportConfig({ ...exportConfig, table: e.target.value });
                            }
                          }}
                          label="Target Table"
                        >
                          {tableOptions.map(table => (
                            <MenuItem key={table} value={table}>{table}</MenuItem>
                          ))}
                        </Select>
                      </FormControl>
                    </Grid>

                    {operationType === 'import' && (
                      <>
                        <Grid item xs={12} md={6}>
                          <FormControl fullWidth>
                            <InputLabel>File Format</InputLabel>
                            <Select
                              value={importConfig.format}
                              onChange={(e) => setImportConfig({ 
                                ...importConfig, 
                                format: e.target.value as any 
                              })}
                              label="File Format"
                            >
                              <MenuItem value="csv">CSV</MenuItem>
                              <MenuItem value="json">JSON</MenuItem>
                              <MenuItem value="sql">SQL</MenuItem>
                            </Select>
                          </FormControl>
                        </Grid>
                        <Grid item xs={12}>
                          <Button
                            variant="outlined"
                            component="label"
                            startIcon={<ImportIcon />}
                            fullWidth
                            sx={{ height: 60 }}
                          >
                            {importConfig.file ? importConfig.file.name : 'Choose File to Import'}
                            <input
                              type="file"
                              hidden
                              accept=".csv,.json,.sql"
                              onChange={handleFileUpload}
                            />
                          </Button>
                        </Grid>
                      </>
                    )}

                    {operationType === 'export' && (
                      <>
                        <Grid item xs={12} md={6}>
                          <FormControl fullWidth>
                            <InputLabel>Export Format</InputLabel>
                            <Select
                              value={exportConfig.format}
                              onChange={(e) => setExportConfig({ 
                                ...exportConfig, 
                                format: e.target.value as any 
                              })}
                              label="Export Format"
                            >
                              <MenuItem value="csv">CSV</MenuItem>
                              <MenuItem value="json">JSON</MenuItem>
                              <MenuItem value="sql">SQL</MenuItem>
                            </Select>
                          </FormControl>
                        </Grid>
                        <Grid item xs={12}>
                          <TextField
                            fullWidth
                            label="WHERE Clause (optional)"
                            value={exportConfig.whereClause}
                            onChange={(e) => setExportConfig({ 
                              ...exportConfig, 
                              whereClause: e.target.value 
                            })}
                            placeholder="e.g., created_at > '2023-01-01'"
                          />
                        </Grid>
                        <Grid item xs={12} md={6}>
                          <TextField
                            fullWidth
                            type="number"
                            label="Record Limit"
                            value={exportConfig.limit}
                            onChange={(e) => setExportConfig({ 
                              ...exportConfig, 
                              limit: Number(e.target.value) 
                            })}
                          />
                        </Grid>
                      </>
                    )}
                  </Grid>
                </Box>
              )}

              {activeStep === 1 && (
                <Box>
                  <Typography variant="h6" gutterBottom>
                    Preview Data
                  </Typography>
                  {previewData.length > 0 ? (
                    <TableContainer component={Paper} sx={{ maxHeight: 400 }}>
                      <Table size="small">
                        <TableHead>
                          <TableRow>
                            {Object.keys(previewData[0] || {}).map(key => (
                              <TableCell key={key}>{key}</TableCell>
                            ))}
                          </TableRow>
                        </TableHead>
                        <TableBody>
                          {previewData.map((row, index) => (
                            <TableRow key={index}>
                              {Object.values(row).map((value: any, i) => (
                                <TableCell key={i}>{String(value)}</TableCell>
                              ))}
                            </TableRow>
                          ))}
                        </TableBody>
                      </Table>
                    </TableContainer>
                  ) : (
                    <Alert severity="info">No preview data available</Alert>
                  )}
                </Box>
              )}

              {activeStep === 2 && (
                <Box>
                  <Alert severity="warning" sx={{ mb: 2 }}>
                    You are about to {operationType} data {operationType === 'import' ? 'into' : 'from'} the {
                      operationType === 'import' ? importConfig.table : exportConfig.table
                    } table. This action cannot be undone.
                  </Alert>
                  <Typography variant="body1">
                    Click Execute to start the {operationType} operation.
                  </Typography>
                </Box>
              )}

              {/* Navigation Buttons */}
              <Box display="flex" justifyContent="space-between" mt={3}>
                <Button
                  disabled={activeStep === 0}
                  onClick={handleBack}
                >
                  Back
                </Button>
                <Box>
                  {activeStep === steps.length - 1 ? (
                    <Button
                      variant="contained"
                      onClick={handleExecute}
                      startIcon={<ExecuteIcon />}
                      disabled={executeImport.isPending || executeExport.isPending}
                    >
                      Execute {operationType}
                    </Button>
                  ) : (
                    <Button
                      variant="contained"
                      onClick={handleNext}
                    >
                      Next
                    </Button>
                  )}
                </Box>
              </Box>
            </CardContent>
          </Card>
        </Grid>

        {/* Operation History */}
        <Grid item xs={12} lg={4}>
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                Recent Operations
              </Typography>
              <List dense>
                {operations.map((operation) => (
                  <ListItem key={operation.id}>
                    <ListItemIcon>
                      {getStatusIcon(operation.status)}
                    </ListItemIcon>
                    <ListItemText
                      primary={
                        <Box display="flex" justifyContent="space-between">
                          <span>{operation.type} - {operation.table}</span>
                          <Chip
                            label={operation.status}
                            size="small"
                            color={operation.status === 'completed' ? 'success' : 
                                   operation.status === 'failed' ? 'error' : 'default'}
                          />
                        </Box>
                      }
                      secondary={
                        <Box>
                          <Typography variant="caption" display="block">
                            {operation.recordsProcessed} / {operation.totalRecords} records
                          </Typography>
                          {operation.status === 'running' && (
                            <LinearProgress 
                              variant="determinate" 
                              value={operation.progress} 
                              sx={{ mt: 1 }}
                            />
                          )}
                        </Box>
                      }
                    />
                  </ListItem>
                ))}
                {operations.length === 0 && (
                  <ListItem>
                    <ListItemText 
                      primary="No operations yet"
                      secondary="Start by configuring an import or export operation"
                    />
                  </ListItem>
                )}
              </List>
            </CardContent>
          </Card>
        </Grid>
      </Grid>
    </Box>
  );
};

export default BulkOperations;