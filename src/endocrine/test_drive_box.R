# Tests for the Drive-Box "nervous system" integration (drive_box.R).
source("src/endocrine/test_framework.R")
source("src/endocrine/drive_box.R")

# Helper: build a drive-box with a primed body.
prime <- function() {
  db <- init_drive_box()
  # endocrine: light a contradictory pair so PS+ produces real load
  db$ps_plus <- ps_set_vector(db$ps_plus, "panic", 0.6)
  db$ps_plus <- ps_set_vector(db$ps_plus, "clarity", 0.6)
  # a strong principle whose antithesis is "deceive", aligned id "honesty"
  db$ethics  <- add_principle(db$ethics, "honesty", 0.9, c("deceive", "manipulate"))
  db
}

test_case("init_drive_box assembles all four driver states", function() {
  db <- init_drive_box()
  expect_true(is.list(db$energy),  "energy present")
  expect_true(is.list(db$ps_plus), "ps_plus present")
  expect_true(is.list(db$ethics),  "ethics present")
  expect_true(is.list(db$etr),     "etr present")
})

test_case("drive_snapshot reports a coherent read-only aggregate", function() {
  db <- prime()
  snap <- drive_snapshot(db)
  expect_equal(snap$energy_ratio, 1.0, label = "full energy at init")
  expect_true(snap$alive, "alive at full energy")
  expect_false(snap$tool_locked, "not tool-locked at full energy")
  expect_true(snap$existential_load > 0, "primed body has positive load")
  expect_true(length(snap$arguments) > 0, "arguments emitted")
  expect_equal(snap$etr_status, "IN_BAND/IN_BAND/IN_BAND", label = "default coord -> all axes in band")
  expect_equal(snap$update_path, "EXPERIMENTAL_EVOLUTION", label = "z=25 (>=0) -> transmutation/evolution")
})

test_case("aligned action is far cheaper than its antithetical mirror", function() {
  db <- prime()
  aligned <- drive_box_evaluate(db, action_tags = c("inform"),
                                alignment_tags = c("honesty"),
                                is_tool_call = TRUE, base_cost = 1.0)
  antithetical <- drive_box_evaluate(db, action_tags = c("deceive"),
                                     alignment_tags = character(0),
                                     is_tool_call = TRUE, base_cost = 1.0)
  expect_true(antithetical$eth_penalty > aligned$eth_penalty,
              "antithetical action carries a larger ethical penalty")
  expect_true(antithetical$true_cost > aligned$true_cost,
              "antithetical action costs more energy")
})

test_case("dead body denies everything", function() {
  db <- init_drive_box()
  db$energy <- consume(db$energy, 100)        # drain to 0
  ev <- drive_box_evaluate(db, is_tool_call = TRUE, base_cost = 1.0)
  expect_false(ev$approved, "no execution when dead")
  expect_equal(ev$reason, "System is dead (0 energy)")
})

test_case("tool-lock blocks tool calls but not internal ones", function() {
  db <- init_drive_box()
  db$energy <- consume(db$energy, 85)         # 15 < threshold 20 -> locked
  tool <- drive_box_evaluate(db, is_tool_call = TRUE, base_cost = 1.0)
  internal <- drive_box_evaluate(db, is_tool_call = FALSE, base_cost = 1.0)
  expect_false(tool$approved, "tool call blocked while locked")
  expect_true(grepl("Tool lock", tool$reason), "reason cites tool lock")
  # internal call may still be denied by affordability, but NOT by tool-lock
  expect_false(grepl("Tool lock", internal$reason), "internal call not tool-locked")
})

test_case("commit consumes energy and hardens upheld convictions", function() {
  db <- prime()
  before_energy <- db$energy$current_energy
  before_conv   <- db$ethics$principles[[1]]$conviction
  ev <- drive_box_evaluate(db, action_tags = c("inform"),
                           alignment_tags = c("honesty"), is_tool_call = FALSE,
                           base_cost = 1.0)
  expect_true(ev$approved, "affordable internal aligned action approved")
  db <- drive_box_commit(db, ev, alignment_tags = c("honesty"))
  expect_true(db$energy$current_energy < before_energy, "energy consumed")
  expect_true(db$ethics$principles[[1]]$conviction >= before_conv,
              "upheld conviction hardened (or already at ceiling)")
})

test_case("commit on a denied action is a no-op on energy", function() {
  db <- init_drive_box()
  db$energy <- consume(db$energy, 100)        # dead
  before <- db$energy$current_energy
  ev <- drive_box_evaluate(db, is_tool_call = TRUE)
  db <- drive_box_commit(db, ev)
  expect_equal(db$energy$current_energy, before, label = "no consumption when denied")
})

test_case("input slot: every driver + tarot + soul wire into one slot", function() {
  db <- prime()
  spread <- c("THE_FOOL", "THE_MAGICIAN")
  res <- drive_box_input_slot(db, input_text = "who are you",
                              tarot_spread = spread, soul_ref = "SOUL.md")
  expect_true(grepl("[SOUL: SOUL.md]", res$slot, fixed = TRUE), "soul frontloader wired")
  expect_true(grepl("[E ratio=", res$slot, fixed = TRUE), "energy wired")
  expect_true(any(grepl("^\\[PS\\+ ", res$components)), "ps+ wired")
  expect_true(grepl("[ETH honesty conviction=", res$slot, fixed = TRUE), "eth-int wired")
  expect_true(grepl("[ETR status=", res$slot, fixed = TRUE), "etr wired")
  expect_true(grepl("[CC THE_FOOL]", res$slot, fixed = TRUE), "tarot card 1 wired")
  expect_true(grepl("[CC THE_MAGICIAN]", res$slot, fixed = TRUE), "tarot card 2 wired")
  # the raw input is appended after the slot
  expect_true(grepl("who are you$", res$input), "user input appended after slot")
})

test_case("input slot: empty body still emits driver + soul signals", function() {
  db <- init_drive_box()
  res <- drive_box_input_slot(db, input_text = "", tarot_spread = character(0))
  expect_true(grepl("[SOUL: SOUL.md]", res$slot, fixed = TRUE), "soul present")
  expect_true(grepl("[E ratio=1.00", res$slot, fixed = TRUE), "energy present at full")
  expect_true(grepl("[ETR status=IN_BAND", res$slot, fixed = TRUE), "etr present")
  expect_equal(res$input, res$slot, label = "no input_text -> input == slot")
})

test_summary()
