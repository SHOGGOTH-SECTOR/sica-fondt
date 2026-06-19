"""
Ichor — the perfusion medium ("the blood"). D2.

The one envelope every organ emits and consumes. Mirrors the Ada D1
`Organ_Message {Source, Destination, Provenance, Payload}` so the Pony broker
and the Ada border (Trust_Boundary) speak the same shape across the seam.

Envelope is `class val`: immutable and sendable between actors.
"""

type OrganId is
  ( DriveBox | EnergyTorus | Soul | Metacog | Brain | Cerebellum
  | AdaBorder | Storage | MiniRag | UnknownOrgan )

primitive DriveBox
  fun string(): String => "drive_box"
primitive EnergyTorus
  fun string(): String => "etr"
primitive Soul
  fun string(): String => "soul"
primitive Metacog
  fun string(): String => "metacog"
primitive Brain
  fun string(): String => "brain"
primitive Cerebellum
  fun string(): String => "cerebellum"
primitive AdaBorder
  fun string(): String => "ada_border"
primitive Storage
  fun string(): String => "storage"
primitive MiniRag
  fun string(): String => "mini_rag"
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
