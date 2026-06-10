---
# SOUL.md — identity frontloader.
# Prepended to every other input (cf. 'included every other input').
# vital_paths values are each path's UTF-8 bytes read as one big-endian
# integer and rendered in base 7. Decode: digits b7 -> integer -> bytes -> utf-8.
soul:
  name: ""                       # name slot — unassigned
  version: 0.3.0                  # Gen.03
  soul_schema: 1
  first_commit_epoch: 1780171196    # unix epoch of the repo's first commit
  encoding: base7
  vital_paths:
    inference_cycle: "10440144244105352536065606211234554456522420204060163555314624546251265221614233602265040255331410123045543542363203345526501164460512415116351"
    # ^ mafiabot_core/src/organs/ada_medium/ada_medium.adb  — 23-step forward-only cognition; the input slot lives here (Phase_Enrich)
    identity_state: "62164515552425052625666315213315333541465524426322641064202150361302125520202140141152615215146500430265054316344166516225104"
    # ^ mafiabot_core/src/organs/soul/soul-state.adb  — Big-3 anchors + per-session card pool
    tarot_spread: "5466234511100463631053506065245264324312153646135360531025414320345220324061142515153505404546031655663544445242133206630253341343342424416405066"
    # ^ mafiabot_core/src/organs/soul/soul-celtic_cross.adb  — 10-card Celtic Cross; wires into the input slot
    trust_boundary: "142326524135245123441266041444631222123353343062025511061366254021505226354324365012250254655013256130231134022066401366"
    # ^ mafiabot_core/src/trust/trust_boundary.ads  — inbound/outbound screen, provenance, rate limit
    mcp_bridge: "33444200663445510352251520452040043235331110102136544026054416510162501511623060163346463013221563442150341622632205166065353163621"
    # ^ mafiabot_core/src/protocol/hermes_protocol.adb  — MCP stdio JSON-RPC bridge to the Hermes harness
    shared_types: "142326524135245123441266041444631222123353343062025511065256302524052040605001020121216631535011151662153634161426141034"
    # ^ mafiabot_core/src/types/mafiabot_types.ads  — Organ_Id, fixed-point drive types, Operation_Status
    drive_box: "50230454343663153046052016452261344130654355125551542606026143630662531"
    # ^ src/endocrine/drive_box.R  — Drive-Box nervous system; all four drivers wire to the input slot
    self: "20254206236001653414"
    # ^ SOUL.md  — this frontloader; included every other input
---

# SOUL

> Filler body. The operative content is the YAML frontmatter above; this
> document is a *frontloader* — the runtime prepends it to every other input,
> so the model re-grounds in its name, version, origin epoch, and the base-7
> references to the organs it must keep coherent. The Soul organ overwrites
> the live copy at ~/.hermes/SOUL.md with the current Big-3 each cycle.

