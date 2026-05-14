# secapp — Intentionally Vulnerable Flask App

Target app for Docker security demo (Master CSML, Software Security, Ricea Ion Raul).

## Vulnerabilities (by design)

| ID  | Location                | Type                          |
|-----|-------------------------|-------------------------------|
| V1  | `/api/deserialize`      | Insecure pickle deserialization (RCE) |
| V2  | `/api/ping`             | OS command injection          |
| V3  | `/api/user`             | SQL injection (sqlite)        |
| V4  | hardcoded `API_KEY`     | Secret in source / env layer  |
| V5  | outdated deps           | Multiple CVEs (Werkzeug, PyYAML, requests) |
| V6  | runs as root (bad img)  | Privilege escalation surface  |

## Build / Run (uv)

```bash
uv sync                          # install vulnerable pins
uv run secapp                    # dev server on :5000
uv sync --extra secure           # install patched versions
uv run pytest                    # smoke tests
```

## Endpoints

- `GET  /healthz`               → liveness
- `GET  /`                      → index
- `POST /api/deserialize`       → pickle.loads(body)  [V1]
- `GET  /api/ping?host=X`       → os.system("ping X") [V2]
- `GET  /api/user?id=X`         → SQL concat          [V3]
- `GET  /api/whoami`            → leaks API_KEY       [V4]
