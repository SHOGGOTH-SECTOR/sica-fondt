"""
Ichor — the perfusion medium ("the blood"). D2.

The one envelope every organ emits and consumes. Mirrors the Ada D1
`Organ_Message {Source, Destination, Provenance, Payload}` so the Pony broker
and the Ada border (Trust_Boundary) speak the same shape across the seam.

Envelope is `class val`: immutable and sendable between actors.
"""

// OUTER organs only. Ichor is the OUTER bus (the "skin") -- it carries the outer
// organs up to Ada (D1). The INNER organs -- soul, metacog, drive-box, mini-rag,
// Hermes, the E1 invariant laws -- do NOT belong here; they ride the Ada-routed
// (Jorvik) inner bus. NEVER add a brain/inner organ to this enum: that is
// "plugging the brain onto the skin". See docs/bus-topology.md.
type OrganId is
  ( Stomach | Microagents | SAE | MoRAG
  | AdaBorder | World | UnknownOrgan )

primitive Stomach
  // economy organ (small-model): digests external input into context
  fun string(): String => "stomach"
primitive Microagents
  fun string(): String => "microagents"
primitive SAE
  // sparse autoencoder
  fun string(): String => "sae"
primitive MoRAG
  // = GoDAGRAG: graph of DAGs of RAGs; reads the world
  fun string(): String => "morag"
primitive AdaBorder
  // the membrane (D1): the outer bus delivers inbound traffic here to be screened
  fun string(): String => "ada_border"
primitive World
  // the external world (user / network)
  fun string(): String => "world"
primitive UnknownOrgan
  fun string(): String => "unknown"

type Provenance is ( SystemInternal | UserInput | OrganSecretion | External )

primitive SystemInternal
  fun string(): String => "system_internal"
primitive UserInput
  fun string(): String => "user_input"
primitive OrganSecretion
  fun string(): String => "organ_secretion"
primitive External
  fun string(): String => "external"

class val Envelope
  let source: OrganId
  let dest: OrganId
  let provenance: Provenance
  let payload: String

  new val create(
    source': OrganId,
    dest': OrganId,
    provenance': Provenance,
    payload': String)
  =>
    source = source'
    dest = dest'
    provenance = provenance'
    payload = payload'

  fun string(): String =>
    source.string() + " -> " + dest.string()
      + " [" + provenance.string() + "] " + payload
