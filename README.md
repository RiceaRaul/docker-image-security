# docker-image-security

Securizarea aplicațiilor Docker — analiza vulnerabilităților containerelor, scanare imagini, best practices.

**Master CSML — Software Security, Universitatea Ovidius Constanța**
Autor: **Ricea Ion Raul**

## Scope

Image-only security:

- Dockerfile best practices (multi-stage, distroless, non-root, pinned digest)
- Linting (Hadolint)
- Vulnerability scan (Trivy, Grype)
- SBOM (Syft — CycloneDX + SPDX)
- Secret scan (Trivy, `docker history`)
- Policy gate (Conftest / OPA pe SBOM)
- Image signing + attestation (Cosign)
- CI/CD: Jenkins declarative pipeline cu dynamic K8s agents (BuildKit rootless)

## Layout

```
app/        Flask app (uv, intentionally vulnerable)
docker/     Dockerfile (hardened) + Dockerfile.bad
ci/         Jenkinsfile + agent-pod.yaml
k8s/        Jenkins namespace + ServiceAccount
policy/     Conftest rego + Kyverno cosign verify
attacks/    Demo: secret leak, CVE exploit, unsigned swap
document/   LaTeX report
```

## Quickstart

```bash
cd app && uv sync && uv run pytest
DOCKER_BUILDKIT=1 docker build -f docker/Dockerfile     -t secapp:hardened .
DOCKER_BUILDKIT=1 docker build -f docker/Dockerfile.bad -t secapp:bad .
trivy image secapp:bad
trivy image secapp:hardened
```
