import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';
import { ThemeProvider, createTheme } from '@mui/material/styles';
import { CssBaseline, Box } from '@mui/material';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { ReactQueryDevtools } from '@tanstack/react-query-devtools';

import Sidebar from './components/Sidebar';
import Dashboard from './pages/Dashboard';
import Tables from './pages/Tables';
import Users from './pages/Users';
import Migrations from './pages/Migrations';
import QueryEditor from './pages/QueryEditor';
import Backups from './pages/Backups';
import { DatabaseProvider } from './contexts/DatabaseContext';

const theme = createTheme({
  palette: {
    mode: 'dark',
    primary: {
      main: '#2563eb',
    },
    secondary: {
      main: '#10b981',
    },
    background: {
      default: '#0f172a',
      paper: '#1e293b',
    },
  },
  typography: {
    fontFamily: '"Inter", "Roboto", "Helvetica", "Arial", sans-serif',
  },
});

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      refetchOnWindowFocus: false,
      retry: 1,
      staleTime: 30000,
    },
  },
});

function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <ThemeProvider theme={theme}>
        <CssBaseline />
        <DatabaseProvider>
          <Router>
            <Box sx={{ display: 'flex', minHeight: '100vh' }}>
              <Sidebar />
              <Box 
                component="main" 
                sx={{ 
                  flexGrow: 1, 
                  p: 3,
                  backgroundColor: 'background.default'
                }}
              >
                <Routes>
                  <Route path="/" element={<Dashboard />} />
                  <Route path="/tables" element={<Tables />} />
                  <Route path="/users" element={<Users />} />
                  <Route path="/migrations" element={<Migrations />} />
                  <Route path="/query" element={<QueryEditor />} />
                  <Route path="/backups" element={<Backups />} />
                </Routes>
              </Box>
            </Box>
          </Router>
        </DatabaseProvider>
        <ReactQueryDevtools initialIsOpen={false} />
      </ThemeProvider>
    </QueryClientProvider>
  );
}

export default App;
