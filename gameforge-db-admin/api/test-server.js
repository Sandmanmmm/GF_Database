// Minimal test API server
const express = require('express');
const cors = require('cors');

const app = express();
const PORT = process.env.PORT || 5002;

// Basic middleware
app.use(cors());
app.use(express.json());

// Simple health check
app.get('/api/health', (req, res) => {
  console.log('Health check requested');
  res.json({ status: 'OK', timestamp: new Date().toISOString() });
});

// Simple test endpoint
app.get('/api/test', (req, res) => {
  res.json({ message: 'Test successful', port: PORT });
});

app.listen(PORT, () => {
  console.log(`🚀 Test API server running on port ${PORT}`);
  console.log(`🔗 Health check: http://localhost:${PORT}/api/health`);
});