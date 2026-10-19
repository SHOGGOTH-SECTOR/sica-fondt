# Economy organ — M0 stomach

Executable scaffold for M0–M7. The stomach is an OUTER organ: its only organism-facing product is an Ada-bound `organ_secretion`; it never joins the inner bus.

## Implemented now

- **M1 Marketplace** — single action ingress; wallet-first admission; deterministic action/chain law; wallet brake; Conductor veto after law; simulated execution only.
- **M2 Feeds** — normalized datum history with explicit backpressure instead of silent eviction.
- **M3 Sims hub** — bounded-prediction validation and current-state publication/query. Native M3a–M3g engines and 90:1 scheduler are not built yet.
- **M4 Wallets** — permanent 1:1 trader binding plus per-action/session exposure brakes. No private-key field, signer, or RPC surface exists yet.
- **M5 Traders** — trader registry and mechanical pause state. AI trader inference is not implemented here.
- **M6 Conductor** — veto-next, pause/resume, SAE alert intake, append-only in-memory decision log. Specialist inference is not implemented yet.
- **M7 SAE** — records Marketplace tool calls and produces alert envelopes; actual sparse-autoencoder inference/training is not implemented yet.
- **M0** — composes the above, stages tax receipts without moving value, and emits a stomach→Ada status secretion.

There is deliberately no live transaction broadcaster. A successful action returns `execution simulated` and a deterministic `simtx-*` identifier. Live custody/execution should not appear until the unresolved M4 key-storage design is ratified.

## Test

```sh
tclsh core/src/economy/tests/stomach.test
```

Expected: `Total 13 Passed 13 ... Failed 0`.

## Public scaffold API

`::stomach::Economy` exposes `register_trader`, `bind_wallet`, `submit_action`, `feed_publish`, `feed_history`, `sim_publish`, `query_predictions`, `conductor_veto_next`, `conductor_pause`, `conductor_resume`, `sae_alert`, `tax_event`, and `secretion`.

`secretion` returns the envelope-compatible metadata `source stomach`, `destination ada_border`, `provenance organ_secretion`. The runtime Pony↔Tcl bridge is still an integration task; no code may shortcut D1 while that bridge is built.
