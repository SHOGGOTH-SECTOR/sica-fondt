# Networking (optional) — clean-room SPEC, NO code copied

The transport membrane (`mafiabot_core/src/network/sockets.ads`) is a stub.
Two sources, both license-encumbered, kept as concept references only.

- **Reticulum** (custom license) — encrypted P2P mesh. Useful concept: the
  `Identity` + `Channel` + `Destination` model for coordination-free, end-to-end
  encrypted agent-to-agent links. Reimplement minimally if mesh transport is
  wanted; otherwise run Reticulum as an external sidecar behind the membrane.
- **mercury** (**AGPL**) — HF-radio modem. Concept only: ARQ/gearshift adaptive
  retransmission + LDPC robustness modes as a reliability policy for degraded
  links. Reimplement as a state machine if disaster/HF resilience is ever needed.

This whole layer is optional and currently unscheduled.
