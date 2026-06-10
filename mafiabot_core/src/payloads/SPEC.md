# Blood-brain barrier — capability call-export (port note)

`payloads/exploits.ads` is the BBB seam where the membrane **exports** tool/skill
calls to the `capabilities/` sidecars and **screens the returns** (post-22).

## Port reference

- Parallel dispatch pattern: `capabilities/registry/parallel-tool-calls/`
  (pi-openai-api-parallel-tool-calls, MIT) — schema-neutral payload mutation that
  batches independent tool calls. Port its dispatch logic into the Ada export
  path so REPRAG can fire multiple capabilities at once.
- Registry/schema source: `capabilities/registry/` (hermes + dapr).

## Invariant

Every capability return crosses back through the immune system
(`src/trust/`) before reaching the brain. The sidecars are untrusted; the
membrane is what makes them safe to use.
