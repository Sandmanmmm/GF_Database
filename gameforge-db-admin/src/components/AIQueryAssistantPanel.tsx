import React, { useState, useCallback } from 'react';
import {
  Box,
  Paper,
  Typography,
  TextField,
  Button,
  Accordion,
  AccordionSummary,
  AccordionDetails,
  Chip,
  Alert,
  CircularProgress,
  Switch,
  FormControlLabel,
  Tabs,
  Tab,
  Card,
  CardContent,
} from '@mui/material';
import {
  ExpandMore as ExpandMoreIcon,
  Send as SendIcon,
  Psychology as PsychologyIcon,
  Security as SecurityIcon,
  Speed as SpeedIcon,
  Analytics as AnalyticsIcon,
  AutoFixHigh as AutoFixHighIcon,
  PlayArrow as PlayArrowIcon,
  Refresh as RefreshIcon,
  SmartToy as SmartToyIcon,
  TrendingUp as TrendingUpIcon,
  Shield as ShieldIcon,
} from '@mui/icons-material';
import { LineChart, Line, ResponsiveContainer } from 'recharts';
import { useAIService } from '../hooks/useAIService';

interface TabPanelProps {
  children?: React.ReactNode;
  index: number;
  value: number;
}

function TabPanel(props: TabPanelProps) {
  const { children, value, index, ...other } = props;

  return (
    <div
      role="tabpanel"
      hidden={value !== index}
      id={`ai-tabpanel-${index}`}
      aria-labelledby={`ai-tab-${index}`}
      {...other}
    >
      {value === index && <Box sx={{ p: 2 }}>{children}</Box>}
    </div>
  );
}

interface QuerySuggestion {
  id: string;
  text: string;
  confidence: number;
  category: 'SELECT' | 'INSERT' | 'UPDATE' | 'DELETE' | 'ANALYSIS';
  sql: string;
  explanation: string;
}

interface OptimizationRecommendation {
  id: string;
  type: 'INDEX' | 'QUERY' | 'SCHEMA' | 'PERFORMANCE';
  title: string;
  description: string;
  impact: 'HIGH' | 'MEDIUM' | 'LOW';
  effort: 'LOW' | 'MEDIUM' | 'HIGH';
  sqlSuggestion?: string;
}

interface SecurityAlert {
  id: string;
  severity: 'CRITICAL' | 'HIGH' | 'MEDIUM' | 'LOW';
  title: string;
  description: string;
  affected: string[];
  recommendation: string;
}

interface PerformanceMetric {
  name: string;
  value: number;
  unit: string;
  status: 'good' | 'warning' | 'critical';
  trend: number[];
}

const AIQueryAssistantPanel: React.FC = () => {
  const [activeTab, setActiveTab] = useState(0);
  const [naturalLanguageQuery, setNaturalLanguageQuery] = useState('');
  const [autoOptimize, setAutoOptimize] = useState(true);
  const [realTimeMonitoring, setRealTimeMonitoring] = useState(true);
  const [queryHistory, setQueryHistory] = useState<QuerySuggestion[]>([]);
  
  // Use the AI service hooks
  const {
    processNaturalLanguage,
    executeQuery,
    useOptimizationRecommendations,
    useSecurityAudit,
  } = useAIService();

  // Load data from API
  const {
    data: optimizationData,
    isLoading: isLoadingOptimization,
    refetch: refetchOptimization,
  } = useOptimizationRecommendations();

  const {
    data: securityData,
    isLoading: isLoadingSecurity,
    refetch: refetchSecurity,
  } = useSecurityAudit();

  const handleTabChange = (_event: React.SyntheticEvent, newValue: number) => {
    setActiveTab(newValue);
  };

  const handleNaturalLanguageSubmit = useCallback(async () => {
    if (!naturalLanguageQuery.trim()) return;
    
    try {
      const result = await processNaturalLanguage.mutateAsync({ query: naturalLanguageQuery });
      
      if (result.success) {
        const newSuggestion: QuerySuggestion = {
          id: Date.now().toString(),
          text: naturalLanguageQuery,
          confidence: result.result.confidence,
          category: result.result.category as 'SELECT' | 'INSERT' | 'UPDATE' | 'DELETE' | 'ANALYSIS',
          sql: result.result.sql,
          explanation: result.result.explanation
        };
        
        setQueryHistory(prev => [newSuggestion, ...prev]);
        setNaturalLanguageQuery('');
      }
    } catch (error) {
      console.error('Failed to process natural language query:', error);
    }
  }, [naturalLanguageQuery, processNaturalLanguage]);

  const handleExecuteQuery = useCallback(async (sql: string) => {
    try {
      await executeQuery.mutateAsync({ sql, safetyCheck: true });
      // Handle successful execution - could show results in a modal or new tab
    } catch (error) {
      console.error('Failed to execute query:', error);
    }
  }, [executeQuery]);

  const getImpactColor = (impact: string) => {
    switch (impact) {
      case 'HIGH': return 'error';
      case 'MEDIUM': return 'warning';
      case 'LOW': return 'success';
      default: return 'default';
    }
  };

  const getSeverityColor = (severity: string) => {
    switch (severity) {
      case 'CRITICAL': return 'error';
      case 'HIGH': return 'error';
      case 'MEDIUM': return 'warning';
      case 'LOW': return 'info';
      default: return 'default';
    }
  };

  return (
    <Box sx={{ width: 400, height: '100vh', borderLeft: 1, borderColor: 'divider', backgroundColor: 'background.paper' }}>
      <Box sx={{ p: 2, borderBottom: 1, borderColor: 'divider' }}>
        <Box sx={{ display: 'flex', alignItems: 'center', mb: 1 }}>
          <SmartToyIcon color="primary" sx={{ mr: 1 }} />
          <Typography variant="h6" fontWeight="bold">
            AI Query Assistant
          </Typography>
        </Box>
        <Typography variant="body2" color="text.secondary">
          Intelligent database assistance powered by AI
        </Typography>
      </Box>

      <Tabs
        value={activeTab}
        onChange={handleTabChange}
        variant="fullWidth"
        sx={{ borderBottom: 1, borderColor: 'divider' }}
      >
        <Tab icon={<PsychologyIcon />} label="AI Chat" />
        <Tab icon={<SpeedIcon />} label="Optimize" />
        <Tab icon={<SecurityIcon />} label="Security" />
        <Tab icon={<AnalyticsIcon />} label="Insights" />
      </Tabs>

      <Box sx={{ height: 'calc(100vh - 140px)', overflow: 'auto' }}>
        {/* AI Chat Tab */}
        <TabPanel value={activeTab} index={0}>
          <Box sx={{ mb: 2 }}>
            <TextField
              fullWidth
              multiline
              rows={3}
              variant="outlined"
              placeholder="Ask me anything about your database... 
e.g., 'Show users who haven't logged in for 30 days'"
              value={naturalLanguageQuery}
              onChange={(e) => setNaturalLanguageQuery(e.target.value)}
              sx={{ mb: 2 }}
            />
            <Button
              fullWidth
              variant="contained"
              startIcon={processNaturalLanguage.isPending ? <CircularProgress size={20} /> : <SendIcon />}
              onClick={handleNaturalLanguageSubmit}
              disabled={processNaturalLanguage.isPending || !naturalLanguageQuery.trim()}
            >
              {processNaturalLanguage.isPending ? 'Processing...' : 'Generate SQL'}
            </Button>
          </Box>

          <FormControlLabel
            control={<Switch checked={autoOptimize} onChange={(e) => setAutoOptimize(e.target.checked)} />}
            label="Auto-optimize generated queries"
            sx={{ mb: 2 }}
          />

          <Typography variant="subtitle2" gutterBottom>
            Recent Suggestions
          </Typography>
          
          {queryHistory.map((suggestion) => (
            <Accordion key={suggestion.id} sx={{ mb: 1 }}>
              <AccordionSummary expandIcon={<ExpandMoreIcon />}>
                <Box sx={{ display: 'flex', alignItems: 'center', width: '100%' }}>
                  <Chip 
                    label={suggestion.category} 
                    size="small" 
                    color="primary" 
                    sx={{ mr: 1 }} 
                  />
                  <Typography variant="body2" sx={{ flexGrow: 1 }}>
                    {suggestion.text}
                  </Typography>
                  <Chip 
                    label={`${Math.round(suggestion.confidence * 100)}%`} 
                    size="small" 
                    color="success"
                  />
                </Box>
              </AccordionSummary>
              <AccordionDetails>
                <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
                  {suggestion.explanation}
                </Typography>
                <Paper sx={{ p: 2, backgroundColor: 'background.default', mb: 2 }}>
                  <Typography variant="caption" component="pre" sx={{ fontSize: '0.75rem', whiteSpace: 'pre-wrap' }}>
                    {suggestion.sql}
                  </Typography>
                </Paper>
                <Button
                  variant="contained"
                  size="small"
                  startIcon={executeQuery.isPending ? <CircularProgress size={16} /> : <PlayArrowIcon />}
                  onClick={() => handleExecuteQuery(suggestion.sql)}
                  disabled={executeQuery.isPending}
                  fullWidth
                >
                  {executeQuery.isPending ? 'Executing...' : 'Execute Query'}
                </Button>
              </AccordionDetails>
            </Accordion>
          ))}
        </TabPanel>

        {/* Optimization Tab */}
        <TabPanel value={activeTab} index={1}>
          <Box sx={{ mb: 2 }}>
            <FormControlLabel
              control={<Switch checked={realTimeMonitoring} onChange={(e) => setRealTimeMonitoring(e.target.checked)} />}
              label="Real-time monitoring"
            />
          </Box>

          <Typography variant="subtitle2" gutterBottom>
            Optimization Recommendations
          </Typography>

          {isLoadingOptimization && <CircularProgress />}
          
          {optimizationData?.recommendations?.map((rec) => (
            <Card key={rec.id} sx={{ mb: 2 }}>
              <CardContent>
                <Box sx={{ display: 'flex', alignItems: 'center', mb: 1 }}>
                  <AutoFixHighIcon color="primary" sx={{ mr: 1 }} />
                  <Typography variant="subtitle2" sx={{ flexGrow: 1 }}>
                    {rec.title}
                  </Typography>
                  <Chip label={rec.type} size="small" variant="outlined" />
                </Box>
                
                <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
                  {rec.description}
                </Typography>

                <Box sx={{ display: 'flex', gap: 1, mb: 2 }}>
                  <Chip 
                    label={`Impact: ${rec.impact}`} 
                    size="small" 
                    color={getImpactColor(rec.impact) as any}
                  />
                  <Chip 
                    label={`Effort: ${rec.effort}`} 
                    size="small" 
                    variant="outlined"
                  />
                </Box>

                {rec.sqlSuggestion && (
                  <Paper sx={{ p: 1, backgroundColor: 'background.default', mb: 2 }}>
                    <Typography variant="caption" component="pre" sx={{ fontSize: '0.7rem' }}>
                      {rec.sqlSuggestion}
                    </Typography>
                  </Paper>
                )}

                <Button
                  variant="outlined"
                  size="small"
                  startIcon={<PlayArrowIcon />}
                  fullWidth
                >
                  Apply Optimization
                </Button>
              </CardContent>
            </Card>
          ))}
        </TabPanel>

        {/* Security Tab */}
        <TabPanel value={activeTab} index={2}>
          <Typography variant="subtitle2" gutterBottom>
            Security Alerts
          </Typography>

          {isLoadingSecurity && <CircularProgress />}

          {securityData?.alerts?.map((alert) => (
            <Card key={alert.id} sx={{ mb: 2 }}>
              <CardContent>
                <Box sx={{ display: 'flex', alignItems: 'center', mb: 1 }}>
                  <ShieldIcon color="error" sx={{ mr: 1 }} />
                  <Typography variant="subtitle2" sx={{ flexGrow: 1 }}>
                    {alert.title}
                  </Typography>
                  <Chip 
                    label={alert.severity} 
                    size="small" 
                    color={getSeverityColor(alert.severity) as any}
                  />
                </Box>
                
                <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
                  {alert.description}
                </Typography>

                <Typography variant="caption" color="text.secondary" sx={{ mb: 1 }}>
                  Affected: {alert.affected.join(', ')}
                </Typography>

                <Alert severity="info" sx={{ mt: 1 }}>
                  <Typography variant="body2">
                    {alert.recommendation}
                  </Typography>
                </Alert>
              </CardContent>
            </Card>
          ))}

          <Button
            variant="contained"
            startIcon={<RefreshIcon />}
            fullWidth
            sx={{ mt: 2 }}
            onClick={() => refetchSecurity()}
            disabled={isLoadingSecurity}
          >
            {isLoadingSecurity ? 'Scanning...' : 'Run Security Scan'}
          </Button>
        </TabPanel>

        {/* Performance Insights Tab */}
        <TabPanel value={activeTab} index={3}>
          <Typography variant="subtitle2" gutterBottom>
            Performance Metrics
          </Typography>

          <Card sx={{ mb: 2 }}>
            <CardContent>
              <Box sx={{ display: 'flex', alignItems: 'center', mb: 1 }}>
                <TrendingUpIcon sx={{ mr: 1, color: '#10b981' }} />
                <Typography variant="subtitle2" sx={{ flexGrow: 1 }}>
                  Query Response Time
                </Typography>
                <Typography variant="h6" color="#10b981">
                  145ms
                </Typography>
              </Box>

              <Box sx={{ height: 60, mt: 2 }}>
                <ResponsiveContainer width="100%" height="100%">
                  <LineChart data={[
                    { value: 120, time: 0 },
                    { value: 130, time: 1 },
                    { value: 125, time: 2 },
                    { value: 140, time: 3 },
                    { value: 145, time: 4 },
                    { value: 135, time: 5 },
                    { value: 130, time: 6 }
                  ]}>
                    <Line 
                      type="monotone" 
                      dataKey="value" 
                      stroke="#10b981" 
                      strokeWidth={2}
                      dot={false}
                    />
                  </LineChart>
                </ResponsiveContainer>
              </Box>
            </CardContent>
          </Card>

          <Button
            variant="outlined"
            startIcon={<AnalyticsIcon />}
            fullWidth
            sx={{ mt: 2 }}
          >
            Generate Performance Report
          </Button>
        </TabPanel>
      </Box>
    </Box>
  );
};

export default AIQueryAssistantPanel;