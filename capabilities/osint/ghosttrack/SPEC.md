# OSINT — GhostTrack (rewrite SPEC, no code copied)

Source: `GhostTrack` — plain non-agentic Python with a custom honor-code license,
so per policy it is **rewritten**, not vendored. Kept because *all* OSINT is kept.

## Capability to reimplement

Three trivial lookups, as registered REPRAG tools:

- `phone_lookup(number)` — carrier / region / line-type (via a phone-numbers lib).
- `ip_lookup(ip)` — geo / ASN / org (via a public IP-geo API).
- `username_lookup(handle)` — presence across common social platforms.

## Notes

- Implement fresh against the underlying public APIs; structured JSON output
  (the original printed unstructured text — fix that for tool use).
- Rate-limit aware; API keys via config.
