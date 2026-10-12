const express = require('express');
const { Pool } = require('pg');

const app = express();
const PORT = process.env.PORT || 3000;

const pool = new Pool({
  host: process.env.DB_HOST || 'db-server',
  port: Number(process.env.DB_PORT || 5432),
  database: process.env.DB_NAME || 'appdb',
  user: process.env.DB_USER || 'appuser',
  password: process.env.DB_PASSWORD || 'app123'
});

app.get('/', async (req, res) => {
  try {
    const result = await pool.query(
      'SELECT current_database() AS database'
    );

    res.json({
      status: 'success',
      message: 'Backend connected to PostgreSQL!',
      database: result.rows[0].database
    });
  } catch (error) {
    console.error('Database connection failed:', error.message);
    res.status(500).json({
      status: 'error',
      message: 'Cannot connect to PostgreSQL'
    });
  }
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`Backend listening on port ${PORT}`);
});
