import React from 'react';
import { useNavigate, useLocation } from 'react-router-dom';
import {
  Drawer,
  List,
  ListItem,
  ListItemButton,
  ListItemIcon,
  ListItemText,
  Typography,
  Box,
  FormControl,
  Select,
  MenuItem,
  Chip,
  Divider,
} from '@mui/material';
import {
  Dashboard as DashboardIcon,
  TableChart as TableIcon,
  People as UsersIcon,
  Upgrade as MigrationsIcon,
  Code as QueryIcon,
  Backup as BackupIcon,
  Storage as DatabaseIcon,
} from '@mui/icons-material';

import { useDatabaseContext } from '../contexts/DatabaseContext';

const DRAWER_WIDTH = 280;

const menuItems = [
  { path: '/', label: 'Dashboard', icon: DashboardIcon },
  { path: '/tables', label: 'Tables', icon: TableIcon },
  { path: '/users', label: 'Database Users', icon: UsersIcon },
  { path: '/migrations', label: 'Migrations', icon: MigrationsIcon },
  { path: '/query', label: 'Query Editor', icon: QueryIcon },
  { path: '/backups', label: 'Backups', icon: BackupIcon },
];

const Sidebar: React.FC = () => {
  const navigate = useNavigate();
  const location = useLocation();
  const { currentEnvironment, setCurrentEnvironment } = useDatabaseContext();

  return (
    <Drawer
      variant="permanent"
      sx={{
        width: DRAWER_WIDTH,
        flexShrink: 0,
        '& .MuiDrawer-paper': {
          width: DRAWER_WIDTH,
          boxSizing: 'border-box',
          backgroundColor: 'background.paper',
          borderRight: '1px solid',
          borderColor: 'divider',
        },
      }}
    >
      <Box sx={{ p: 3 }}>
        <Box sx={{ display: 'flex', alignItems: 'center', mb: 2 }}>
          <DatabaseIcon sx={{ mr: 1, color: 'primary.main' }} />
          <Typography variant="h6" sx={{ fontWeight: 600 }}>
            GameForge DB
          </Typography>
        </Box>
        
        <FormControl fullWidth size="small">
          <Typography variant="body2" sx={{ mb: 1, opacity: 0.7 }}>
            Environment
          </Typography>
          <Select
            value={currentEnvironment}
            onChange={(e) => setCurrentEnvironment(e.target.value as 'dev' | 'prod')}
            sx={{ mb: 1 }}
          >
            <MenuItem value="dev">
              <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                Development
                <Chip 
                  label="DEV" 
                  size="small" 
                  color="info" 
                  sx={{ fontSize: '0.7rem', height: '18px' }}
                />
              </Box>
            </MenuItem>
            <MenuItem value="prod">
              <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                Production
                <Chip 
                  label="PROD" 
                  size="small" 
                  color="error" 
                  sx={{ fontSize: '0.7rem', height: '18px' }}
                />
              </Box>
            </MenuItem>
          </Select>
        </FormControl>
      </Box>

      <Divider />

      <List sx={{ flexGrow: 1, px: 1 }}>
        {menuItems.map((item) => {
          const Icon = item.icon;
          const isActive = location.pathname === item.path;
          
          return (
            <ListItem key={item.path} disablePadding>
              <ListItemButton
                onClick={() => navigate(item.path)}
                selected={isActive}
                sx={{
                  borderRadius: 2,
                  mb: 0.5,
                  mx: 1,
                  '&.Mui-selected': {
                    backgroundColor: 'primary.main',
                    color: 'primary.contrastText',
                    '&:hover': {
                      backgroundColor: 'primary.dark',
                    },
                  },
                }}
              >
                <ListItemIcon 
                  sx={{ 
                    color: isActive ? 'inherit' : 'text.secondary',
                    minWidth: 40,
                  }}
                >
                  <Icon fontSize="small" />
                </ListItemIcon>
                <ListItemText 
                  primary={item.label}
                  primaryTypographyProps={{
                    fontSize: '0.875rem',
                    fontWeight: isActive ? 600 : 400,
                  }}
                />
              </ListItemButton>
            </ListItem>
          );
        })}
      </List>

      <Box sx={{ p: 2 }}>
        <Typography variant="caption" sx={{ opacity: 0.6 }}>
          GameForge Database Admin v1.0.0
        </Typography>
      </Box>
    </Drawer>
  );
};

export default Sidebar;