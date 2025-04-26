const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const winston = require('winston');

// Create Express app
const app = express();
const port = process.env.PORT || 8080;

// Configure logger
const logger = winston.createLogger({
  level: 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.json()
  ),
  defaultMeta: { service: 'api-service' },
  transports: [
    new winston.transports.Console(),
  ],
});

// Middleware
app.use(helmet()); // Security headers
app.use(cors({
  origin: process.env.FRONTEND_URL || '*', // In production, restrict to your frontend domain
  methods: 'GET,HEAD,PUT,PATCH,POST,DELETE',
  preflightContinue: false,
  optionsSuccessStatus: 204,
  credentials: true,
}));
app.use(express.json()); // Parse JSON request body
app.use(morgan('combined')); // Request logging

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'healthy' });
});

// API routes
app.get('/api/v1/info', (req, res) => {
  res.json({
    name: 'Cloud Native Backend API',
    version: '1.0.0',
    environment: process.env.NODE_ENV || 'development',
    timestamp: new Date().toISOString()
  });
});

// Sample resource endpoint
app.get('/api/v1/items', (req, res) => {
  const items = [
    { id: 1, name: 'Item 1', description: 'This is item 1' },
    { id: 2, name: 'Item 2', description: 'This is item 2' },
    { id: 3, name: 'Item 3', description: 'This is item 3' },
  ];
  
  res.json(items);
});

// Add a new item (POST example)
app.post('/api/v1/items', (req, res) => {
  const { name, description } = req.body;
  
  if (!name) {
    return res.status(400).json({ error: 'Name is required' });
  }
  
  // In a real app, you would save to a database
  logger.info('Item created', { name, description });
  
  res.status(201).json({ 
    id: Math.floor(Math.random() * 1000) + 10,
    name, 
    description,
    createdAt: new Date().toISOString()
  });
});

// Error handling middleware
app.use((err, req, res, next) => {
  logger.error('Application error', { error: err.message, stack: err.stack });
  res.status(500).json({ error: 'Internal Server Error' });
});

// Not found handler
app.use((req, res) => {
  res.status(404).json({ error: 'Not Found' });
});

// Start server
app.listen(port, () => {
  logger.info(`Server listening on port ${port}`);
});