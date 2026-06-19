// The cerebellum: the OpenHermes agent harness, mounted as an organ on the
// Ichor bus. It owns NO cognition -- it SEQUENCES a turn: receive input off the
// bus, drive the metacognitive passes through a swappable model adapter, emit
// the synthesis back through the bus (Brain-bound, so it crosses D1). This is
// the C1 integration spine ("plumbing + sequencing, not an organ").
//
// Plug-and-play: the model is the `LLM` seam below. StubLLM stands in now; drop
// a real OpenHermes client (HTTP / subprocess) in its place and nothing else
// on the bus changes.

// --- the model seam -------------------------------------------------------
interface val LLM
  """One inference call. Implement this to plug a model into the cerebellum."""
  fun infer(prompt: String): String

class val StubLLM is LLM
  """Stand-in until a real OpenHermes client is wired."""
  fun infer(prompt: String): String =>
    "[stub-openhermes] " + prompt

// --- the harness ----------------------------------------------------------
actor CerebellumHarness is OrganReceiver
  let _out: OutStream
  let _bus: Broker
  let _llm: LLM
  let _passes: USize

  new create(out': OutStream, bus: Broker, llm: LLM, passes': USize = 4) =>
    _out = out'
    _bus = bus
    _llm = llm
    // C1 L3: pass count is the responsiveness knob (energy-gated later), the
    // 4+4 ordering itself is static. Clamp to >=1 so a turn always runs once.
    _passes = if passes' < 1 then 1 else passes' end

  be receive(envl: Envelope) =>
    // A turn arrives off the bus. Sequence the passes through the model, then
    // emit the synthesis back onto the bus toward the Brain.
    var ctx: String = envl.payload
    var pass: USize = 1
    while pass <= _passes do
      ctx = _llm.infer(ctx)
      pass = pass + 1
    end
    _out.print("[cerebellum] " + _passes.string() + " passes -> " + ctx)
    _bus.route(Envelope(Cerebellum, Brain, OrganSecretion, ctx))
