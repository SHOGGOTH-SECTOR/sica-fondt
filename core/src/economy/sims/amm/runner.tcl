namespace eval ::stomach {}

oo::class create ::stomach::AMMRunner {
    variable runtime rpc address

    constructor {} {
        set runtime cast
        set rpc [expr {[info exists ::env(AMM_RPC_URL)] ? $::env(AMM_RPC_URL) : ""}]
        set address [expr {[info exists ::env(AMM_QUERY_ADDRESS)] ? $::env(AMM_QUERY_ADDRESS) : ""}]
    }

    method available {} {
        expr {
            [auto_execok $runtime] ne "" &&
            $rpc ne "" &&
            [regexp {^0x[0-9A-Fa-f]{40}$} $address]
        }
    }

    method _prediction_index {prediction_type} {
        set names {
            impermanent_loss
            pool_return
            optimal_range
            slippage_estimate
            lp_withdrawal_threshold
        }
        set i [lsearch -exact $names $prediction_type]
        if {$i < 0} { error "unknown_prediction_type" }
        return $i
    }

    method _horizon {horizon} {
        switch -- $horizon {
            tick_hourly { return [list 3600 1h] }
            daily { return [list 86400 24h] }
            weekly { return [list 604800 7d] }
            monthly { return [list 2592000 30d] }
            annual { return [list 31536000 1y] }
            five_year { return [list 157680000 5y] }
            default { error "unknown_horizon" }
        }
    }

    method _decimal_wad {value} {
        set s [string trim $value]
        if {[regexp {^([+-]?)([0-9]+)(?:\.([0-9]*))?$} $s -> sign whole frac]} {
            if {$frac eq ""} { set frac "" }
            set frac [string range "${frac}000000000000000000" 0 17]
            set n [expr {$whole * 1000000000000000000 + $frac}]
            if {$sign eq "-"} { set n [expr {-$n}] }
            return $n
        }
        if {![string is double -strict $s]} { error "invalid_decimal" }
        return [format %.0f [expr {double($s) * 1.0e18}]]
    }

    method _wad_double {value} {
        expr {double($value) / 1.0e18}
    }

    method _scalar {function_name prediction_index raw} {
        if {![my available]} { error "amm_runtime_unavailable" }
        if {[llength $raw] != 11} { error "invalid_amm_state" }
        set arr "\[[join $raw ,]\]"
        set sig "${function_name}(uint8,uint256\[11\])(int256)"
        set output [exec $runtime call --rpc-url $rpc $address $sig $prediction_index $arr]
        set output [string trim $output]
        if {![regexp {^-?[0-9]+} $output value]} {
            error "invalid_amm_output"
        }
        return $value
    }

    method _raw_prediction {prediction_type raw} {
        set kind [my _prediction_index $prediction_type]
        set value [my _scalar queryValue $kind $raw]
        set lower [my _scalar queryLower $kind $raw]
        set upper [my _scalar queryUpper $kind $raw]
        if {$lower > $value || $value > $upper} { error "amm_prediction_out_of_bounds" }
        return [dict create value_wad $value lower_wad $lower upper_wad $upper]
    }

    method _filter_prices {history ticker} {
        set out {}
        foreach datum $history {
            if {![dict exists $datum payload]} { continue }
            set payload [dict get $datum payload]
            if {[catch {dict get $payload token_ticker} token] || $token ne $ticker} { continue }
            if {[catch {dict get $payload price} price] || ![string is double -strict $price] || $price <= 0} { continue }
            lappend out [dict create                 price $price                 timestamp [dict get $datum timestamp]                 confidence [dict get $datum confidence]]
        }
        return $out
    }

    method _filter_pools {history ticker} {
        set out {}
        foreach datum $history {
            if {![dict exists $datum payload]} { continue }
            set payload [dict get $datum payload]
            if {[catch {dict get $payload token_ticker} token] || $token ne $ticker} { continue }
            if {[catch {dict get $payload reserve0} r0] ||
                [catch {dict get $payload reserve1} r1] ||
                ![string is double -strict $r0] ||
                ![string is double -strict $r1] ||
                $r0 <= 0 || $r1 <= 0} { continue }
            lappend out $datum
        }
        return $out
    }

    method _volatility {prices} {
        if {[llength $prices] < 3} { return 0.2 }
        set returns {}
        set spacings {}
        for {set i 1} {$i < [llength $prices]} {incr i} {
            set a [lindex $prices [expr {$i-1}]]
            set b [lindex $prices $i]
            set pa [dict get $a price]
            set pb [dict get $b price]
            if {$pa > 0 && $pb > 0} {
                lappend returns [expr {log(double($pb)/double($pa))}]
            }
            set ta [dict get $a timestamp]
            set tb [dict get $b timestamp]
            if {[string is double -strict $ta] && [string is double -strict $tb] && $tb > $ta} {
                lappend spacings [expr {double($tb)-double($ta)}]
            }
        }
        if {[llength $returns] < 2} { return 0.2 }
        set sum 0.0
        foreach x $returns { set sum [expr {$sum+$x}] }
        set mean [expr {$sum/double([llength $returns])}]
        set ss 0.0
        foreach x $returns { set ss [expr {$ss+($x-$mean)*($x-$mean)}] }
        set sd [expr {sqrt($ss/double([llength $returns]-1))}]
        set dt 86400.0
        if {[llength $spacings]} {
            set total 0.0
            foreach x $spacings { set total [expr {$total+$x}] }
            set dt [expr {$total/double([llength $spacings])}]
        }
        if {$dt <= 0} { set dt 86400.0 }
        set annualized [expr {$sd*sqrt(31536000.0/$dt)}]
        if {$annualized < 0.0001} { set annualized 0.0001 }
        if {$annualized > 5.0} { set annualized 5.0 }
        return $annualized
    }

    method _uncertainty_bps {price_conf pool_conf} {
        set c [expr {(double($price_conf)+double($pool_conf))/2.0}]
        if {$c < 0} { set c 0 }
        if {$c > 10} { set c 10 }
        set bps [expr {round(100.0 + (10.0-$c)*200.0)}]
        if {$bps < 50} { set bps 50 }
        if {$bps > 2500} { set bps 2500 }
        return $bps
    }

    method _state_from_pool {pool price_ratio external_price volatility uncertainty_bps horizon_seconds} {
        set payload [dict get $pool payload]
        set x [my _decimal_wad [dict get $payload reserve0]]
        set y [my _decimal_wad [dict get $payload reserve1]]
        set fee 30
        if {[dict exists $payload fee_bps]} { set fee [dict get $payload fee_bps] }
        if {![string is integer -strict $fee] || $fee < 0 || $fee >= 10000} { error "invalid_pool_fee" }

        set volume 0.0
        if {[dict exists $payload volume]} { set volume [dict get $payload volume] }
        set tvl [expr {double([dict get $payload reserve0]) + double([dict get $payload reserve1])}]
        if {[dict exists $payload tvl]} { set tvl [dict get $payload tvl] }
        if {![string is double -strict $tvl] || $tvl <= 0} { error "invalid_pool_tvl" }

        set trade [expr {double([dict get $payload reserve0]) * 0.01}]
        if {[dict exists $payload trade_size]} { set trade [dict get $payload trade_size] }
        if {![string is double -strict $trade] || $trade <= 0} { error "invalid_trade_size" }

        return [list             $x             $y             $fee             [my _decimal_wad $volume]             [my _decimal_wad $tvl]             [my _decimal_wad $price_ratio]             [my _decimal_wad $external_price]             [my _decimal_wad $volatility]             [my _decimal_wad $trade]             $uncertainty_bps             $horizon_seconds]
    }

    method _correctness {pools price_ratio external_price volatility uncertainty_bps horizon_seconds} {
        set n [llength $pools]
        if {$n < 2} { return 5.0 }
        set start [expr {max(0,$n-4)}]
        set hits 0
        set total 0
        for {set i $start} {$i < $n-1} {incr i} {
            set prev [my _state_from_pool                 [lindex $pools $i] $price_ratio $external_price $volatility                 $uncertainty_bps $horizon_seconds]
            set next [my _state_from_pool                 [lindex $pools [expr {$i+1}]] $price_ratio $external_price $volatility                 $uncertainty_bps $horizon_seconds]
            set pred [my _raw_prediction slippage_estimate $prev]
            set actualKind [my _prediction_index slippage_estimate]
            set actual [my _scalar queryValue $actualKind $next]
            if {$actual >= [dict get $pred lower_wad] && $actual <= [dict get $pred upper_wad]} {
                incr hits
            }
            incr total
        }
        if {$total == 0} { return 5.0 }
        return [expr {10.0*double($hits)/double($total)}]
    }

    method query_history {ticker prediction_type horizon price_history pool_history} {
        if {![my available]} { error "amm_runtime_unavailable" }
        set prices [my _filter_prices $price_history $ticker]
        set pools [my _filter_pools $pool_history $ticker]
        if {![llength $pools]} { error "insufficient_pool_history" }
        if {[llength $prices] < 2} { error "insufficient_price_history" }

        lassign [my _horizon $horizon] horizon_seconds horizon_label
        set first [lindex $prices 0]
        set last [lindex $prices end]
        set first_price [dict get $first price]
        set last_price [dict get $last price]
        set price_ratio [expr {double($last_price)/double($first_price)}]
        set volatility [my _volatility $prices]
        set pool_conf [dict get [lindex $pools end] confidence]
        set price_conf [dict get $last confidence]
        set uncertainty_bps [my _uncertainty_bps $price_conf $pool_conf]

        set raw [my _state_from_pool             [lindex $pools end] $price_ratio $last_price $volatility             $uncertainty_bps $horizon_seconds]
        set native [my _raw_prediction $prediction_type $raw]
        set value [my _wad_double [dict get $native value_wad]]
        set lower [my _wad_double [dict get $native lower_wad]]
        set upper [my _wad_double [dict get $native upper_wad]]

        set confidence [expr {(double($price_conf)+double($pool_conf))/2.0}]
        if {$confidence < 0} { set confidence 0 }
        if {$confidence > 10} { set confidence 10 }
        set correctness [my _correctness             $pools $price_ratio $last_price $volatility             $uncertainty_bps $horizon_seconds]
        set denom [expr {max(abs($value),1.0e-9)}]
        set relative_width [expr {abs($upper-$lower)/$denom}]
        set certainty [expr {$confidence/(1.0+min($relative_width,5.0))}]
        if {$certainty < 0} { set certainty 0 }
        if {$certainty > 10} { set certainty 10 }

        set recent_shift [expr {double($last_price)/double($first_price)-1.0}]
        return [dict create             value $value             lower_bound $lower             upper_bound $upper             confidence $confidence             correctness $correctness             certainty $certainty             time_horizon $horizon_label             sim_type amm_liquidity             token_ticker $ticker             recent_shift $recent_shift             prediction_type $prediction_type             calibration_sources price_tick,dex_pool_state             timestamp [clock seconds]]
    }
}
