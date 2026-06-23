# --- Priors: Records of Salient Spikes in Relativity ---
# Standalone module for traumatic and rewarding memory records.
# PS+ calls into this module to retrieve active priors that inject high-salience arguments.

# Initialize a fresh priors state
init_priors_state <- function() {
  return(list(records = list()))
}

# Add a prior record
# type: "TRAUMA" or "TRIUMPH"
# salience: 0.0 to 1.0 (how strongly this prior activates when matched)
# payload: the argument string injected into PS+ load when active
add_prior <- function(priors_state, id, type, salience, payload) {
  if (!(type %in% c("TRAUMA", "TRIUMPH"))) {
    stop(sprintf("Invalid prior type: %s. Must be TRAUMA or TRIUMPH.", type))
  }

  new_prior <- list(
    id = id,
    type = type,
    salience = max(0.0, min(1.0, salience)),
    payload = payload,
    activation_count = 0L
  )

  priors_state$records[[length(priors_state$records) + 1]] <- new_prior
  return(priors_state)
}

# Get priors above a salience threshold, sorted descending by salience
get_top_active_priors <- function(priors_state, threshold = 0.8) {
  active <- Filter(function(p) p$salience >= threshold, priors_state$records)

  if (length(active) > 0) {
    active <- active[order(sapply(active, function(p) p$salience), decreasing = TRUE)]
  }

  return(active)
}

# Activate a prior (increment its activation count for tracking)
activate_prior <- function(priors_state, prior_id) {
  for (i in seq_along(priors_state$records)) {
    if (priors_state$records[[i]]$id == prior_id) {
      priors_state$records[[i]]$activation_count <- priors_state$records[[i]]$activation_count + 1L
      break
    }
  }
  return(priors_state)
}

# Decay salience of a prior over time (for future use in migration cycles)
decay_prior <- function(priors_state, prior_id, decay_rate = 0.01) {
  for (i in seq_along(priors_state$records)) {
    if (priors_state$records[[i]]$id == prior_id) {
      current <- priors_state$records[[i]]$salience
      priors_state$records[[i]]$salience <- max(0.0, current - decay_rate)
      break
    }
  }
  return(priors_state)
}
