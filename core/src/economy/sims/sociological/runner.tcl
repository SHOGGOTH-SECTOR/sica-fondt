namespace eval ::stomach {}

oo::class create ::stomach::SociologicalRunner {
    variable engine runtime populations epochs

    constructor {engine_path {runtime_cmd eclipse}} {
        set engine [file normalize $engine_path]
        set runtime $runtime_cmd
        set populations {}
        set epochs {}
    }

    method available {} {
        expr {[file exists $engine] && [auto_execok $runtime] ne ""}
    }

    method _clamp {x lo hi} {
        if {$x < $lo} { return $lo }
        if {$x > $hi} { return $hi }
        return $x
    }

    method _fmt {x} {
        if {![string is double -strict $x]} { error "invalid_numeric_state" }
        format %.17g [expr {double($x)}]
    }

    method _list_fmt {xs} {
        set out {}
        foreach x $xs { lappend out [my _fmt $x] }
        return [format {[%s]} [join $out ,]]
    }

    method _prediction_type {name} {
        set allowed {
            sentiment_index herd_threshold strategy_distribution
            cascade_probability coordination_stability opinion_cluster_count
            pump_dump_phase mfg_equilibrium_stability narrative_regime
        }
        if {[lsearch -exact $allowed $name] < 0} { error "unknown_prediction_type" }
        return $name
    }

    method _horizon {name} {
        switch -- $name {
            current { return [list current current] }
            tick_hourly -
            hourly { return [list hourly 1h] }
            daily { return [list daily 24h] }
            weekly { return [list weekly 7d] }
            monthly { return [list monthly 30d] }
            annual { return [list annual 1y] }
            five_year { return [list five_year 5y] }
            default { error "unknown_horizon" }
        }
    }

    method _filter_prices {history ticker} {
        set out {}
        foreach datum $history {
            if {![dict exists $datum payload]} { continue }
            set p [dict get $datum payload]
            if {[catch {dict get $p token_ticker} token] || $token ne $ticker} { continue }
            if {[catch {dict get $p price} price] ||
                ![string is double -strict $price] || $price <= 0} { continue }
            lappend out [dict create                 price [expr {double($price)}]                 timestamp [dict get $datum timestamp]                 confidence [dict get $datum confidence]]
        }
        return $out
    }

    method _filter_social {history ticker} {
        set out {}
        foreach datum $history {
            if {![dict exists $datum payload]} { continue }
            set p [dict get $datum payload]
            if {[catch {dict get $p token_ticker} token] || $token ne $ticker} { continue }
            if {[catch {dict get $p sentiment} sentiment] ||
                ![string is double -strict $sentiment]} { continue }
            set engagement 0.5
            if {[dict exists $p engagement] &&
                [string is double -strict [dict get $p engagement]]} {
                set engagement [dict get $p engagement]
            }
            set source_type unknown
            if {[dict exists $p source_type]} { set source_type [dict get $p source_type] }
            lappend out [dict create                 sentiment [my _clamp [expr {double($sentiment)}] -1.0 1.0]                 engagement [my _clamp [expr {double($engagement)}] 0.0 1.0]                 source_type $source_type                 timestamp [dict get $datum timestamp]                 confidence [dict get $datum confidence]]
        }
        return $out
    }

    method _weighted_social {social} {
        set sumw 0.0
        set sums 0.0
        set sume 0.0
        foreach d $social {
            set c [my _clamp [expr {double([dict get $d confidence])}] 0.0 10.0]
            set e [dict get $d engagement]
            set w [expr {max(0.05,$e) * max(0.1,$c/10.0)}]
            set s [dict get $d sentiment]
            set sumw [expr {$sumw+$w}]
            set sums [expr {$sums+$w*$s}]
            set sume [expr {$sume+$w*$e}]
        }
        if {$sumw <= 0} { error "invalid_social_weights" }
        set mean [expr {$sums/$sumw}]
        set exposure [expr {$sume/$sumw}]
        set var 0.0
        foreach d $social {
            set c [my _clamp [expr {double([dict get $d confidence])}] 0.0 10.0]
            set e [dict get $d engagement]
            set w [expr {max(0.05,$e) * max(0.1,$c/10.0)}]
            set delta [expr {[dict get $d sentiment]-$mean}]
            set var [expr {$var+$w*$delta*$delta}]
        }
        set dispersion [expr {sqrt($var/$sumw)}]
        return [list             [my _clamp $mean -1.0 1.0]             [my _clamp $dispersion 0.0 1.0]             [my _clamp $exposure 0.0 1.0]]
    }

    method _price_stats {prices} {
        set first [dict get [lindex $prices 0] price]
        set last [dict get [lindex $prices end] price]
        set shift [expr {$last/$first-1.0}]
        set returns {}
        set spacings {}
        for {set i 1} {$i < [llength $prices]} {incr i} {
            set a [lindex $prices [expr {$i-1}]]
            set b [lindex $prices $i]
            set pa [dict get $a price]
            set pb [dict get $b price]
            lappend returns [expr {log($pb/$pa)}]
            set ta [dict get $a timestamp]
            set tb [dict get $b timestamp]
            if {[string is double -strict $ta] &&
                [string is double -strict $tb] && $tb > $ta} {
                lappend spacings [expr {double($tb)-double($ta)}]
            }
        }
        set vol 0.0
        if {[llength $returns] >= 2} {
            set total 0.0
            foreach x $returns { set total [expr {$total+$x}] }
            set mean [expr {$total/double([llength $returns])}]
            set ss 0.0
            foreach x $returns { set ss [expr {$ss+($x-$mean)*($x-$mean)}] }
            set sd [expr {sqrt($ss/double([llength $returns]-1))}]
            set dt 86400.0
            if {[llength $spacings]} {
                set sumdt 0.0
                foreach x $spacings { set sumdt [expr {$sumdt+$x}] }
                set dt [expr {$sumdt/double([llength $spacings])}]
            }
            if {$dt <= 0} { set dt 86400.0 }
            set vol [expr {$sd*sqrt(31536000.0/$dt)}]
        }
        return [list             [my _clamp $shift -1.0 1.0]             [my _clamp $vol 0.0001 1.0]]
    }

    method _normalize {weights} {
        set total 0.0
        foreach w $weights { set total [expr {$total+max(0.0,$w)}] }
        if {$total <= 0} { error "invalid_population_weights" }
        set out {}
        foreach w $weights { lappend out [expr {max(0.0,$w)/$total}] }
        return $out
    }

    method _shares {sentiment volatility exposure} {
        set a [expr {abs($sentiment)}]
        set pos [expr {max(0.0,$sentiment)}]
        return [my _normalize [list             [expr {0.20+0.30*$a+0.15*$exposure}]             [expr {0.15+0.25*(1.0-$a)}]             [expr {0.10+0.25*$volatility}]             [expr {0.25+0.25*(1.0-$volatility)}]             [expr {0.05+0.25*$pos*$exposure}]]]
    }

    method _pump_shares {sentiment exposure} {
        set manip [expr {0.10+0.25*max(0.0,$sentiment)*$exposure}]
        set analyst [expr {0.15+0.10*$exposure}]
        set normal [expr {max(0.10,1.0-$analyst-$manip)}]
        return [my _normalize [list $normal $analyst $manip]]
    }

    method _mean_confidence {items} {
        if {![llength $items]} { return 0.0 }
        set total 0.0
        foreach d $items { set total [expr {$total+double([dict get $d confidence])}] }
        my _clamp [expr {$total/double([llength $items])}] 0.0 10.0
    }

    method _walk_forward_correctness {prices social} {
        set correct 0.0
        set total_weight 0.0
        foreach event $social {
            set sentiment [dict get $event sentiment]
            if {abs($sentiment) < 0.10} { continue }
            set ts [dict get $event timestamp]
            if {![string is double -strict $ts]} { continue }

            set before ""
            set after ""
            foreach point $prices {
                set pts [dict get $point timestamp]
                if {![string is double -strict $pts]} { continue }
                if {$pts <= $ts} {
                    set before $point
                    continue
                }
                set after $point
                break
            }
            if {$before eq "" || $after eq ""} { continue }

            set p0 [dict get $before price]
            set p1 [dict get $after price]
            set move [expr {$p1/$p0-1.0}]
            if {abs($move) < 0.0005} { continue }

            set predicted [expr {$sentiment > 0 ? 1 : -1}]
            set actual [expr {$move > 0 ? 1 : -1}]
            set engagement [dict get $event engagement]
            set confidence [my _clamp                 [expr {double([dict get $event confidence])}] 0.0 10.0]
            set weight [expr {max(0.05,$engagement)*max(0.1,$confidence/10.0)}]
            set total_weight [expr {$total_weight+$weight}]
            if {$predicted == $actual} {
                set correct [expr {$correct+$weight}]
            }
        }
        if {$total_weight <= 0.0} { return 5.0 }
        return [my _clamp [expr {10.0*$correct/$total_weight}] 0.0 10.0]
    }

    method _bandit_update {
        ticker initial_shares sentiment price_shift volatility exposure evidence_count
    } {
        if {![my available]} { error "eclipse_runtime_unavailable" }

        if {[dict exists $populations $ticker]} {
            set shares [dict get $populations $ticker]
        } else {
            set shares $initial_shares
        }

        set n [expr {max(1,int($evidence_count))}]
        set positive [expr {max(0.0,$sentiment)}]
        set aligned [expr {max(0.0,$sentiment*$price_shift)}]
        set payoffs [list             [expr {0.75+1.20*$aligned+0.35*$exposure}]             [expr {0.80+0.60*abs($sentiment-$price_shift)}]             [expr {0.70+1.40*$volatility}]             [expr {1.15-0.65*$volatility}]             [expr {0.45+1.60*$positive*$exposure+0.80*max(0.0,$price_shift)}]]
        set reward_sums {}
        foreach payoff $payoffs {
            lappend reward_sums [expr {$payoff*$n}]
        }
        set counts [lrepeat 5 $n]
        set total [expr {5*$n}]

        set goal [format {
            bandit_replicator_step(%s,%s,%s,%d,0.6,0.25,[A,B,C,D,E],_),
            printf("BANDIT %%w %%w %%w %%w %%w%%n",[A,B,C,D,E])
        } [my _list_fmt $shares] [my _list_fmt $reward_sums]           [my _list_fmt $counts] $total]
        set output [exec $runtime -b $engine -e $goal]
        if {![regexp {BANDIT[[:space:]]+([-+0-9.eE]+)[[:space:]]+([-+0-9.eE]+)[[:space:]]+([-+0-9.eE]+)[[:space:]]+([-+0-9.eE]+)[[:space:]]+([-+0-9.eE]+)}                 $output -> a b cc d e]} {
            error "invalid_bandit_output"
        }
        set next [my _normalize [list             [expr {double($a)}] [expr {double($b)}] [expr {double($cc)}]             [expr {double($d)}] [expr {double($e)}]]]
        dict set populations $ticker $next

        set epoch 1
        if {[dict exists $epochs $ticker]} {
            set epoch [expr {[dict get $epochs $ticker]+1}]
        }
        dict set epochs $ticker $epoch
        return [list $next $epoch]
    }

    method _mfg_stability {shares} {
        if {![my available]} { error "eclipse_runtime_unavailable" }
        set density [my _list_fmt $shares]
        set goal [format {
            mfg_equilibrium(500,%s,0.12,0.08,0.35,60,_,_,S,_),
            printf("MFG %%w%%n",[S])
        } $density]
        set output [exec $runtime -b $engine -e $goal]
        if {![regexp {MFG[[:space:]]+([-+0-9.eE]+)} $output -> value] ||
            ![string is double -strict $value]} {
            error "invalid_mfg_output"
        }
        return [my _clamp [expr {double($value)}] 0.0 1.0]
    }

    method _prediction {prediction_type state horizon_atom} {
        if {![my available]} { error "eclipse_runtime_unavailable" }
        set type [my _prediction_type $prediction_type]
        set goal [format {
            sociological_prediction(%s,%s,%s,V,L,U,Label),
            printf("RESULT %%w %%w %%w %%w%%n",[V,L,U,Label])
        } $type $state $horizon_atom]
        set output [exec $runtime -b $engine -e $goal]
        if {![regexp {RESULT[[:space:]]+([-+0-9.eE]+)[[:space:]]+([-+0-9.eE]+)[[:space:]]+([-+0-9.eE]+)[[:space:]]+([^[:space:]]+)}                 $output -> value lower upper label]} {
            error "invalid_sociological_output"
        }
        foreach x [list $value $lower $upper] {
            if {![string is double -strict $x]} { error "invalid_sociological_output" }
        }
        return [dict create             value [expr {double($value)}]             lower [expr {double($lower)}]             upper [expr {double($upper)}]             label $label]
    }

    method query_history {ticker prediction_type horizon price_history social_history} {
        if {![my available]} { error "eclipse_runtime_unavailable" }
        set prices [my _filter_prices $price_history $ticker]
        set social [my _filter_social $social_history $ticker]
        if {[llength $social] < 3} { error "insufficient_social_history" }
        if {[llength $prices] < 3} { error "insufficient_price_history" }

        lassign [my _horizon $horizon] horizon_atom horizon_label
        lassign [my _weighted_social $social] sentiment dispersion exposure
        lassign [my _price_stats $prices] price_shift volatility
        set initial_shares [my _shares $sentiment $volatility $exposure]
        lassign [my _bandit_update             $ticker $initial_shares $sentiment $price_shift             $volatility $exposure [llength $social]] shares population_epoch
        set pump_shares [my _pump_shares $sentiment $exposure]
        set stability [my _mfg_stability $shares]

        set opinions {}
        foreach d $social {
            lappend opinions [my _clamp [expr {([dict get $d sentiment]+1.0)/2.0}] 0.0 1.0]
        }
        set state [format {state(%s,%s,%s,%s,%s,%s,%s,%s,%s)}             [my _fmt $sentiment]             [my _fmt $dispersion]             [my _fmt $price_shift]             [my _fmt $volatility]             [my _fmt $exposure]             [my _list_fmt $shares]             [my _list_fmt $pump_shares]             [my _fmt $stability]             [my _list_fmt $opinions]]

        set native [my _prediction $prediction_type $state $horizon_atom]
        set value [dict get $native value]
        set lower [dict get $native lower]
        set upper [dict get $native upper]
        if {$lower > $value || $value > $upper} {
            error "sociological_prediction_out_of_bounds"
        }

        set social_conf [my _mean_confidence $social]
        set price_conf [my _mean_confidence $prices]
        set confidence [my _clamp [expr {0.65*$social_conf+0.35*$price_conf}] 0.0 10.0]
        set width [expr {abs($upper-$lower)}]
        set scale [expr {max(abs($value),1.0)}]
        set certainty [my _clamp [expr {$confidence/(1.0+$width/$scale)}] 0.0 10.0]

        # Empirical correctness: does signed aggregate social evidence predict
        # the next observed price move in walk-forward order?
        set correctness [my _walk_forward_correctness $prices $social]

        return [dict create             value $value             lower_bound $lower             upper_bound $upper             confidence $confidence             correctness $correctness             certainty $certainty             time_horizon $horizon_label             sim_type sociological             token_ticker $ticker             recent_shift $price_shift             prediction_type $prediction_type             label [dict get $native label]             calibration_sources rss_news,price_tick             population_model bandit_replicator             population_epoch $population_epoch             population_shares [join $shares ,]             timestamp [clock seconds]]
    }
}
