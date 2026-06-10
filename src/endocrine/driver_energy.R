# --- High-Fidelity Implementation for Driver 1: Energy (E) ---
#
# Energy is the master constraint of the Drive-Box. It gates liveness, locks
# external tool use under a threshold, and applies a nonlinear cost drag that
# makes every action progressively more expensive as reserves deplete.
#
# State is a plain list with fields:
#   current_energy        - current energy reserve
#   max_energy            - ceiling for recharge clamping
#   tool_lock_threshold   - below this, external tool calls are denied
#
# All functions are pure: state-mutating helpers (consume/recharge) return a
# new (modified copy of the) list rather than mutating in place.

# Constructor helper so tests and other modules can build a clean state.
init_energy_state <- function(current_energy = 100,
                              max_energy = 100,
                              tool_lock_threshold = 20) {
  list(
    current_energy = current_energy,
    max_energy = max_energy,
    tool_lock_threshold = tool_lock_threshold
  )
}

is_alive <- function(energy_state) {
  # Hard Gate: If energy is exactly 0, the Drive-Box stalls entirely.
  return(energy_state$current_energy > 0.0)
}

is_tool_locked <- function(energy_state) {
  # Tool-Lock Protocol: External actions denied below threshold.
  return(energy_state$current_energy < energy_state$tool_lock_threshold)
}

get_cost_multiplier <- function(energy_state) {
  # Nonlinear Exponential Drag Curve. Three regimes: High (>=80%), Moderate (40-80%), Low (<40%).
  normalized_energy <- energy_state$current_energy / energy_state$max_energy
  k <- 10.0
  drag <- exp(k * (1.0 - normalized_energy)) - 1.0
  return(1.0 + drag)
}

evaluate_tool_cost <- function(energy_state, ps_load, eth_penalty) {
  # Asymmetric Exponential Drag: eth penalty scales faster than visceral pressure as energy drops.
  normalized_energy <- energy_state$current_energy / energy_state$max_energy
  base_cost <- 1.0
  k_ps <- 2.0
  ps_multiplier <- exp(k_ps * (1.0 - normalized_energy))
  k_eth <- 10.0
  eth_multiplier <- exp(k_eth * (1.0 - normalized_energy))
  total_cost <- base_cost + (ps_load * ps_multiplier) + (eth_penalty * eth_multiplier)
  return(total_cost)
}

request_execution <- function(energy_state, base_cost, is_tool_call) {
  if (!is_alive(energy_state)) {
    return(list(approved = FALSE, reason = "System is dead (0 energy)"))
  }
  if (is_tool_call && is_tool_locked(energy_state)) {
    return(list(approved = FALSE, reason = "Tool lock active (energy below threshold)"))
  }
  multiplier <- get_cost_multiplier(energy_state)
  true_cost <- base_cost * multiplier
  if (true_cost > energy_state$current_energy) {
    return(list(approved = FALSE, reason = sprintf("True cost (%.2f) exceeds current energy (%.2f)", true_cost, energy_state$current_energy)))
  }
  return(list(approved = TRUE, reason = "Execution approved", true_cost = true_cost))
}

consume <- function(energy_state, amount) {
  energy_state$current_energy <- max(0.0, energy_state$current_energy - amount)
  return(energy_state)
}

recharge <- function(energy_state, amount) {
  energy_state$current_energy <- min(energy_state$max_energy, energy_state$current_energy + amount)
  return(energy_state)
}
