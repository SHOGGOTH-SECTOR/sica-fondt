// The cerebellum: the OpenHermes agent harness, mounted as an organ on the
// Ichor bus. It owns NO cognition -- it SEQUENCES a turn: receive input off the
// bus, drive the metacognitive passes through a swappable model adapter, emit
// the synthesis back through the bus (Brain-bound, so it crosses D1). This is
// the C1 integration spine ("plumbing + sequencing, not an organ").
//
// Plug-and-play: the model is the `LLM` seam. A real model call is network /
// process IO, so the seam is ASYNCHRONOUS -- `infer` is a behaviour that hands
// its result to a callback. StubLLM answers immediately; OpenHermesClient is the
// real plug. Swap which one you register; nothing else on the bus changes.

// --- the model seam (async) ----------------------------------------------
type ResponseFn is {(String)} val
  """Callback the model invokes with its output."""

interface tag LLM
  be infer(prompt: String, respond: ResponseFn)

// --- stub -----------------------------------------------------------------
actor StubLLM is LLM
  new create() => None

  be infer(prompt: String, respond: ResponseFn) =>
    respond("[stub-openhermes] " + prompt)

// --- the OpenHermes plug --------------------------------------------------
class val OpenHermesConfig
  """Where to reach an OpenAI-compatible OpenHermes server."""
  let url: String       // base, e.g. http://localhost:8080/v1
  let model: String

  new val create(
    url': String = "http://localhost:8080/v1",
    model': String = "openhermes")
  =>
    url = url'
    model = model'

actor OpenHermesClient is LLM
  let _cfg: OpenHermesConfig

  new create(cfg: OpenHermesConfig) =>
    _cfg = cfg

  be infer(prompt: String, respond: ResponseFn) =>
    // TODO(loop next): POST an OpenAI-compatible chat/completions request to
    // `_cfg.url`/chat/completions via the process seam (curl) or a Pony TCP
    // client, parse choices[0].message.content, then call respond() with it.
    // Until that IO is wired and testable in this env, surface intent rather
    // than perform an untested network call.
    respond("[openhermes " + _cfg.model + " @ " + _cfg.url + "] " + prompt)

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
    // C1 L3: pass count is the responsiveness knob (energy-gated later); the
    // 4+4 ordering is static. Clamp to >=1 so a turn always runs once.
    _passes = if passes' < 1 then 1 else passes' end

  be receive(envl: Envelope) =>
    // A turn arrives off the bus: sequence the passes, then emit.
    _pass(envl.payload, 1)

  be _pass(ctx: String, n: USize) =>
    if n > _passes then
      _out.print("[cerebellum] " + _passes.string() + " passes -> " + ctx)
      _bus.route(Envelope(Cerebellum, Brain, OrganSecretion, ctx))
    else
      let self: CerebellumHarness tag = this
      _llm.infer(ctx, {(out: String)(self, n) => self._pass(out, n + 1) } val)
    end
