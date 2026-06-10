# --- The Drive-Box "Nervous System" ---
# Couples the four autonomous drivers into one body. The wiring is NOT arbitrary
# glue: the Energy driver's own request_execution() comments that "in a full
# integration, this would call evaluate_tool_cost with actual PS+ and Eth-Int
# loads." This module IS that full integration -- the afferent (sensing) ->
# efferent (acting) arc:
#
#   PS+      (afferent)  : reads the endocrine array + priors  -> existential_load, arguments
#   Eth-Int  (modulator) : prices the proposed action vs principles -> eth_penalty
#   Energy   (efferent gate): folds ps_load + eth_penalty asymmetrically
#                            (evaluate_tool_cost) and gates on alive/tool-lock/affordability
#   ETR      (regime)    : reports temporal-coherence status + generative update path
#
# drive_snapshot()      -- read-only aggregate other organs consume (the Ada Medium
#                          would read this at Phase_Enrich / step 2 of the cycle).
# drive_box_evaluate()  -- run a proposed action through all four drivers.
# drive_box_commit()    -- write an approved action's consequences back into the body.

source("src/endocrine/driver_energy.R")
source("src/endocrine/driver_ps_plus.R")            # also sources endocrine_array + priors
source("src/endocrine/driver_ethical_integrity.R")
source("src/endocrine/driver_etr.R")

init_drive_box <- function() {
  list(
    energy  = init_energy_state(),
    ps_plus = init_ps_plus_state(),
    ethics  = init_principles_state(),
    etr     = init_etr_state()
  )
}

# Read-only aggregate: the drive state as other organs see it.
drive_snapshot <- function(state) {
  reality <- evaluate_reality(state$ps_plus)
  list(
    energy_ratio     = state$energy$current_energy / state$energy$max_energy,
    tool_locked      = is_tool_locked(state$energy),
    alive            = is_alive(state$energy),
    existential_load = reality$existential_load,
    arguments        = reality$arguments,
    etr_status       = evaluate_status(state$etr),
    update_path      = determine_system_update_path(state$etr)
  )
}

# Afferent -> efferent: evaluate a proposed action through the whole body.
#   action_tags       : tags describing the action (matched against principle antitheses)
#   alignment_tags    : principle ids this action upholds (alignment discount)
#   is_tool_call      : whether this is an external tool call (subject to tool-lock)
#   base_cost         : intrinsic energy cost before drive modulation
#   compromise_factor : partial-breach factor [0,1] for multi-polar constraints
drive_box_evaluate <- function(state, action_tags = character(0),
                               alignment_tags = character(0),
                               is_tool_call = TRUE, base_cost = 1.0,
                               compromise_factor = 0.0) {
  # 1. PS+ (afferent): visceral reality -> existential load + arguments (never logic)
  reality <- evaluate_reality(state$ps_plus)
  ps_load <- reality$existential_load

  # 2. Eth-Int: trajectory cost of THIS action; the marginal surcharge above base
  #    is the "ethical penalty" Energy folds in.
  eth_total   <- evaluate_trajectory_costs(state$ethics, action_tags, alignment_tags,
                                           base_energy = base_cost,
                                           compromise_factor = compromise_factor)
  eth_penalty <- max(0.0, eth_total - base_cost)

  # 3. Energy (efferent gate). This is the "full integration" request_execution
  #    anticipated: gates of alive -> tool-lock -> affordability, but the cost is
  #    the asymmetric evaluate_tool_cost(ps_load, eth_penalty), not the generic drag.
  approved <- TRUE
  reason   <- "Execution approved"
  true_cost <- evaluate_tool_cost(state$energy, ps_load = ps_load, eth_penalty = eth_penalty)
  if (!is_alive(state$energy)) {
    approved <- FALSE; reason <- "System is dead (0 energy)"
  } else if (is_tool_call && is_tool_locked(state$energy)) {
    approved <- FALSE; reason <- "Tool lock active (energy below threshold)"
  } else if (true_cost > state$energy$current_energy) {
    approved <- FALSE
    reason <- sprintf("True cost (%.2f) exceeds current energy (%.2f)",
                      true_cost, state$energy$current_energy)
  }

  # 4. ETR (regime): temporal-coherence status + generative path. Informational in
  #    this v1 -- it does not yet gate (see open design questions).
  list(
    approved         = approved,
    reason           = reason,
    true_cost        = true_cost,
    existential_load = ps_load,
    eth_penalty      = eth_penalty,
    etr_status       = evaluate_status(state$etr),
    update_path      = determine_system_update_path(state$etr),
    arguments        = reality$arguments
  )
}

# Efferent feedback: commit an approved action's consequences back into the body.
#   - Energy is consumed by the true cost.
#   - Upholding principles under existential load hardens their conviction
#     (load_factor scaled from existential_load).
drive_box_commit <- function(state, evaluation, alignment_tags = character(0)) {
  if (isTRUE(evaluation$approved)) {
    state$energy <- consume(state$energy, evaluation$true_cost)
    load_factor  <- min(1.0, evaluation$existential_load / 10.0)
    state$ethics <- enforce_conviction(state$ethics, alignment_tags, load_factor = load_factor)
  }
  state
}
