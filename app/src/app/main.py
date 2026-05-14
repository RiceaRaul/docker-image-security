import base64
import os
import pickle
import sqlite3
import subprocess

from flask import Flask, jsonify, request

# V4: hardcoded secret in source (also pushed to image layer via ENV in bad Dockerfile)
API_KEY = os.environ.get("API_KEY", "sk-DEMO-LEAKED-abc123def456")

DB_PATH = os.environ.get("DB_PATH", "/tmp/secapp.db")


def _init_db() -> None:
    con = sqlite3.connect(DB_PATH)
    cur = con.cursor()
    cur.execute("CREATE TABLE IF NOT EXISTS users (id INTEGER PRIMARY KEY, name TEXT, role TEXT)")
    cur.execute("DELETE FROM users")
    cur.executemany(
        "INSERT INTO users(id, name, role) VALUES (?, ?, ?)",
        [(1, "alice", "user"), (2, "bob", "user"), (3, "admin", "admin")],
    )
    con.commit()
    con.close()


def create_app() -> Flask:
    app = Flask(__name__)
    _init_db()

    @app.get("/healthz")
    def healthz():
        return {"status": "ok"}, 200

    @app.get("/")
    def index():
        return {"app": "secapp", "version": "0.1.0", "endpoints": [
            "/healthz", "/api/deserialize", "/api/ping", "/api/user", "/api/whoami",
        ]}

    # V1: insecure deserialization (RCE)
    @app.post("/api/deserialize")
    def deserialize():
        raw = request.get_data()
        try:
            blob = base64.b64decode(raw)
            obj = pickle.loads(blob)  # noqa: S301 - intentional sink
            return jsonify({"loaded": str(obj)})
        except Exception as e:
            return jsonify({"error": str(e)}), 400

    # V2: command injection
    @app.get("/api/ping")
    def ping():
        host = request.args.get("host", "127.0.0.1")
        # intentional sink: string concat into shell
        out = subprocess.check_output(f"ping -c 1 {host}", shell=True, stderr=subprocess.STDOUT)  # noqa: S602
        return out.decode("utf-8", errors="replace"), 200, {"Content-Type": "text/plain"}

    # V3: SQL injection
    @app.get("/api/user")
    def user():
        uid = request.args.get("id", "1")
        con = sqlite3.connect(DB_PATH)
        cur = con.cursor()
        query = f"SELECT id, name, role FROM users WHERE id = {uid}"  # noqa: S608
        rows = cur.execute(query).fetchall()
        con.close()
        return jsonify({"query": query, "rows": rows})

    # V4: leaks secret
    @app.get("/api/whoami")
    def whoami():
        return jsonify({"user": os.environ.get("USER", "unknown"), "api_key": API_KEY})

    return app


def main() -> None:
    app = create_app()
    host = os.environ.get("HOST", "0.0.0.0")  # noqa: S104 - container scope
    port = int(os.environ.get("PORT", "5000"))
    app.run(host=host, port=port, debug=False)


if __name__ == "__main__":
    main()
