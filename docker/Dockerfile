# syntax=docker/dockerfile:1.7
# Hardened multi-stage build — Chainguard wolfi base = near-zero CVE.
# Build context = repository root.
#
# Why Chainguard:
#   - 0-CVE policy on tracked images (rebuilt daily against upstream patches)
#   - distroless runtime, nonroot by default (uid 65532)
#   - wolfi-linux (musl alternative w/ glibc), small surface
#
# Why uv:
#   - fast resolver, deterministic install into /opt/venv

# ---------- Stage 1: builder ----------
FROM cgr.dev/chainguard/python:latest-dev AS builder

ENV UV_LINK_MODE=copy \
    UV_COMPILE_BYTECODE=1 \
    UV_PYTHON_DOWNLOADS=never \
    UV_PROJECT_ENVIRONMENT=/opt/venv \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

# Install uv from official static binary image (no curl|sh).
COPY --from=ghcr.io/astral-sh/uv:0.4.20 /uv /uvx /usr/local/bin/

USER root
WORKDIR /src

# Copy project metadata + sources.
COPY app/pyproject.toml app/README.md ./
COPY app/src ./src

# Install hardened (patched) dependency set into /opt/venv.
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
 && uv pip install --python /opt/venv/bin/python --no-cache --no-deps . \
 && chown -R 65532:65532 /opt/venv

# ---------- Stage 2: runtime (chainguard distroless, nonroot) ----------
FROM cgr.dev/chainguard/python:latest

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PATH="/opt/venv/bin:${PATH}" \
    PORT=5000 \
    HOST=0.0.0.0

COPY --from=builder --chown=nonroot:nonroot /opt/venv /opt/venv

USER nonroot
WORKDIR /home/nonroot

EXPOSE 5000

# Distroless = no shell, no curl. Healthcheck via Python stdlib.
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD ["/opt/venv/bin/python", "-c", "import urllib.request,sys; sys.exit(0 if urllib.request.urlopen('http://127.0.0.1:5000/healthz',timeout=2).status==200 else 1)"]

ENTRYPOINT ["/opt/venv/bin/gunicorn", \
            "--bind", "0.0.0.0:5000", \
            "--workers", "2", \
            "--threads", "4", \
            "--access-logfile", "-", \
            "--error-logfile", "-", \
            "app.main:create_app()"]
