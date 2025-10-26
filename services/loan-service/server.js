const express = require("express");
const { Pool } = require("pg");
const app = express();
const port = 7000;

// Database connection
const pool = new Pool({
  host: process.env.DB_HOST,
  user: process.env.DB_USER,
  password: process.env.DB_PASS,
  database: process.env.DB_NAME || 'finopsdb',
  port: 5432,
});

// Initialize database
async function initDB() {
  try {
    await pool.query(`
      CREATE TABLE IF NOT EXISTS loans (
        id SERIAL PRIMARY KEY,
        loan_id VARCHAR(20) UNIQUE,
        customer_name VARCHAR(100),
        amount DECIMAL(10,2),
        status VARCHAR(20),
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);
    
    // Insert sample data if table is empty
    const result = await pool.query('SELECT COUNT(*) FROM loans');
    if (parseInt(result.rows[0].count) === 0) {
      await pool.query(`
        INSERT INTO loans (loan_id, customer_name, amount, status) VALUES
        ('LOAN001', 'John Doe', 5000.00, 'active'),
        ('LOAN002', 'Jane Smith', 3000.00, 'active'),
        ('LOAN003', 'Bob Johnson', 2000.00, 'pending')
      `);
    }
    console.log('Loan database initialized');
  } catch (err) {
    console.error('Database initialization error:', err);
  }
}

initDB();

app.get("/", (req, res) => {
  res.json({ message: "Loan Service Running" });
});

app.get("/health", (req, res) => {
  res.json({ status: "healthy" });
});

app.get("/loans", async (req, res) => {
  try {
    const result = await pool.query('SELECT loan_id, customer_name, amount, status FROM loans');
    const activeLoans = result.rows.filter(loan => loan.status === 'active');
    const pendingLoans = result.rows.filter(loan => loan.status === 'pending');
    const totalDisbursed = activeLoans.reduce((sum, loan) => sum + parseFloat(loan.amount), 0);
    
    res.json({
      status: "success",
      active_loans: activeLoans.length,
      pending_approvals: pendingLoans.length,
      total_disbursed: `${totalDisbursed} USD`,
      loans: result.rows
    });
  } catch (err) {
    res.json({ error: err.message, status: "failed" });
  }
});

app.listen(port, () => console.log(`Loan service running on ${port}`));
