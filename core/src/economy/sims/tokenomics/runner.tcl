namespace eval ::stomach {}

oo::class create ::stomach::TokenomicsRunner {
    variable runtime

    constructor {{runtime_cmd ""}} {
        if {$runtime_cmd ne ""} {
            set runtime $runtime_cmd
        } elseif {[info exists ::env(M3E_QUERY_BIN)]} {
            set runtime $::env(M3E_QUERY_BIN)
        } else {
            set runtime tokenomics_query
        }
    }

    method available {} {
        if {[file pathtype $runtime] eq "absolute"} {
            return [expr {[file exists $runtime] && [file executable $runtime]}]
        }
        expr {[auto_execok $runtime] ne ""}
    }

    method _horizon {horizon} {
        switch -- $horizon {
            current { return [list 0.0 current] }
            tick_hourly -
            hourly { return [list 0.000114077116 1h] }
            daily { return [list 0.002737850787 24h] }
            weekly { return [list 0.019164955510 7d] }
            monthly { return [list 0.082135523614 30d] }
            annual { return [list 1.0 1y] }
            five_year { return [list 5.0 5y] }
            default { error "unknown_horizon" }
        }
    }

    method _prediction_type {name} {
        set allowed {
            supply_trajectory inflation_rate staking_ratio velocity_estimate
            halving_impact treasury_runway utilization_rate
            liquidation_cascade_risk systemic_contagion_index
            optimal_yield_allocation
        }
        if {[lsearch -exact $allowed $name] < 0} {
            error "unknown_prediction_type"
        }
        return $name
    }

    method _number {payload key} {
        if {![dict exists $payload $key]} { error "on_chain_missing_$key" }
        set value [dict get $payload $key]
        if {![string is double -strict $value]} { error "on_chain_invalid_$key" }
        return [expr {double($value)}]
    }

    method _triple {payload key} {
        if {![dict exists $payload $key]} { error "on_chain_missing_$key" }
        set values [dict get $payload $key]
        if {[llength $values] != 3} { error "on_chain_invalid_$key" }
        set out {}
        foreach value $values {
            if {![string is double -strict $value] || $value < 0} {
                error "on_chain_invalid_$key"
            }
            lappend out [expr {double($value)}]
        }
        return $out
    }

    method _observations {history ticker} {
        set rows {}
        foreach datum $history {
            if {![dict exists $datum payload]} { continue }
            set payload [dict get $datum payload]
            if {![dict exists $payload token_ticker] ||
                [dict get $payload token_ticker] ne $ticker} {
                continue
            }
            set confidence [dict get $datum confidence]
            if {![string is double -strict $confidence]} {
                error "invalid_on_chain_confidence"
            }

            set apy [my _triple $payload yield_apy]
            set vol [my _triple $payload yield_vol]
            set row [list                 [dict get $datum timestamp]                 [my _number $payload total_minted]                 [my _number $payload circulating]                 [my _number $payload staked]                 [my _number $payload locked]                 [my _number $payload burned]                 [my _number $payload supplied]                 [my _number $payload borrowed]                 [my _number $payload collateral]                 [my _number $payload ltv]                 [my _number $payload treasury]                 [my _number $payload treasury_burn_rate]                 [my _number $payload velocity]                 [my _number $payload base_emission_rate]                 [my _number $payload halving_interval]                 [my _number $payload policy_time]                 [my _number $payload exposure_factor]                 [lindex $apy 0] [lindex $vol 0]                 [lindex $apy 1] [lindex $vol 1]                 [lindex $apy 2] [lindex $vol 2]                 [expr {double($confidence)}]]
            lappend rows $row
        }
        return $rows
    }

    method _parse_result {output} {
        set line ""
        foreach candidate [split [string trim $output] "\n"] {
            if {[string match "RESULT *" [string trim $candidate]]} {
                set line [string trim $candidate]
            }
        }
        if {$line eq ""} { error "invalid_tokenomics_output" }
        set fields [regexp -all -inline {[^[:space:]]+} $line]
        if {[llength $fields] != 11 || [lindex $fields 0] ne "RESULT"} {
            error "invalid_tokenomics_output"
        }
        set nums {}
        foreach value [lrange $fields 1 end] {
            if {![string is double -strict $value]} {
                error "invalid_tokenomics_output"
            }
            lappend nums [expr {double($value)}]
        }
        return $nums
    }

    method query_history {ticker prediction_type horizon history} {
        if {![my available]} { error "tokenomics_runtime_unavailable" }
        set prediction_type [my _prediction_type $prediction_type]
        lassign [my _horizon $horizon] horizon_years horizon_label
        set rows [my _observations $history $ticker]
        if {[llength $rows] < 2} { error "insufficient_on_chain_history" }

        set payload "[llength $rows]\n"
        foreach row $rows {
            append payload "[join $row { }]\n"
        }

        set output [exec $runtime $prediction_type $horizon_years << $payload]
        lassign [my _parse_result $output]             value lower upper confidence correctness certainty recent_shift             detail1 detail2 detail3

        if {$lower > $value || $value > $upper} {
            error "tokenomics_prediction_out_of_bounds"
        }
        foreach metric [list $confidence $correctness $certainty] {
            if {$metric < 0 || $metric > 10} {
                error "tokenomics_quality_out_of_range"
            }
        }

        set result [dict create             value $value             lower_bound $lower             upper_bound $upper             confidence $confidence             correctness $correctness             certainty $certainty             time_horizon $horizon_label             sim_type tokenomics_macro             token_ticker $ticker             recent_shift $recent_shift             prediction_type $prediction_type             calibration_sources on_chain_event             state_estimator kalman             timestamp [clock seconds]]

        if {$prediction_type eq "optimal_yield_allocation"} {
            dict set result allocation_weights [join [list $detail1 $detail2 $detail3] ,]
        }
        return $result
    }
}
