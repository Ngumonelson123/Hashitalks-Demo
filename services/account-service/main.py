from fastapi import FastAPI
import os
import psycopg2

app = FastAPI()

@app.get("/")
def home():
    return {"message": "Account Service Running"}

@app.get("/accounts")
def get_accounts():
    try:
        conn = psycopg2.connect(
            host=os.getenv("DB_HOST"),
            user=os.getenv("DB_USER"),
            password=os.getenv("DB_PASS"),
            dbname="finopsdb"
        )
        cur = conn.cursor()
        cur.execute("SELECT 'Account balance: 500 USD';")
        res = cur.fetchone()
        conn.close()
        return {"result": res[0]}
    except Exception as e:
        return {"error": str(e)}
