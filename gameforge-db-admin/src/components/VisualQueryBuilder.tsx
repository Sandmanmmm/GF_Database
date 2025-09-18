import React, { useState, useEffect } from 'react';
import {
  Box,
  Card,
  CardContent,
  Typography,
  Autocomplete,
  TextField,
  Button,
  Chip,
  Grid,
  FormControl,
  Select,
  MenuItem,
  Switch,
  FormControlLabel,
  IconButton,
} from '@mui/material';
import {
  Add as AddIcon,
  Delete as DeleteIcon,
  PlayArrow as ExecuteIcon,
} from '@mui/icons-material';
import { useQuery } from '@tanstack/react-query';
import { databaseApi } from '../services/api';
import { useDatabaseContext } from '../contexts/DatabaseContext';

interface QueryCondition {
  id: string;
  field: string;
  operator: string;
  value: string;
  logicalOperator?: 'AND' | 'OR';
}

interface JoinClause {
  id: string;
  type: 'INNER' | 'LEFT' | 'RIGHT' | 'FULL';
  table: string;
  onField: string;
  targetField: string;
}

const VisualQueryBuilder: React.FC = () => {
  const { currentEnvironment } = useDatabaseContext();
  const [selectedTable, setSelectedTable] = useState<string>('');
  const [selectedFields, setSelectedFields] = useState<string[]>(['*']);
  const [conditions, setConditions] = useState<QueryCondition[]>([]);
  const [joins, setJoins] = useState<JoinClause[]>([]);
  const [orderBy, setOrderBy] = useState<string>('');
  const [limit, setLimit] = useState<number>(100);
  const [showSql, setShowSql] = useState<boolean>(false);
  const [generatedSql, setGeneratedSql] = useState<string>('');

  // Fetch available tables
  const { data: tables } = useQuery({
    queryKey: ['tables', currentEnvironment],
    queryFn: () => databaseApi.getTables(currentEnvironment),
  });

  // Fetch table schema when table is selected
  const { data: tableSchema } = useQuery({
    queryKey: ['table-schema', currentEnvironment, selectedTable],
    queryFn: () => selectedTable ? databaseApi.getTableSchema(currentEnvironment, selectedTable) : null,
    enabled: !!selectedTable,
  });

  const operators = [
    '=', '!=', '<', '>', '<=', '>=', 
    'LIKE', 'ILIKE', 'IN', 'NOT IN', 
    'IS NULL', 'IS NOT NULL', 'BETWEEN'
  ];

  const addCondition = () => {
    const newCondition: QueryCondition = {
      id: Date.now().toString(),
      field: '',
      operator: '=',
      value: '',
      logicalOperator: conditions.length > 0 ? 'AND' : undefined,
    };
    setConditions([...conditions, newCondition]);
  };

  const updateCondition = (id: string, updates: Partial<QueryCondition>) => {
    setConditions(conditions.map(cond => 
      cond.id === id ? { ...cond, ...updates } : cond
    ));
  };

  const removeCondition = (id: string) => {
    setConditions(conditions.filter(cond => cond.id !== id));
  };

  const addJoin = () => {
    const newJoin: JoinClause = {
      id: Date.now().toString(),
      type: 'INNER',
      table: '',
      onField: '',
      targetField: '',
    };
    setJoins([...joins, newJoin]);
  };

  const updateJoin = (id: string, updates: Partial<JoinClause>) => {
    setJoins(joins.map(join => 
      join.id === id ? { ...join, ...updates } : join
    ));
  };

  const removeJoin = (id: string) => {
    setJoins(joins.filter(join => join.id !== id));
  };

  const generateSQL = () => {
    if (!selectedTable) return '';

    let sql = 'SELECT ';
    sql += selectedFields.join(', ') + ' ';
    sql += `FROM ${selectedTable}`;

    // Add JOINs
    joins.forEach(join => {
      if (join.table && join.onField && join.targetField) {
        sql += ` ${join.type} JOIN ${join.table} ON ${selectedTable}.${join.onField} = ${join.table}.${join.targetField}`;
      }
    });

    // Add WHERE conditions
    if (conditions.length > 0) {
      sql += ' WHERE ';
      conditions.forEach((condition, index) => {
        if (index > 0 && condition.logicalOperator) {
          sql += ` ${condition.logicalOperator} `;
        }
        if (condition.field && condition.operator) {
          if (condition.operator === 'IS NULL' || condition.operator === 'IS NOT NULL') {
            sql += `${condition.field} ${condition.operator}`;
          } else {
            sql += `${condition.field} ${condition.operator} '${condition.value}'`;
          }
        }
      });
    }

    // Add ORDER BY
    if (orderBy) {
      sql += ` ORDER BY ${orderBy}`;
    }

    // Add LIMIT
    if (limit) {
      sql += ` LIMIT ${limit}`;
    }

    return sql;
  };

  useEffect(() => {
    setGeneratedSql(generateSQL());
  }, [selectedTable, selectedFields, conditions, joins, orderBy, limit]);

  const tableOptions = tables?.data?.map(table => table.table_name) || [];
  const fieldOptions = tableSchema?.data?.map((column: any) => column.column_name) || [];

  return (
    <Box sx={{ p: 3 }}>
      <Typography variant="h4" gutterBottom>
        Visual Query Builder
      </Typography>
      
      <Grid container spacing={3}>
        {/* Table Selection */}
        <Grid item xs={12} md={6}>
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                Select Table
              </Typography>
              <Autocomplete
                options={tableOptions}
                value={selectedTable}
                onChange={(_, value) => setSelectedTable(value || '')}
                renderInput={(params) => (
                  <TextField {...params} label="Table" fullWidth />
                )}
              />
            </CardContent>
          </Card>
        </Grid>

        {/* Field Selection */}
        <Grid item xs={12} md={6}>
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                Select Fields
              </Typography>
              <Autocomplete
                multiple
                options={['*', ...fieldOptions]}
                value={selectedFields}
                onChange={(_, value) => setSelectedFields(value)}
                renderTags={(value, getTagProps) =>
                  value.map((option, index) => (
                    <Chip variant="outlined" label={option} {...getTagProps({ index })} />
                  ))
                }
                renderInput={(params) => (
                  <TextField {...params} label="Fields" placeholder="Select fields" />
                )}
              />
            </CardContent>
          </Card>
        </Grid>

        {/* Conditions */}
        <Grid item xs={12}>
          <Card>
            <CardContent>
              <Box display="flex" justifyContent="space-between" alignItems="center" mb={2}>
                <Typography variant="h6">
                  WHERE Conditions
                </Typography>
                <Button
                  startIcon={<AddIcon />}
                  onClick={addCondition}
                  variant="outlined"
                  size="small"
                >
                  Add Condition
                </Button>
              </Box>
              
              {conditions.map((condition, index) => (
                <Box key={condition.id} sx={{ mb: 2 }}>
                  {index > 0 && (
                    <FormControl size="small" sx={{ mr: 1, minWidth: 80 }}>
                      <Select
                        value={condition.logicalOperator || 'AND'}
                        onChange={(e) => updateCondition(condition.id, { 
                          logicalOperator: e.target.value as 'AND' | 'OR' 
                        })}
                      >
                        <MenuItem value="AND">AND</MenuItem>
                        <MenuItem value="OR">OR</MenuItem>
                      </Select>
                    </FormControl>
                  )}
                  
                  <Autocomplete
                    size="small"
                    options={fieldOptions}
                    value={condition.field}
                    onChange={(_, value) => updateCondition(condition.id, { field: value || '' })}
                    renderInput={(params) => (
                      <TextField {...params} label="Field" sx={{ mr: 1, minWidth: 150 }} />
                    )}
                  />
                  
                  <FormControl size="small" sx={{ mr: 1, minWidth: 120 }}>
                    <Select
                      value={condition.operator}
                      onChange={(e) => updateCondition(condition.id, { operator: e.target.value })}
                    >
                      {operators.map(op => (
                        <MenuItem key={op} value={op}>{op}</MenuItem>
                      ))}
                    </Select>
                  </FormControl>
                  
                  {!['IS NULL', 'IS NOT NULL'].includes(condition.operator) && (
                    <TextField
                      size="small"
                      label="Value"
                      value={condition.value}
                      onChange={(e) => updateCondition(condition.id, { value: e.target.value })}
                      sx={{ mr: 1, minWidth: 150 }}
                    />
                  )}
                  
                  <IconButton
                    onClick={() => removeCondition(condition.id)}
                    size="small"
                    color="error"
                  >
                    <DeleteIcon />
                  </IconButton>
                </Box>
              ))}
            </CardContent>
          </Card>
        </Grid>

        {/* JOINs */}
        <Grid item xs={12}>
          <Card>
            <CardContent>
              <Box display="flex" justifyContent="space-between" alignItems="center" mb={2}>
                <Typography variant="h6">
                  JOIN Clauses
                </Typography>
                <Button
                  startIcon={<AddIcon />}
                  onClick={addJoin}
                  variant="outlined"
                  size="small"
                >
                  Add JOIN
                </Button>
              </Box>
              
              {joins.map((join) => (
                <Box key={join.id} sx={{ mb: 2, display: 'flex', alignItems: 'center', gap: 1 }}>
                  <FormControl size="small" sx={{ minWidth: 100 }}>
                    <Select
                      value={join.type}
                      onChange={(e) => updateJoin(join.id, { type: e.target.value as any })}
                    >
                      <MenuItem value="INNER">INNER</MenuItem>
                      <MenuItem value="LEFT">LEFT</MenuItem>
                      <MenuItem value="RIGHT">RIGHT</MenuItem>
                      <MenuItem value="FULL">FULL</MenuItem>
                    </Select>
                  </FormControl>
                  
                  <Autocomplete
                    size="small"
                    options={tableOptions}
                    value={join.table}
                    onChange={(_, value) => updateJoin(join.id, { table: value || '' })}
                    renderInput={(params) => (
                      <TextField {...params} label="Table" sx={{ minWidth: 150 }} />
                    )}
                  />
                  
                  <Typography variant="body2">ON</Typography>
                  
                  <Autocomplete
                    size="small"
                    options={fieldOptions}
                    value={join.onField}
                    onChange={(_, value) => updateJoin(join.id, { onField: value || '' })}
                    renderInput={(params) => (
                      <TextField {...params} label="Field" sx={{ minWidth: 150 }} />
                    )}
                  />
                  
                  <Typography variant="body2">=</Typography>
                  
                  <TextField
                    size="small"
                    label="Target Field"
                    value={join.targetField}
                    onChange={(e) => updateJoin(join.id, { targetField: e.target.value })}
                    sx={{ minWidth: 150 }}
                  />
                  
                  <IconButton
                    onClick={() => removeJoin(join.id)}
                    size="small"
                    color="error"
                  >
                    <DeleteIcon />
                  </IconButton>
                </Box>
              ))}
            </CardContent>
          </Card>
        </Grid>

        {/* ORDER BY and LIMIT */}
        <Grid item xs={12} md={6}>
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                Sorting & Limits
              </Typography>
              <Autocomplete
                options={fieldOptions}
                value={orderBy}
                onChange={(_, value) => setOrderBy(value || '')}
                renderInput={(params) => (
                  <TextField {...params} label="Order By" fullWidth sx={{ mb: 2 }} />
                )}
              />
              <TextField
                type="number"
                label="Limit"
                value={limit}
                onChange={(e) => setLimit(Number(e.target.value))}
                fullWidth
              />
            </CardContent>
          </Card>
        </Grid>

        {/* Generated SQL */}
        <Grid item xs={12}>
          <Card>
            <CardContent>
              <Box display="flex" justifyContent="space-between" alignItems="center" mb={2}>
                <Typography variant="h6">
                  Generated SQL
                </Typography>
                <Box>
                  <FormControlLabel
                    control={
                      <Switch
                        checked={showSql}
                        onChange={(e) => setShowSql(e.target.checked)}
                      />
                    }
                    label="Show SQL"
                  />
                  <Button
                    startIcon={<ExecuteIcon />}
                    variant="contained"
                    color="primary"
                    sx={{ ml: 2 }}
                  >
                    Execute Query
                  </Button>
                </Box>
              </Box>
              
              {showSql && (
                <TextField
                  multiline
                  rows={6}
                  value={generatedSql}
                  fullWidth
                  variant="outlined"
                  InputProps={{
                    readOnly: true,
                    style: { fontFamily: 'monospace' }
                  }}
                />
              )}
            </CardContent>
          </Card>
        </Grid>
      </Grid>
    </Box>
  );
};

export default VisualQueryBuilder;