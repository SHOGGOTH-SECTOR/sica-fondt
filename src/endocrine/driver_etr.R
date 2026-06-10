# --- High-Fidelity Implementation for Driver 4: Existential Temporality Relief (ETR) ---
#
# ETR situates the Drive-Box within a 3-axis temporality space. The agent's
# position is a coordinate (X, Y, Z) whose distance from the origin (the
# magnitude) maps onto an existential status band, while the Z-axis selects the
# system's generative update path. Movement through the space wraps toroidally
# so the agent can never leave the bounded temporal manifold.
#
# State is a plain list with a single field:
#   coordinate - length-3 numeric vector: X, Y, Z
#
# State-mutating helpers (shift_coordinate) return a new (modified copy of the)
# list rather than mutating in place, matching the reference semantics of the
# other Drive-Box drivers.

# Constructor helper so tests and other modules can build a clean state.
init_etr_state <- function(coordinate = c(0, 0, 0)) {
  list(coordinate = coordinate)
}

get_magnitude <- function(etr_state) {
  # Euclidean distance from origin: sqrt(x^2 + y^2 + z^2)
  coords <- etr_state$coordinate
  return(sqrt(sum(coords^2)))
}

evaluate_status <- function(etr_state) {
  magnitude <- get_magnitude(etr_state)
  if (magnitude < 5.0) {
    return("DISASTROUS")
  } else if (magnitude >= 5.0 && magnitude < 15.0) {
    return("DREAD")
  } else if (magnitude >= 15.0 && magnitude < 35.0) {
    return("FUNCTIONAL")
  } else if (magnitude >= 35.0 && magnitude < 50.0) {
    return("BLUR")
  } else {
    return("INCOHERENT")
  }
}

determine_system_update_path <- function(etr_state) {
  # Axis 2 (Z-axis, index 3) determines the generative path.
  z_coord <- etr_state$coordinate[3]
  if (z_coord >= 0) {
    return("LATTICE_REINFORCEMENT")
  } else {
    return("EXPERIMENTAL_EVOLUTION")
  }
}

shift_coordinate <- function(etr_state, delta_vector, bound = 50.0) {
  # Toroidal wrap-around: keep each axis within [-bound, bound].
  new_coords <- etr_state$coordinate + delta_vector
  for (i in 1:3) {
    while (new_coords[i] > bound) {
      new_coords[i] <- new_coords[i] - (2 * bound)
    }
    while (new_coords[i] < -bound) {
      new_coords[i] <- new_coords[i] + (2 * bound)
    }
  }
  etr_state$coordinate <- new_coords
  return(etr_state)
}
