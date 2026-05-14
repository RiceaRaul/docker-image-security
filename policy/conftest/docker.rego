package main

# Input expected: CycloneDX SBOM JSON.
# Conftest passes the file as `input`.

critical_components[name] {
  some i
  c := input.components[i]
  some j
  v := c.vulnerabilities[j]
  v.ratings[_].severity == "critical"
  name := c.name
}

deny[msg] {
  count(critical_components) > 0
  msg := sprintf("CRITICAL CVEs found in components: %v", [critical_components])
}

warn[msg] {
  some i
  c := input.components[i]
  contains(lower(c.purl), "alpha")
  msg := sprintf("pre-release component: %s", [c.purl])
}
