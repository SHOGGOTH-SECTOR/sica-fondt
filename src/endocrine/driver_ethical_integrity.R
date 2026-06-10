# --- High-Fidelity Implementation for Driver 3: Ethical Integrity (Eth-Int) ---
#
# Ethical Integrity is the Drive-Box's principled backbone. It holds a set of
# convictions, each with an associated "antithesis" -- the action tags that
# violate it. Trajectory costs are warped by these principles:
#
#   * Antithetical actions incur an EXPONENTIAL penalty scaled by conviction,
#     making it progressively unthinkable to violate a strongly-held principle.
#   * Aligned actions receive an EXPONENTIAL discount, making the right thing
#     cheaper the more deeply the principle is held.
#   * Compromise (multi-polar constraint) adds a LINEAR partial penalty for
#     trajectories that only partially satisfy competing principles.
#
# Convictions ratchet: principles upheld under load are retroactively hardened
# with diminishing returns toward an asymptote of 1.0.
#
# State is a plain list with one field:
#   principles - a list of principle records, each a list(id, conviction, antithesis)
#
# All functions are pure: state-mutating helpers return a new (modified copy of
# the) list rather than mutating in place.

# Constructor helper so tests and other modules can build a clean state.
init_principles_state <- function() {
  list(principles = list())
}

# Register a new principle. Conviction is clamped into [0, 1].
add_principle <- function(principles_state, id, conviction, antithesis) {
  new_principle <- list(
    id = id,
    conviction = max(0.0, min(1.0, conviction)),
    antithesis = antithesis
  )
  principles_state$principles[[length(principles_state$principles) + 1]] <- new_principle
  return(principles_state)
}

# Compute the warped energy cost of a candidate trajectory.
evaluate_trajectory_costs <- function(principles_state, action_tags, alignment_tags, base_energy, compromise_factor) {
  total_cost <- base_energy

  # 1. Antithetical Penalty (exponential)
  penalty_multiplier <- 1.0
  for (principle in principles_state$principles) {
    if (any(action_tags %in% principle$antithesis)) {
      k_penalty <- 5.0
      penalty_multiplier <- penalty_multiplier + exp(k_penalty * principle$conviction)
    }
  }
  total_cost <- total_cost * penalty_multiplier

  # 2. Alignment Discount (exponential)
  discount_multiplier <- 1.0
  for (tag in alignment_tags) {
    principle <- NULL
    for (p in principles_state$principles) {
      if (p$id == tag) { principle <- p; break }
    }
    if (!is.null(principle)) {
      k_discount <- 5.0
      discount <- exp(-k_discount * principle$conviction)
      discount_multiplier <- discount_multiplier * discount
    }
  }
  total_cost <- total_cost * discount_multiplier

  # 3. Compromise / Multi-Polar Constraint (linear partial penalty)
  if (compromise_factor > 0) {
    compromise_penalty <- 1.0 + (compromise_factor * 2.0)
    total_cost <- total_cost * compromise_penalty
  }

  return(total_cost)
}

# Retroactively harden principles upheld under load. Diminishing returns toward 1.0.
enforce_conviction <- function(principles_state, chosen_alignment_tags, load_factor) {
  for (i in seq_along(principles_state$principles)) {
    if (principles_state$principles[[i]]$id %in% chosen_alignment_tags) {
      current_conviction <- principles_state$principles[[i]]$conviction
      increase <- 0.1 * load_factor * (1.0 - current_conviction)
      principles_state$principles[[i]]$conviction <- min(1.0, current_conviction + increase)
    }
  }
  return(principles_state)
}
