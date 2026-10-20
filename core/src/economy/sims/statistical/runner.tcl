namespace eval ::stomach {}

oo::class create ::stomach::StatisticalRunner {
    variable engine runtime

    constructor {engine_path {runtime_cmd Rscript}} {
        set engine [file normalize $engine_path]
        set runtime $runtime_cmd
    }

    method available {} {
        expr {[file exists $engine] && [auto_execok $runtime] ne ""}
    }

    method _number {json key} {
        set pattern [format {"%s"[[:space:]]*:[[:space:]]*(-?[0-9]+(?:\.[0-9]+)?(?:[eE][+-]?[0-9]+)?)} $key]
        if {![regexp -- $pattern $json -> value]} { error "prediction_missing_$key" }
        return $value
    }

    method _string {json key} {
        set pattern [format {"%s"[[:space:]]*:[[:space:]]*"([^"]*)"} $key]
        if {![regexp -- $pattern $json -> value]} { error "prediction_missing_$key" }
        return $value
    }

    method _optional_string {json key {default ""}} {
        set pattern [format {"%s"[[:space:]]*:[[:space:]]*"([^"]*)"} $key]
        if {![regexp -- $pattern $json -> value]} { return $default }
        return $value
    }

    method parse_prediction {json} {
        set p [dict create]
        foreach key {value lower_bound upper_bound confidence correctness certainty recent_shift} {
            dict set p $key [my _number $json $key]
        }
        foreach key {time_horizon sim_type token_ticker prediction_type calibration_sources} {
            dict set p $key [my _string $json $key]
        }
        foreach key {label detail} {
            set value [my _optional_string $json $key]
            if {$value ne ""} { dict set p $key $value }
        }
        dict set p timestamp [clock seconds]
        return $p
    }

    method query_typed {
        prices ticker prediction_type horizon
        {paths 4000} {seed 1} {dt 0.0027397260273972603}
        {pool_prices {}} {pool_liquidity {}}
    } {
        if {![my available]} { error "r_runtime_unavailable" }
        if {[llength $prices] < 80} { error "insufficient_price_history" }
        if {![regexp {^[A-Za-z0-9_.:-]+$} $ticker]} { error "invalid_ticker" }
        if {[lsearch -exact {
            price_forecast volatility_surface var_calculation correlation_matrix
            regime_state rough_vol_estimate jump_intensity
        } $prediction_type] < 0} { error "unknown_prediction_type" }
        if {[lsearch -exact {current tick_hourly daily weekly monthly annual five_year} $horizon] < 0} {
            error "unknown_horizon"
        }
        if {$prediction_type eq "price_forecast" && $horizon eq "current"} {
            error "unknown_horizon"
        }
        if {![string is integer -strict $paths] || $paths < 100} { error "invalid_paths" }
        if {![string is integer -strict $seed]} { error "invalid_seed" }
        if {![string is double -strict $dt] || $dt <= 0} { error "invalid_dt" }

        set encoded {}
        foreach price $prices {
            if {![string is double -strict $price] || $price <= 0} { error "invalid_price" }
            lappend encoded [format %.17g $price]
        }
        set encoded_pool {}
        foreach price $pool_prices {
            if {![string is double -strict $price] || $price <= 0} { error "invalid_pool_price" }
            lappend encoded_pool [format %.17g $price]
        }
        set encoded_liquidity {}
        foreach liquidity $pool_liquidity {
            if {![string is double -strict $liquidity] || $liquidity < 0} { error "invalid_pool_liquidity" }
            lappend encoded_liquidity [format %.17g $liquidity]
        }
        if {[llength $encoded_pool] != [llength $encoded_liquidity] && [llength $encoded_liquidity] > 0} {
            error "pool_liquidity_length"
        }

        set payload [format             {"prices":[%s],"pool_prices":[%s],"pool_liquidity":[%s],"dt":%.17g,"token_ticker":"%s","prediction_type":"%s","horizon":"%s","paths":%d,"seed":%d}             [join $encoded ,] [join $encoded_pool ,] [join $encoded_liquidity ,]             $dt $ticker $prediction_type $horizon $paths $seed]

        set output [exec $runtime $engine << $payload]
        return [my parse_prediction $output]
    }

    method query {prices ticker horizon {paths 4000} {seed 1} {dt 0.0027397260273972603}} {
        return [my query_typed             $prices $ticker price_forecast $horizon $paths $seed $dt {} {}]
    }
}
