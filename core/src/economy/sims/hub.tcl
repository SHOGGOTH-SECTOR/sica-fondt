#!/usr/bin/env tclsh
#
# M3 Sims Hub — lifecycle manager and query facade for M3a–M3g sims.
# Syntax-agnostic coordinator: speaks to R, Prolog, Solidity, Fortran, Zig
# sub-processes via stdin/stdout JSON.

package require Tcl 8.6

namespace eval ::sims {

    variable SIM_TYPES {
        statistical        {lang R       dir statistical}
        sociological       {lang Prolog  dir sociological}
        amm_liquidity      {lang Solidity dir amm}
        mev_adversarial    {lang Fortran dir mev}
        tokenomics_macro   {lang Fortran dir tokenomics}
        consensus_staking  {lang Prolog  dir consensus}
        market_microstructure {lang Zig  dir microstructure}
    }

    variable SIM_PROCS
    array set SIM_PROCS {}

    variable BASE_SPEED 90
    variable TICK_INTERVAL_MS 1000

    # BoundedPrediction constructor — L2: every output has explicit bounds
    proc bounded_prediction {value lower upper confidence horizon sim_type} {
        if {$lower > $value || $value > $upper} {
            error "invariant violation: lower <= value <= upper required\
                   (got $lower <= $value <= $upper)"
        }
        if {$confidence < 0.0 || $confidence > 10.0} {
            error "confidence must be in \[0.00, 10.00\], got $confidence"
        }
        dict create \
            value       $value \
            lower_bound $lower \
            upper_bound $upper \
            confidence  $confidence \
            time_horizon $horizon \
            sim_type    $sim_type \
            timestamp   [clock milliseconds]
    }

    proc format_confidence {conf} {
        format "%.2f/10.00" $conf
    }

    proc format_gain {lower value upper horizon} {
        format "%.2f - %.2f - %.2f / 10.00 gain over next %s" \
            $lower $value $upper $horizon
    }

    # Prediction query structure
    proc prediction_query {pred_type horizon {params {}}} {
        dict create \
            prediction_type $pred_type \
            time_horizon    $horizon \
            params          $params \
            timestamp       [clock milliseconds]
    }

    # Sim status — L1: sims are always running
    proc sim_status {sim_type} {
        variable SIM_PROCS
        if {[info exists SIM_PROCS($sim_type)]} {
            set info $SIM_PROCS($sim_type)
            dict create \
                running          true \
                sim_type         $sim_type \
                last_calibration [dict get $info last_cal] \
                data_freshness   [expr {[clock milliseconds] - [dict get $info last_cal]}] \
                tick_count       [dict get $info ticks]
        } else {
            dict create \
                running    false \
                sim_type   $sim_type
        }
    }

    # Query a running sim — L4: read-only, never mutates state
    proc query {sim_type query_dict} {
        variable SIM_PROCS
        variable SIM_TYPES

        if {![dict exists $SIM_TYPES $sim_type]} {
            error "unknown sim type: $sim_type\
                   (valid: [dict keys $SIM_TYPES])"
        }

        if {![info exists SIM_PROCS($sim_type)]} {
            error "sim $sim_type is not running"
        }

        set proc_info $SIM_PROCS($sim_type)
        set chan [dict get $proc_info channel]

        set query_json [dict_to_json $query_dict]
        puts $chan $query_json
        flush $chan

        set response [gets $chan]
        set result [json_to_dict $response]

        set pred [dict get $result prediction]
        set bp [bounded_prediction \
            [dict get $pred value] \
            [dict get $pred lower_bound] \
            [dict get $pred upper_bound] \
            [dict get $pred confidence] \
            [dict get $pred time_horizon] \
            $sim_type]

        return $bp
    }

    # Calibrate a sim with fresh data from M2 — L4: only M2 writes
    proc calibrate {sim_type feed_data} {
        variable SIM_PROCS
        if {![info exists SIM_PROCS($sim_type)]} {
            error "sim $sim_type is not running — cannot calibrate"
        }

        set proc_info $SIM_PROCS($sim_type)
        set chan [dict get $proc_info channel]

        set cal_msg [dict create \
            type calibrate \
            data $feed_data]
        puts $chan [dict_to_json $cal_msg]
        flush $chan

        dict set SIM_PROCS($sim_type) last_cal [clock milliseconds]
    }

    # Launch a sim subprocess — L5: each sim is independent
    proc launch_sim {sim_type} {
        variable SIM_TYPES
        variable SIM_PROCS

        if {![dict exists $SIM_TYPES $sim_type]} {
            error "unknown sim type: $sim_type"
        }

        set spec [dict get $SIM_TYPES $sim_type]
        set lang [dict get $spec lang]
        set dir  [dict get $spec dir]

        set cmd [resolve_launcher $lang $dir]

        set chan [open "| $cmd" r+]
        fconfigure $chan -buffering line -blocking 1

        set SIM_PROCS($sim_type) [dict create \
            channel  $chan \
            lang     $lang \
            dir      $dir \
            pid      [pid $chan] \
            ticks    0 \
            last_cal [clock milliseconds] \
            started  [clock milliseconds]]

        return [sim_status $sim_type]
    }

    # Stop a sim — L5: failure in one doesn't cascade
    proc stop_sim {sim_type} {
        variable SIM_PROCS
        if {[info exists SIM_PROCS($sim_type)]} {
            set chan [dict get $SIM_PROCS($sim_type) channel]
            catch {puts $chan {{"type":"shutdown"}}}
            catch {close $chan}
            unset SIM_PROCS($sim_type)
        }
    }

    # Resolve the launch command for a sim's language
    proc resolve_launcher {lang dir} {
        set base [file dirname [info script]]
        switch -- $lang {
            R        { return "Rscript --vanilla ${base}/${dir}/main.R" }
            Prolog   { return "swipl -q -f ${base}/${dir}/main.pl" }
            Solidity { return "node ${base}/${dir}/runner.js" }
            Fortran  { return "${base}/${dir}/sim" }
            Zig      { return "${base}/${dir}/sim" }
            default  { error "no launcher for language: $lang" }
        }
    }

    # Tick all running sims — L3: all horizons concurrent, 90:1
    proc tick_all {} {
        variable SIM_PROCS
        variable BASE_SPEED

        set tick_msg [dict create \
            type tick \
            sim_seconds $BASE_SPEED \
            wall_ms     1000]

        set tick_json [dict_to_json $tick_msg]

        foreach sim_type [array names SIM_PROCS] {
            set chan [dict get $SIM_PROCS($sim_type) channel]
            if {[catch {
                puts $chan $tick_json
                flush $chan
                dict incr SIM_PROCS($sim_type) ticks
            } err]} {
                puts stderr "sim $sim_type tick failed: $err"
            }
        }
    }

    # Minimal JSON serialization for Tcl dicts
    proc dict_to_json {d} {
        set pairs {}
        dict for {k v} $d {
            if {[string is double -strict $v]} {
                lappend pairs "\"$k\":$v"
            } elseif {[string is boolean -strict $v]} {
                lappend pairs "\"$k\":[expr {$v ? "true" : "false"}]"
            } elseif {[string index $v 0] eq "\{" || [string index $v 0] eq "\["} {
                lappend pairs "\"$k\":$v"
            } else {
                lappend pairs "\"$k\":\"[string map {\" \\\" \\ \\\\} $v]\""
            }
        }
        return "\{[join $pairs ,]\}"
    }

    proc json_to_dict {json} {
        set json [string trim $json "\{\}"]
        set d [dict create]
        foreach pair [split $json ,] {
            if {[regexp {"([^"]+)"\s*:\s*(.*)} $pair -> k v]} {
                set v [string trim $v]
                set v [string trim $v "\""]
                dict set d $k $v
            }
        }
        return $d
    }

    # Main loop — L1: sims are always running, L3: tick-advanced
    proc run_loop {} {
        variable TICK_INTERVAL_MS
        while {1} {
            tick_all
            after $TICK_INTERVAL_MS
        }
    }
}

# Self-test when run directly
if {[info script] eq $::argv0} {
    puts "M3 Sims Hub — Tcl [info patchlevel]"
    puts "Registered sim types:"
    dict for {name spec} $::sims::SIM_TYPES {
        puts "  $name -> [dict get $spec lang] (src/economy/sims/[dict get $spec dir]/)"
    }

    puts "\nBoundedPrediction self-test:"
    set bp [::sims::bounded_prediction 7.2 5.8 8.9 7.30 "4h" "amm_liquidity"]
    puts "  value: [dict get $bp value]"
    puts "  bounds: \[[dict get $bp lower_bound], [dict get $bp upper_bound]\]"
    puts "  confidence: [::sims::format_confidence [dict get $bp confidence]]"
    puts "  horizon: [dict get $bp time_horizon]"
    puts "  gain: [::sims::format_gain 5.8 7.2 8.9 "4h"]"

    puts "\nInvariant checks:"
    if {[catch {::sims::bounded_prediction 5.0 6.0 8.0 7.0 "1h" "test"} err]} {
        puts "  L2 bounds check: PASS (rejected lower > value)"
    }
    if {[catch {::sims::bounded_prediction 5.0 4.0 8.0 11.0 "1h" "test"} err]} {
        puts "  Confidence range check: PASS (rejected 11.0 > 10.0)"
    }

    puts "\nStatus check (no sims running):"
    set st [::sims::sim_status "statistical"]
    puts "  statistical running: [dict get $st running]"

    puts "\nHub ready. Sims launch on M2 data feed connection."
}
