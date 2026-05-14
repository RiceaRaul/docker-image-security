package main

# Conftest evaluates CycloneDX SBOM (sbom.json) from Syft.
# Syft SBOM contains components but not CVE data — those come from Trivy.
# Policies below act on metadata: components, licenses, suspicious versions.

# ---- DENY rules ----

# Block GPL-3.0 only components (example license policy).
deny[msg] {
  some i
  c := input.components[i]
  some j
  c.licenses[j].license.id == "GPL-3.0-only"
  msg := sprintf("forbidden license GPL-3.0-only in component: %s", [c.name])
}

# Block components with no version pinned.
deny[msg] {
  some i
  c := input.components[i]
  not c.version
  msg := sprintf("component without version: %s", [c.name])
}

# ---- WARN rules ----

warn[msg] {
  some i
  c := input.components[i]
  contains(lower(c.version), "alpha")
  msg := sprintf("pre-release component: %s@%s", [c.name, c.version])
}

warn[msg] {
  some i
  c := input.components[i]
  contains(lower(c.version), "rc")
  msg := sprintf("release-candidate component: %s@%s", [c.name, c.version])
}
