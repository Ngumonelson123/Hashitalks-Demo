from fastapi import FastAPI
import os
import psycopg2
from psycopg2.extras import RealDictCursor

app = FastAPI()

def get_db_connection():
    return psycopg2.connect(
        host=os.getenv("DB_HOST"),
        user=os.getenv("DB_USER"),
        password=os.getenv("DB_PASS"),
        dbname=os.getenv("DB_NAME", "finopsdb")
    )

def init_db():
    try:
        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute("""
            CREATE TABLE IF NOT EXISTS accounts (
                id SERIAL PRIMARY KEY,
                account_number VARCHAR(20) UNIQUE,
                customer_name VARCHAR(100),
                balance DECIMAL(10,2),
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        """)
        
        # Insert sample data if table is empty
        cur.execute("SELECT COUNT(*) FROM accounts")
        if cur.fetchone()[0] == 0:
            cur.execute("""
                INSERT INTO accounts (account_number, customer_name, balance) VALUES
                ('ACC001', 'John Doe', 1500.00),
                ('ACC002', 'Jane Smith', 2300.50),
                ('ACC003', 'Bob Johnson', 750.25)
            """)
        
        conn.commit()
        conn.close()
    except Exception as e:
        print(f"Database initialization error: {e}")

@app.on_event("startup")
async def startup_event():
    init_db()

@app.get("/")
def home():
    return {"message": "Account Service Running"}

@app.get("/health")
def health():
    return {"status": "healthy"}

@app.get("/accounts")
def get_accounts():
    try:
        conn = get_db_connection()
        cur = conn.cursor(cursor_factory=RealDictCursor)
        cur.execute("SELECT account_number, customer_name, balance FROM accounts")
        accounts = cur.fetchall()
        conn.close()
        return {
            "status": "success",
            "accounts": [dict(account) for account in accounts],
            "total_accounts": len(accounts)
        }
    except Exception as e:
        return {"error": str(e), "status": "failed"}
