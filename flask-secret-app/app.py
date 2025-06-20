from flask import Flask
import os

app = Flask(__name__)

@app.route("/")
def index():
    try:
        with open("/secrets/conjur-secret.txt", "r") as f:
            secret = f.read().strip()
    except Exception as e:
        secret = f"Error reading secret: {e}"
    return f"<h1>Retrieved Secret</h1><p>{secret}</p>"

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)