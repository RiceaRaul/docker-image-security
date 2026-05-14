# syntax=docker/dockerfile:1.7
# Hardened multi-stage build using uv + distroless.
# Build context = repository root.

# ---------- Stage 1: builder ----------
FROM python:3.12.3-slim-bookworm AS builder

ENV UV_LINK_MODE=copy \
    UV_COMPILE_BYTECODE=1 \
    UV_PYTHON_DOWNLOADS=never \
    UV_PROJECT_ENVIRONMENT=/opt/venv \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

# Install uv from official static binary image (no curl|sh pattern)
COPY --from=ghcr.io/astral-sh/uv:0.4.20 /uv /uvx /usr/local/bin/

WORKDIR /src

# Cache deps layer separate from source for fast rebuilds
COPY app/pyproject.toml app/README.md ./
COPY app/src ./src

# Install secure (patched) dependency set into /opt/venv
RUN --mount=type=cache,target=/root/.cache/uv \
    uv venv /opt/venv \
 && uv pip install --python /opt/venv/bin/python --no-cache \
        "flask>=3.0.3" \
        "werkzeug>=3.0.3" \
        "jinja2>=3.1.4" \
        "itsdangerous>=2.2.0" \
        "requests>=2.32.3" \
        "pyyaml>=6.0.1" \
        "gunicorn>=22.0.0" \
 && uv pip install --python /opt/venv/bin/python --no-cache --no-deps .

# ---------- Stage 2: runtime (distroless, nonroot) ----------
FROM gcr.io/distroless/python3-debian12:nonroot

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PATH="/opt/venv/bin:${PATH}" \
    PORT=5000 \
    HOST=0.0.0.0

COPY --from=builder --chown=nonroot:nonroot /opt/venv /opt/venv

USER nonroot
WORKDIR /home/nonroot

EXPOSE 5000

# Distroless has no shell — exec form is mandatory.
# Healthcheck via Python (no curl in distroless).
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD ["/opt/venv/bin/python", "-c", "import urllib.request,sys; sys.exit(0 if urllib.request.urlopen('http://127.0.0.1:5000/healthz',timeout=2).status==200 else 1)"]

ENTRYPOINT ["/opt/venv/bin/gunicorn", \
            "--bind", "0.0.0.0:5000", \
            "--workers", "2", \
            "--threads", "4", \
            "--access-logfile", "-", \
            "--error-logfile", "-", \
            "app.main:create_app()"]
