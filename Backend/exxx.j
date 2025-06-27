require('dotenv').config();
const express = require('express');
const { Pool } = require('pg');
const cors = require('cors');
const retry = require('async-retry');

const app = express();
const port = process.env.PORT || 3425;

// Database configuration
const dbConfig = {
  user: process.env.DB_USER || 'postgres',
  host: process.env.DB_HOST || 'postgres',
  database: process.env.DB_NAME || 'new_employee_db',
  password: process.env.DB_PASSWORD || 'admin123',
  port: process.env.DB_PORT || 5432,
};

// Create database pool with retry logic
const createPool = async () => {
  return await retry(
    async () => {
      const pool = new Pool(dbConfig);
      console.log('Attempting to connect to database...');
      const client = await pool.connect();
      client.release();
      console.log('Successfully connected to database');
      return pool;
    },
    {
      retries: 5,
      minTimeout: 2000,
      onRetry: (error) => {
        console.log(`Database connection failed, retrying... (${error.message})`);
      },
    }
  );
};

// Initialize application
const initApp = async () => {
  try {
    const pool = await createPool();

    // Middleware
    app.use(cors());
    app.use(express.json());

    // Health check endpoint
    app.get('/api/health', (req, res) => {
      res.status(200).json({ status: 'OK', database: 'Connected' });
    });

    // Get all requests for an employee
    app.get('/api/requests', async (req, res) => {
      try {
        const { employee_id } = req.query;
        const result = await pool.query(
          'SELECT * FROM asset_requests WHERE employee_id = $1',
          [employee_id]
        );
        res.json(result.rows);
      } catch (err) {
        console.error(err);
        res.status(500).json({ error: 'Internal server error' });
      }
    });

    // Create new request
    app.post('/api/requests', async (req, res) => {
      try {
        const {
          employee_id,
          employee_name,
          email,
          request_date,
          asset_type,
          asset_name,
          details,
        } = req.body;

        const result = await pool.query(
          `INSERT INTO asset_requests 
          (employee_id, employee_name, email, request_date, asset_type, asset_name, details)
          VALUES ($1, $2, $3, $4, $5, $6, $7) RETURNING *`,
          [employee_id, employee_name, email, request_date, asset_type, asset_name, details]
        );

        res.status(201).json(result.rows[0]);
      } catch (err) {
        console.error(err);
        res.status(500).json({ error: 'Internal server error' });
      }
    });

    // Start server
    app.listen(port, () => {
      console.log(`Server running on port ${port}`);
    });
  } catch (err) {
    console.error('Failed to initialize application:', err);
    process.exit(1);
  }
};

initApp();
