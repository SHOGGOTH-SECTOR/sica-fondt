# --- Driver 2: Primal Sensates+ (PS+) ---
# The visceral driver of the Drive-Box. PS+ does not reason; it FEELS.
# It reads the endocrine array and the priors store, then emits arguments --
# weighted, embodied claims about reality -- never logical propositions.
#
# Foundation modules are sourced as-is (repo-root-relative paths).
source("core/src/endocrine/endocrine_array.R")
source("core/src/endocrine/priors.R")

# Initialize a fresh PS+ state: a clean endocrine array and an empty priors store.
init_ps_plus_state <- function() {
  return(list(
    endocrines = init_endocrine_state(),
    priors = init_priors_state()
  ))
}

# Ergonomic setter: set an endocrine channel magnitude on PS+ state.
# Delegates to the foundation's set_vector and returns the updated state.
ps_set_vector <- function(ps_plus_state, name, magnitude) {
  ps_plus_state$endocrines <- set_vector(ps_plus_state$endocrines, name, magnitude)
  return(ps_plus_state)
}

# Ergonomic wrapper: register a prior on PS+ state.
# Delegates to the foundation's add_prior and returns the updated state.
ps_add_prior <- function(ps_plus_state, id, type, salience, payload) {
  ps_plus_state$priors <- add_prior(ps_plus_state$priors, id, type, salience, payload)
  return(ps_plus_state)
}

# Evaluate Reality (the visceral way).
# Returns a list:
#   existential_load : numeric  -- aggregate felt pressure (base + friction + priors)
#   arguments        : list     -- embodied claim strings
#   is_logical       : FALSE    -- PS+ emits arguments, never logic
evaluate_reality <- function(ps_plus_state) {
  active_vectors <- get_active_vectors(ps_plus_state$endocrines)
  friction <- calculate_visceral_friction(ps_plus_state$endocrines)
  base_load <- sum(active_vectors)
  arguments <- list()
  for (name in names(active_vectors)) {
    ch_def <- get_channel_def(name)
    if (!is.null(ch_def)) {
      arguments[[length(arguments) + 1]] <- sprintf("VISCERAL [%s]: %s (%.2f)", name, ch_def$sensational, active_vectors[[name]])
    }
  }
  if (friction > 0.5) {
    arguments[[length(arguments) + 1]] <- sprintf("SYSTEMIC HEAT: Contradictory vectors detected (Friction: %.2f)", friction)
  }
  active_priors <- get_top_active_priors(ps_plus_state$priors, threshold = 0.8)
  prior_load <- 0.0
  for (prior in active_priors) {
    prior_load <- prior_load + (prior$salience * 10.0)
    arguments[[length(arguments) + 1]] <- sprintf("PRIOR [%s]: %s", prior$type, prior$payload)
  }
  existential_load <- base_load + friction + prior_load
  return(list(
    existential_load = existential_load,
    arguments = arguments,
    is_logical = FALSE
  ))
}
