import React, { useState } from 'react';
import {
  Box,
  Typography,
  Paper,
  TextField,
  Button,
  Tabs,
  Tab,
  Card,
  CardContent,
  CircularProgress,
} from '@mui/material';
import {
  SmartToy as SmartToyIcon,
  Send as SendIcon,
  Psychology as PsychologyIcon,
  Security as SecurityIcon,
  Speed as SpeedIcon,
  Analytics as AnalyticsIcon,
} from '@mui/icons-material';

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

const AIQueryAssistantPanel: React.FC = () => {
  const [activeTab, setActiveTab] = useState(0);
  const [query, setQuery] = useState('');
  const [isLoading, setIsLoading] = useState(false);

  const handleTabChange = (_event: React.SyntheticEvent, newValue: number) => {
    setActiveTab(newValue);
  };

  const handleSubmit = async () => {
    if (!query.trim()) return;
    
    setIsLoading(true);
    // Simulate processing
    setTimeout(() => {
      setIsLoading(false);
      setQuery('');
    }, 2000);
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
        <TabPanel value={activeTab} index={0}>
          <Box sx={{ mb: 2 }}>
            <TextField
              fullWidth
              multiline
              rows={3}
              variant="outlined"
              placeholder="Ask me anything about your database..."
              value={query}
              onChange={(e) => setQuery(e.target.value)}
              sx={{ mb: 2 }}
            />
            <Button
              fullWidth
              variant="contained"
              startIcon={isLoading ? <CircularProgress size={20} /> : <SendIcon />}
              onClick={handleSubmit}
              disabled={isLoading || !query.trim()}
            >
              {isLoading ? 'Processing...' : 'Generate SQL'}
            </Button>
          </Box>

          <Paper sx={{ p: 2, backgroundColor: 'background.default' }}>
            <Typography variant="body2" color="text.secondary">
              Try asking: "Show me all users who registered this month"
            </Typography>
          </Paper>
        </TabPanel>

        <TabPanel value={activeTab} index={1}>
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                Optimization Recommendations
              </Typography>
              <Typography variant="body2" color="text.secondary">
                Real-time performance analysis and optimization suggestions will appear here.
              </Typography>
            </CardContent>
          </Card>
        </TabPanel>

        <TabPanel value={activeTab} index={2}>
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                Security Audit
              </Typography>
              <Typography variant="body2" color="text.secondary">
                Security analysis and recommendations will appear here.
              </Typography>
            </CardContent>
          </Card>
        </TabPanel>

        <TabPanel value={activeTab} index={3}>
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                Performance Insights
              </Typography>
              <Typography variant="body2" color="text.secondary">
                Database performance metrics and insights will appear here.
              </Typography>
            </CardContent>
          </Card>
        </TabPanel>
      </Box>
    </Box>
  );
};

export default AIQueryAssistantPanel;