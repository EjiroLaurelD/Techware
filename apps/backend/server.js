// const express = require('express');
// const cors = require('cors');

// const app = express();
// const port = 5000;

// app.use(cors());  // Enable CORS to allow the frontend to communicate with the API

// app.get('/api/data', (req, res) => {
//   res.json({ message: 'Hello from the backend!' });
// });

// app.listen(port, () => {
//   console.log(`Server running at http://localhost:${port}`);
// });


// const express = require('express');
// const cors = require('cors');

// const app = express();
// const port = 5000;

// // Enable CORS to allow the frontend to communicate with the API
// app.use(cors());

// // Root route to display a welcome message
// app.get('/', (req, res) => {
//   res.send('Welcome to the backend API!');
// });

// // API route to send JSON data
// app.get('/api/data', (req, res) => {
//   res.json({ message: 'Hello from the backend!' });
// });

// // Start the server
// app.listen(port, () => {
//   console.log(`Server running at http://localhost:${port}`);
// });



const express = require('express');
const cors = require('cors');
const app = express();
const port = process.env.PORT || 80;

// Get frontend URL from environment variable (for flexibility)
const frontendUrl = process.env.FRONTEND_URL || 'http://localhost:3000'; // Default for local dev

// Configure CORS to allow requests from the frontend URL dynamically
const corsOptions = {
  origin: frontendUrl, // Allow requests from the dynamic frontend URL
  methods: ['GET', 'POST', 'PUT', 'DELETE'],
  allowedHeaders: ['Content-Type', 'Authorization'],
};

app.use(cors(corsOptions));

// Example route for testing the backend API
app.get('/api/data', (req, res) => {
  res.json({ message: 'Data from the backend API' });
});

app.get('/', (req, res) => {
  res.status(200).send('OK');
});

// Start the server
app.listen(port, () => {
  console.log(`Backend API running on port ${port}`);
});
