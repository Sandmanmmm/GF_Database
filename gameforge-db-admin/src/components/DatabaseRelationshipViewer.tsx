import React, { useState, useEffect, useRef } from 'react';
import {
  Box,
  Card,
  CardContent,
  Typography,
  Paper,
  IconButton,
  Tooltip,
  Chip,
  List,
  ListItem,
  ListItemText,
  TextField,
  InputAdornment,
} from '@mui/material';
import {
  ZoomIn as ZoomInIcon,
  ZoomOut as ZoomOutIcon,
  CenterFocusStrong as CenterIcon,
  Search as SearchIcon,
  TableChart as TableIcon,
  AccountTree as RelationIcon,
} from '@mui/icons-material';
import { useQuery } from '@tanstack/react-query';
import { databaseApi } from '../services/api';
import { useDatabaseContext } from '../contexts/DatabaseContext';

interface TableNode {
  id: string;
  name: string;
  columns: Column[];
  position: { x: number; y: number };
  size: { width: number; height: number };
}

interface Column {
  name: string;
  type: string;
  isPrimary: boolean;
  isForeign: boolean;
  nullable: boolean;
}

interface Relationship {
  id: string;
  fromTable: string;
  fromColumn: string;
  toTable: string;
  toColumn: string;
  type: 'one-to-one' | 'one-to-many' | 'many-to-many';
}

const DatabaseRelationshipViewer: React.FC = () => {
  const { currentEnvironment } = useDatabaseContext();
  const canvasRef = useRef<HTMLDivElement>(null);
  const [selectedTable, setSelectedTable] = useState<string | null>(null);
  const [searchTerm, setSearchTerm] = useState('');
  const [zoom, setZoom] = useState(1);
  const [pan, setPan] = useState({ x: 0, y: 0 });
  const [tables, setTables] = useState<TableNode[]>([]);
  const [relationships, setRelationships] = useState<Relationship[]>([]);

  // Fetch tables and their schemas
  const { data: tablesData } = useQuery({
    queryKey: ['tables', currentEnvironment],
    queryFn: () => databaseApi.getTables(currentEnvironment),
  });

  // Fetch foreign key relationships
  const { data: relationshipsData } = useQuery({
    queryKey: ['relationships', currentEnvironment],
    queryFn: () => databaseApi.executeQuery(currentEnvironment, `
      SELECT
        tc.table_name as from_table,
        kcu.column_name as from_column,
        ccu.table_name as to_table,
        ccu.column_name as to_column,
        tc.constraint_name
      FROM 
        information_schema.table_constraints AS tc 
        JOIN information_schema.key_column_usage AS kcu
          ON tc.constraint_name = kcu.constraint_name
          AND tc.table_schema = kcu.table_schema
        JOIN information_schema.constraint_column_usage AS ccu
          ON ccu.constraint_name = tc.constraint_name
          AND ccu.table_schema = tc.table_schema
      WHERE tc.constraint_type = 'FOREIGN KEY'
        AND tc.table_schema = 'public'
      ORDER BY tc.table_name, kcu.column_name;
    `, true),
  });

  // Initialize tables layout
  useEffect(() => {
    if (tablesData?.data) {
      const tableNodes: TableNode[] = tablesData.data.map((table, index) => ({
        id: table.table_name,
        name: table.table_name,
        columns: [], // Will be populated by individual queries
        position: {
          x: (index % 5) * 300 + 50,
          y: Math.floor(index / 5) * 200 + 50,
        },
        size: { width: 250, height: 150 },
      }));
      setTables(tableNodes);
    }
  }, [tablesData]);

  // Initialize relationships
  useEffect(() => {
    if (relationshipsData?.data?.rows) {
      const rels: Relationship[] = relationshipsData.data.rows.map((row: any) => ({
        id: `${row.from_table}_${row.from_column}_${row.to_table}_${row.to_column}`,
        fromTable: row.from_table,
        fromColumn: row.from_column,
        toTable: row.to_table,
        toColumn: row.to_column,
        type: 'one-to-many', // Default type
      }));
      setRelationships(rels);
    }
  }, [relationshipsData]);

  const handleZoomIn = () => setZoom(prev => Math.min(prev * 1.2, 3));
  const handleZoomOut = () => setZoom(prev => Math.max(prev / 1.2, 0.3));
  const handleCenter = () => {
    setPan({ x: 0, y: 0 });
    setZoom(1);
  };

  const filteredTables = tables.filter(table =>
    table.name.toLowerCase().includes(searchTerm.toLowerCase())
  );

  const getRelationshipsForTable = (tableName: string) => {
    return relationships.filter(rel => 
      rel.fromTable === tableName || rel.toTable === tableName
    );
  };

  const renderTable = (table: TableNode) => (
    <Paper
      key={table.id}
      sx={{
        position: 'absolute',
        left: table.position.x * zoom + pan.x,
        top: table.position.y * zoom + pan.y,
        width: table.size.width * zoom,
        minHeight: table.size.height * zoom,
        cursor: 'pointer',
        border: selectedTable === table.name ? 2 : 1,
        borderColor: selectedTable === table.name ? 'primary.main' : 'divider',
        borderStyle: 'solid',
        '&:hover': {
          borderColor: 'primary.light',
          boxShadow: 2,
        },
      }}
      onClick={() => setSelectedTable(table.name)}
    >
      <Box
        sx={{
          bgcolor: 'primary.main',
          color: 'primary.contrastText',
          p: 1,
          display: 'flex',
          alignItems: 'center',
          gap: 1,
        }}
      >
        <TableIcon fontSize="small" />
        <Typography variant="subtitle2" noWrap>
          {table.name}
        </Typography>
      </Box>
      
      <Box sx={{ p: 1 }}>
        <Typography variant="caption" color="text.secondary">
          {getRelationshipsForTable(table.name).length} relationships
        </Typography>
      </Box>
    </Paper>
  );

  const renderRelationshipLine = (rel: Relationship) => {
    const fromTable = tables.find(t => t.name === rel.fromTable);
    const toTable = tables.find(t => t.name === rel.toTable);
    
    if (!fromTable || !toTable) return null;

    const startX = (fromTable.position.x + fromTable.size.width / 2) * zoom + pan.x;
    const startY = (fromTable.position.y + fromTable.size.height / 2) * zoom + pan.y;
    const endX = (toTable.position.x + toTable.size.width / 2) * zoom + pan.x;
    const endY = (toTable.position.y + toTable.size.height / 2) * zoom + pan.y;

    return (
      <line
        key={rel.id}
        x1={startX}
        y1={startY}
        x2={endX}
        y2={endY}
        stroke="#666"
        strokeWidth={2 * zoom}
        markerEnd="url(#arrowhead)"
      />
    );
  };

  return (
    <Box sx={{ height: '100vh', display: 'flex' }}>
      {/* Sidebar */}
      <Box sx={{ width: 300, borderRight: 1, borderColor: 'divider', overflow: 'auto' }}>
        <Box sx={{ p: 2 }}>
          <Typography variant="h6" gutterBottom>
            Database Schema
          </Typography>
          
          <TextField
            fullWidth
            size="small"
            placeholder="Search tables..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            InputProps={{
              startAdornment: (
                <InputAdornment position="start">
                  <SearchIcon />
                </InputAdornment>
              ),
            }}
            sx={{ mb: 2 }}
          />

          <List dense>
            {filteredTables.map((table) => (
              <ListItem
                key={table.id}
                button
                selected={selectedTable === table.name}
                onClick={() => setSelectedTable(table.name)}
              >
                <ListItemText
                  primary={table.name}
                  secondary={`${getRelationshipsForTable(table.name).length} relations`}
                />
              </ListItem>
            ))}
          </List>
        </Box>
      </Box>

      {/* Main Canvas */}
      <Box sx={{ flex: 1, position: 'relative', overflow: 'hidden' }}>
        {/* Toolbar */}
        <Box
          sx={{
            position: 'absolute',
            top: 16,
            right: 16,
            zIndex: 1000,
            display: 'flex',
            gap: 1,
          }}
        >
          <Tooltip title="Zoom In">
            <IconButton onClick={handleZoomIn} size="small">
              <ZoomInIcon />
            </IconButton>
          </Tooltip>
          <Tooltip title="Zoom Out">
            <IconButton onClick={handleZoomOut} size="small">
              <ZoomOutIcon />
            </IconButton>
          </Tooltip>
          <Tooltip title="Center View">
            <IconButton onClick={handleCenter} size="small">
              <CenterIcon />
            </IconButton>
          </Tooltip>
          <Chip label={`${Math.round(zoom * 100)}%`} size="small" />
        </Box>

        {/* Canvas */}
        <Box
          ref={canvasRef}
          sx={{
            width: '100%',
            height: '100%',
            position: 'relative',
            bgcolor: 'background.default',
            backgroundImage: `
              linear-gradient(rgba(255,255,255,0.1) 1px, transparent 1px),
              linear-gradient(90deg, rgba(255,255,255,0.1) 1px, transparent 1px)
            `,
            backgroundSize: `${20 * zoom}px ${20 * zoom}px`,
            overflow: 'hidden',
          }}
        >
          {/* SVG for relationship lines */}
          <svg
            style={{
              position: 'absolute',
              top: 0,
              left: 0,
              width: '100%',
              height: '100%',
              pointerEvents: 'none',
            }}
          >
            <defs>
              <marker
                id="arrowhead"
                markerWidth="10"
                markerHeight="7"
                refX="10"
                refY="3.5"
                orient="auto"
              >
                <polygon
                  points="0 0, 10 3.5, 0 7"
                  fill="#666"
                />
              </marker>
            </defs>
            {relationships.map(renderRelationshipLine)}
          </svg>

          {/* Tables */}
          {filteredTables.map(renderTable)}
        </Box>
      </Box>

      {/* Table Details Panel */}
      {selectedTable && (
        <Box sx={{ width: 300, borderLeft: 1, borderColor: 'divider', overflow: 'auto' }}>
          <Box sx={{ p: 2 }}>
            <Typography variant="h6" gutterBottom>
              {selectedTable}
            </Typography>
            
            <Typography variant="subtitle2" gutterBottom>
              Relationships
            </Typography>
            
            {getRelationshipsForTable(selectedTable).map((rel) => (
              <Card key={rel.id} sx={{ mb: 1 }}>
                <CardContent sx={{ p: 1, '&:last-child': { pb: 1 } }}>
                  <Box display="flex" alignItems="center" gap={1}>
                    <RelationIcon fontSize="small" />
                    <Typography variant="body2">
                      {rel.fromTable === selectedTable 
                        ? `→ ${rel.toTable}.${rel.toColumn}`
                        : `← ${rel.fromTable}.${rel.fromColumn}`
                      }
                    </Typography>
                  </Box>
                </CardContent>
              </Card>
            ))}
          </Box>
        </Box>
      )}
    </Box>
  );
};

export default DatabaseRelationshipViewer;