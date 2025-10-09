from flask import Flask, jsonify
import requests, os

app = Flask(__name__)

ACCOUNT_URL = os.getenv("ACCOUNT_URL")
LOAN_URL = os.getenv("LOAN_URL")

@app.route("/")
def home():
    return jsonify({"message": "FinOps API Gateway Running"})

@app.route("/summary")
def summary():
    try:
        acc = requests.get(f"{ACCOUNT_URL}/accounts").json()
        loan = requests.get(f"{LOAN_URL}/loans").json()
        return jsonify({
            "account_info": acc,
            "loan_info": loan
        })
    except Exception as e:
        return jsonify({"error": str(e)})

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=80)
