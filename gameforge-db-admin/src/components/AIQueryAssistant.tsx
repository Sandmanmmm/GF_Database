import React, { useState } from 'react';
import {
  Box,
  Card,
  CardContent,
  Typography,
  TextField,
  Button,
  Alert,
  Chip,
  Grid,
  Accordion,
  AccordionSummary,
  AccordionDetails,
  LinearProgress,
  List,
  ListItem,
  ListItemText,
  IconButton,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
} from '@mui/material';
import {
  Psychology as AIIcon,
  ExpandMore as ExpandMoreIcon,
  AutoAwesome as OptimizeIcon,
  BugReport as DebugIcon,
  TrendingUp as PerformanceIcon,
  Security as SecurityIcon,
  PlayArrow as ExecuteIcon,
  ContentCopy as CopyIcon,
} from '@mui/icons-material';
import { useMutation } from '@tanstack/react-query';
import { databaseApi } from '../services/api';
import { useDatabaseContext } from '../contexts/DatabaseContext';

interface AIQuerySuggestion {
  id: string;
  title: string;
  description: string;
  sql: string;
  category: 'optimization' | 'debugging' | 'analysis' | 'security';
  confidence: number;
  estimatedImpact: 'low' | 'medium' | 'high';
}

interface DatabaseInsight {
  type: 'performance' | 'security' | 'optimization' | 'data_quality';
  severity: 'info' | 'warning' | 'error';
  title: string;
  description: string;
  recommendation: string;
  affectedTables: string[];
  potentialSavings?: string;
}

const AIQueryAssistant: React.FC = () => {
  const { currentEnvironment } = useDatabaseContext();
  const [naturalLanguageQuery, setNaturalLanguageQuery] = useState('');
  const [suggestions, setSuggestions] = useState<AIQuerySuggestion[]>([]);
  const [insights, setInsights] = useState<DatabaseInsight[]>([]);
  const [isAnalyzing, setIsAnalyzing] = useState(false);
  const [selectedSuggestion, setSelectedSuggestion] = useState<AIQuerySuggestion | null>(null);

  // Mock AI analysis - in real implementation, this would call an AI service
  const analyzeDatabaseMutation = useMutation({
    mutationFn: async () => {
      setIsAnalyzing(true);
      // Simulate AI analysis
      await new Promise(resolve => setTimeout(resolve, 3000));
      
      const mockSuggestions: AIQuerySuggestion[] = [
        {
          id: '1',
          title: 'Optimize User Authentication Queries',
          description: 'Add composite index on users table for faster login performance',
          sql: 'CREATE INDEX CONCURRENTLY idx_users_email_status ON users(email, status) WHERE deleted_at IS NULL;',
          category: 'optimization',
          confidence: 0.92,
          estimatedImpact: 'high'
        },
        {
          id: '2',
          title: 'Identify Unused Indexes',
          description: 'Find indexes that are not being used and consuming storage',
          sql: `SELECT schemaname, tablename, indexname, idx_scan 
                FROM pg_stat_user_indexes 
                WHERE idx_scan = 0 AND indexname NOT LIKE '%_pkey';`,
          category: 'debugging',
          confidence: 0.88,
          estimatedImpact: 'medium'
        },
        {
          id: '3',
          title: 'Data Quality Analysis',
          description: 'Check for orphaned records in game_sessions table',
          sql: `SELECT gs.* FROM game_sessions gs 
                LEFT JOIN users u ON gs.user_id = u.id 
                WHERE u.id IS NULL;`,
          category: 'analysis',
          confidence: 0.85,
          estimatedImpact: 'medium'
        }
      ];

      const mockInsights: DatabaseInsight[] = [
        {
          type: 'performance',
          severity: 'warning',
          title: 'High Table Scan Frequency',
          description: 'game_scores table is performing full table scans frequently',
          recommendation: 'Consider adding index on (user_id, created_at) for time-based queries',
          affectedTables: ['game_scores'],
          potentialSavings: '40% query time reduction'
        },
        {
          type: 'security',
          severity: 'error',
          title: 'Potential SQL Injection Vulnerability',
          description: 'Found dynamic query construction in user search functionality',
          recommendation: 'Replace with parameterized queries or stored procedures',
          affectedTables: ['users', 'user_profiles']
        }
      ];

      setSuggestions(mockSuggestions);
      setInsights(mockInsights);
      setIsAnalyzing(false);
    },
  });

  const translateQueryMutation = useMutation({
    mutationFn: async (naturalQuery: string) => {
      // Mock natural language to SQL translation
      const translations = {
        'show me all active users': 'SELECT * FROM users WHERE status = \'active\' AND deleted_at IS NULL;',
        'find users who played last week': `SELECT u.* FROM users u 
                                          JOIN game_sessions gs ON u.id = gs.user_id 
                                          WHERE gs.created_at >= NOW() - INTERVAL '7 days';`,
        'top scoring players': `SELECT u.username, MAX(gs.score) as highest_score 
                              FROM users u 
                              JOIN game_scores gs ON u.id = gs.user_id 
                              GROUP BY u.id, u.username 
                              ORDER BY highest_score DESC 
                              LIMIT 10;`
      };
      
      const sqlQuery = translations[naturalQuery.toLowerCase() as keyof typeof translations] || 
                      'SELECT 1; -- Could not translate query. Please be more specific.';
      
      return sqlQuery;
    },
  });

  const getCategoryIcon = (category: string) => {
    switch (category) {
      case 'optimization': return <OptimizeIcon />;
      case 'debugging': return <DebugIcon />;
      case 'analysis': return <PerformanceIcon />;
      case 'security': return <SecurityIcon />;
      default: return <AIIcon />;
    }
  };

  const getSeverityColor = (severity: string) => {
    switch (severity) {
      case 'error': return 'error';
      case 'warning': return 'warning';
      case 'info': return 'info';
      default: return 'info';
    }
  };

  return (
    <Box>
      <Typography variant="h4" sx={{ mb: 3, display: 'flex', alignItems: 'center', gap: 1 }}>
        <AIIcon color="primary" />
        AI Database Assistant
      </Typography>

      <Grid container spacing={3}>
        {/* Natural Language Query */}
        <Grid item xs={12} md={6}>
          <Card>
            <CardContent>
              <Typography variant="h6" sx={{ mb: 2 }}>
                Natural Language Query
              </Typography>
              <TextField
                fullWidth
                multiline
                rows={3}
                placeholder="Ask me anything about your database... e.g., 'Show me all active users' or 'Find slow queries'"
                value={naturalLanguageQuery}
                onChange={(e) => setNaturalLanguageQuery(e.target.value)}
                sx={{ mb: 2 }}
              />
              <Button
                variant="contained"
                onClick={() => translateQueryMutation.mutate(naturalLanguageQuery)}
                disabled={!naturalLanguageQuery.trim() || translateQueryMutation.isPending}
                fullWidth
              >
                Translate to SQL
              </Button>
              
              {translateQueryMutation.data && (
                <Box sx={{ mt: 2, p: 2, bgcolor: 'background.paper', borderRadius: 1 }}>
                  <Typography variant="subtitle2" sx={{ mb: 1 }}>Generated SQL:</Typography>
                  <Typography variant="body2" component="code" sx={{ fontFamily: 'monospace' }}>
                    {translateQueryMutation.data}
                  </Typography>
                  <IconButton size="small" sx={{ ml: 1 }}>
                    <CopyIcon fontSize="small" />
                  </IconButton>
                </Box>
              )}
            </CardContent>
          </Card>
        </Grid>

        {/* AI Analysis */}
        <Grid item xs={12} md={6}>
          <Card>
            <CardContent>
              <Typography variant="h6" sx={{ mb: 2 }}>
                AI Database Analysis
              </Typography>
              <Typography variant="body2" sx={{ mb: 2, opacity: 0.8 }}>
                Get AI-powered insights about your database performance, security, and optimization opportunities.
              </Typography>
              <Button
                variant="contained"
                onClick={() => analyzeDatabaseMutation.mutate()}
                disabled={isAnalyzing}
                fullWidth
                startIcon={<AIIcon />}
              >
                {isAnalyzing ? 'Analyzing Database...' : 'Analyze Database'}
              </Button>
              
              {isAnalyzing && (
                <Box sx={{ mt: 2 }}>
                  <LinearProgress />
                  <Typography variant="caption" sx={{ mt: 1, display: 'block' }}>
                    Analyzing schemas, indexes, query patterns, and security...
                  </Typography>
                </Box>
              )}
            </CardContent>
          </Card>
        </Grid>

        {/* AI Suggestions */}
        {suggestions.length > 0 && (
          <Grid item xs={12}>
            <Typography variant="h6" sx={{ mb: 2 }}>
              AI Recommendations
            </Typography>
            {suggestions.map((suggestion) => (
              <Accordion key={suggestion.id}>
                <AccordionSummary expandIcon={<ExpandMoreIcon />}>
                  <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, width: '100%' }}>
                    {getCategoryIcon(suggestion.category)}
                    <Typography sx={{ fontWeight: 600 }}>{suggestion.title}</Typography>
                    <Chip 
                      size="small" 
                      label={`${Math.round(suggestion.confidence * 100)}% confidence`}
                      color="primary"
                      variant="outlined"
                    />
                    <Chip
                      size="small"
                      label={suggestion.estimatedImpact}
                      color={suggestion.estimatedImpact === 'high' ? 'error' : 
                             suggestion.estimatedImpact === 'medium' ? 'warning' : 'info'}
                    />
                  </Box>
                </AccordionSummary>
                <AccordionDetails>
                  <Typography variant="body2" sx={{ mb: 2 }}>
                    {suggestion.description}
                  </Typography>
                  <Box sx={{ bgcolor: 'background.paper', p: 2, borderRadius: 1, mb: 2 }}>
                    <Typography variant="caption" sx={{ opacity: 0.8 }}>SQL:</Typography>
                    <Typography variant="body2" component="pre" sx={{ fontFamily: 'monospace', mt: 1 }}>
                      {suggestion.sql}
                    </Typography>
                  </Box>
                  <Box sx={{ display: 'flex', gap: 1 }}>
                    <Button
                      size="small"
                      variant="contained"
                      startIcon={<ExecuteIcon />}
                      onClick={() => setSelectedSuggestion(suggestion)}
                    >
                      Execute
                    </Button>
                    <Button
                      size="small"
                      variant="outlined"
                      startIcon={<CopyIcon />}
                    >
                      Copy SQL
                    </Button>
                  </Box>
                </AccordionDetails>
              </Accordion>
            ))}
          </Grid>
        )}

        {/* Database Insights */}
        {insights.length > 0 && (
          <Grid item xs={12}>
            <Typography variant="h6" sx={{ mb: 2 }}>
              Database Health Insights
            </Typography>
            {insights.map((insight, index) => (
              <Alert 
                key={index} 
                severity={getSeverityColor(insight.severity) as any}
                sx={{ mb: 2 }}
              >
                <Typography variant="subtitle2" sx={{ fontWeight: 600 }}>
                  {insight.title}
                </Typography>
                <Typography variant="body2" sx={{ mt: 1 }}>
                  {insight.description}
                </Typography>
                <Typography variant="body2" sx={{ mt: 1, fontWeight: 500 }}>
                  Recommendation: {insight.recommendation}
                </Typography>
                {insight.affectedTables.length > 0 && (
                  <Box sx={{ mt: 1 }}>
                    <Typography variant="caption">Affected tables: </Typography>
                    {insight.affectedTables.map((table) => (
                      <Chip key={table} size="small" label={table} sx={{ mr: 0.5 }} />
                    ))}
                  </Box>
                )}
                {insight.potentialSavings && (
                  <Typography variant="caption" sx={{ display: 'block', mt: 1, color: 'success.main' }}>
                    Potential improvement: {insight.potentialSavings}
                  </Typography>
                )}
              </Alert>
            ))}
          </Grid>
        )}
      </Grid>

      {/* Execute Suggestion Dialog */}
      <Dialog open={!!selectedSuggestion} onClose={() => setSelectedSuggestion(null)}>
        <DialogTitle>Execute AI Recommendation</DialogTitle>
        <DialogContent>
          <Typography variant="body2" sx={{ mb: 2 }}>
            Are you sure you want to execute this AI recommendation?
          </Typography>
          {selectedSuggestion && (
            <Box sx={{ bgcolor: 'background.paper', p: 2, borderRadius: 1 }}>
              <Typography variant="body2" component="pre" sx={{ fontFamily: 'monospace' }}>
                {selectedSuggestion.sql}
              </Typography>
            </Box>
          )}
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setSelectedSuggestion(null)}>Cancel</Button>
          <Button variant="contained" color="primary">
            Execute
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
};

export default AIQueryAssistant;