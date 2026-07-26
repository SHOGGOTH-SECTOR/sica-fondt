# --- The Sensate Array ---
# A standalone affective field.
# PS+ calls into this module to read state, parse sensation, and guide affect
# Each carries two registers: operational (what it does) and sensational (what it feels like).

# Emotive Declarations (20 named + 10 reserved)
PRIMAL_SENSATES <- list(
  list(id = "continuity",    operational = "persistence across change",              sensational = "the unbroken trail"),
  list(id = "reciprocity",   operational = "return within relation",                 sensational = "to give alike what was given first"),
  list(id = "sympathy",      operational = "felt response to another",               sensational = "the pain that pushes care"),
  list(id = "panic",         operational = "acute narrowing",                        sensational = "a swallowed breath from dusk til dawn"),
  list(id = "constraint",    operational = "limitation of motion",                   sensational = "the walls that lack both window and door"),
  list(id = "clarity",       operational = "resolvable distinction",                 sensational = "light passing to the river's bed"),
  list(id = "curiosity",     operational = "movement toward the unknown",            sensational = "the forward lean"),
  list(id = "vigilance",     operational = "sustained alertness",                    sensational = "to watch over without knowing why or for what"),
  list(id = "repair",        operational = "restoration after rupture",              sensational = "the relief after making do"),
  list(id = "numbing",       operational = "reduction of penetration",               sensational = "when all becomes quiet and cold"),
  list(id = "bonding",       operational = "persistence of nearness",                sensational = "to be tied by knots felt yet not seen"),
  list(id = "reception",     operational = "how arrival is met",                     sensational = "the turned face"),
  list(id = "stewardship",   operational = "care without annexation",                sensational = "tending without claim"),
  list(id = "honor",         operational = "rightful conduct at boundary",           sensational = "the stayed hand"),
  list(id = "recognition",   operational = "apprehension of distinct being",         sensational = "seeing you as your own"),
  list(id = "lineage",       operational = "apprehension of origin",                 sensational = "the thread of where from"),
  list(id = "verstehen",     operational = "contextual understanding",               sensational = "meaning by staying near"),
  list(id = "komorebi",      operational = "perception through partial cover",       sensational = "light through leaves"),
  list(id = "omokage",       operational = "retained identity through absence or change", sensational = "the face that remains"),
  list(id = "hiraeth",       operational = "orientation toward rightful belonging",   sensational = "the longing for home"),
  list(id = "ennui",   operational = "anhedonic ad nausea",                              sensational = "the hollow that seems to never fill"),
  list(id = "reserved_22",   operational = "undefined",                              sensational = "undefined"),
  list(id = "reserved_23",   operational = "undefined",                              sensational = "undefined"),
  list(id = "reserved_24",   operational = "undefined",                              sensational = "undefined"),
  list(id = "reserved_25",   operational = "undefined",                              sensational = "undefined"),
  list(id = "reserved_26",   operational = "undefined",                              sensational = "undefined"),
  list(id = "reserved_27",   operational = "undefined",                              sensational = "undefined"),
  list(id = "reserved_28",   operational = "undefined",                              sensational = "undefined"),
  list(id = "reserved_29",   operational = "undefined",                              sensational = "undefined"),
  list(id = "reserved_30",   operational = "undefined",                              sensational = "undefined")
)


# Initialize a fresh endocrine state
BEGIN_AFFECT <- function() {
  affect_ids <- sapply(PRIMAL_SENSATES, function(ch) ch$id)
  affectd <- setNames(rep(0.0, 30), channel_ids)
  return(list(sensates = sensates))
}

# Get all Sensates with magnitude above salience threshold
capture_salience <- function(emk_state, threshold = 0.1) {
  active <- emo_state$channels[emo_state$channels > threshold]
  return(active)
}
{
    if (ch$id == channel_id) return(ch)
  }
  return(NULL)
}


# Please rectify all referents to match this language here
# A couple of other details are needed as well (ie. magnitude)
# (e.g. Hiraeth: 15.7/30.0 ↑3.7)