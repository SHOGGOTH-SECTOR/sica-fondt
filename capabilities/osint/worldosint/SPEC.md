# OSINT cluster — worldosint (clean-room SPEC, NO code copied)

Source: `worldosint-headless` — **AGPL-3.0**, so nothing is copied. This is a
clean-room description of the capability to reimplement as an MCP sidecar in the
`capabilities/osint/` cluster, registered in REPRAG and screened by the membrane.

## What to reimplement

A headless intel aggregator exposing ~50 read-only OSINT feeds over MCP. Each
feed is one tool: `{name, schema, fetch()->json}`. Groups observed in the source:

- **Conflict/unrest** — ACLED, UCDP, GDELT, humanitarian summaries.
- **Geo** — geocoding, OSM/Overpass filters, satellite snapshot URLs.
- **Maritime** — AIS vessel snapshots, navigational warnings.
- **Military/aviation** — OpenSky military flights, theater posture, airport delays.
- **Infrastructure** — internet outages, undersea-cable health, service status.
- **Cyber** — IOC feeds (IPs, domains, URLs, malware).
- **Seismology/climate** — USGS quakes, NASA FIRMS wildfire, climate anomalies.
- **Displacement** — UNHCR summaries, population exposure.
- **Markets/macro** — equities/crypto/commodities, FRED, World Bank, IMF, OECD, BIS.
- **Trade/supply-chain** — restrictions, tariffs, flows, chokepoints, minerals.
- **News/research** — RSS, arXiv, HN, trending repos, SEC/EDGAR, FMP.

## Implementation notes

- Clean-room: implement from the feed list above + each provider's public API
  docs. Do **not** read or copy the AGPL source.
- Strip the desktop/Tauri/deck.gl/maplibre UI — sidecar is data-only.
- Each feed = a registered REPRAG tool with a JSON schema (mini-rag selects it).
- API keys (FRED, FMP, SEC) via config, never hard-coded.
- ToS check per source (Telegram, GDELT, OpenSky) before enabling.
- Narrative summaries from these feeds may also be fed to LORAG.
