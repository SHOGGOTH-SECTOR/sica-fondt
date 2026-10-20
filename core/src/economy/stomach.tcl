# M0 stomach/economy organ composition for sica-fondt.
# The stomach is an OUTER organ. Market execution remains simulation-only here;
# M3's native engines are registered as subordinate simulation processes.
namespace eval ::stomach { variable version 0.2; variable root }
set __stomach_dir [file dirname [file normalize [info script]]]
set ::stomach::root $__stomach_dir
foreach __stomach_file {
    traders.tcl wallets.tcl sae.tcl conductor.tcl feeds.tcl
    sims/registry.tcl sims/scheduler.tcl sims/hub.tcl
    sims/statistical/runner.tcl marketplace.tcl
} {
    source [file join $__stomach_dir $__stomach_file]
}
unset __stomach_file

oo::class create ::stomach::Economy {
    variable traders wallets sae conductor feeds sims registry clock statistical_runner market taxes
    constructor {args} {
        set cap 256
        if {[llength $args] % 2 != 0} { error "options must be key/value pairs" }
        foreach {k v} $args {
            switch -- $k {
                -history_cap { set cap $v }
                default { error "unknown option $k" }
            }
        }
        set traders [::stomach::Traders new]
        set wallets [::stomach::Wallets new]
        set sae [::stomach::SAEMonitor new]
        set conductor [::stomach::Conductor new $traders]
        set feeds [::stomach::Feeds new $cap]
        set sims [::stomach::SimsHub new]
        set registry [::stomach::EngineRegistry new [file join $::stomach::root sims]]
        set clock [::stomach::HorizonClock new]
        $clock start
        set statistical_runner [::stomach::StatisticalRunner new             [file join $::stomach::root sims statistical engine.R]]
        set market [::stomach::Marketplace new $traders $wallets $conductor $sae $sims]
        set taxes {}
    }
    destructor {
        foreach obj [list $market $statistical_runner $clock $registry $sims $feeds $conductor $sae $wallets $traders] {
            catch {$obj destroy}
        }
    }
    method register_trader {id specialization} { return [$traders register $id $specialization] }
    method bind_wallet {wallet_id trader_id daily_limit per_action_limit} {
        if {![$traders exists $trader_id]} { error "unknown_trader" }
        return [$wallets bind $wallet_id $trader_id $daily_limit $per_action_limit]
    }
    method submit_action {trader_id wallet_id action} { return [$market submit $trader_id $wallet_id $action] }
    method conductor_veto_next {trader_id reason} { return [$conductor veto_next $trader_id $reason] }
    method conductor_pause {trader_id reason} { return [$conductor pause $trader_id $reason] }
    method conductor_resume {trader_id reason} { return [$conductor resume $trader_id $reason] }
    method sae_alert {trader_id alert_type evidence severity timestamp} {
        if {![$traders exists $trader_id]} { error "unknown_trader" }
        return [$conductor receive_alert [$sae alert $trader_id $alert_type $evidence $severity $timestamp]]
    }
    method feed_publish {args} { return [$feeds publish {*}$args] }
    method feed_history {feed_type} { return [$feeds history $feed_type] }
    method sim_publish {sim_type prediction} { return [$sims publish $sim_type $prediction] }
    method statistical_runner_available {} { return [$statistical_runner available] }
    method statistical_query_type {
        prices ticker prediction_type horizon
        {paths 4000} {seed 1} {dt 0.0027397260273972603}
        {pool_prices {}} {pool_liquidity {}}
    } {
        set p [$statistical_runner query_typed             $prices $ticker $prediction_type $horizon $paths $seed $dt             $pool_prices $pool_liquidity]
        $sims publish statistical $p
        return $p
    }
    method statistical_query {prices ticker horizon {paths 4000} {seed 1} {dt 0.0027397260273972603}} {
        return [my statistical_query_type             $prices $ticker price_forecast $horizon $paths $seed $dt {} {}]
    }
    method statistical_from_feed_type {
        ticker prediction_type horizon
        {paths 4000} {seed 1} {dt 0.0027397260273972603}
    } {
        set prices {}
        foreach datum [$feeds history price_tick] {
            if {![dict exists $datum payload]} { continue }
            set payload [dict get $datum payload]
            if {[catch {dict get $payload token_ticker} token]} { continue }
            if {$token ne $ticker} { continue }
            if {[catch {dict get $payload price} price]} { continue }
            if {![string is double -strict $price] || $price <= 0} { continue }
            lappend prices $price
        }
        if {[llength $prices] < 80} { error "insufficient_price_history" }

        set pool_prices {}
        set pool_liquidity {}
        foreach datum [$feeds history dex_pool_state] {
            if {![dict exists $datum payload]} { continue }
            set payload [dict get $datum payload]
            if {[catch {dict get $payload token_ticker} token]} { continue }
            if {$token ne $ticker} { continue }
            if {[catch {dict get $payload price} price]} { continue }
            if {![string is double -strict $price] || $price <= 0} { continue }
            set liquidity 1.0
            if {![catch {dict get $payload liquidity} raw_liquidity] &&
                [string is double -strict $raw_liquidity] && $raw_liquidity >= 0} {
                set liquidity $raw_liquidity
            }
            lappend pool_prices $price
            lappend pool_liquidity $liquidity
        }

        return [my statistical_query_type             $prices $ticker $prediction_type $horizon $paths $seed $dt             $pool_prices $pool_liquidity]
    }
    method statistical_from_feed {ticker horizon {paths 4000} {seed 1} {dt 0.0027397260273972603}} {
        return [my statistical_from_feed_type             $ticker price_forecast $horizon $paths $seed $dt]
    }
    method query_predictions {trader_id sim_type} { return [$market predictions $trader_id $sim_type] }
    method sim_engines {} { return [$registry names] }
    method sim_engine_status {} { return [$registry status] }
    method sim_horizons {} { return [$clock horizons] }
    method sim_running {} { return [$clock running] }
    method sim_advance {wall_seconds} { return [$clock advance $wall_seconds] }
    method tax_event {trader_id amount source_wallet dest_wallet} {
        if {![string is double -strict $amount] || $amount < 0} { error "invalid_tax_amount" }
        set receipt [dict create receipt_id [format "tax-%06d" [expr {[llength $taxes] + 1}]] status staged transferred 0 trader_id $trader_id amount $amount source_wallet $source_wallet dest_wallet $dest_wallet]
        lappend taxes $receipt
        return $receipt
    }
    method secretion {} {
        return [dict create source stomach destination ada_border provenance organ_secretion live_execution 0 traders [$traders count] wallets [$wallets count] sim_engines [llength [$registry names]] predictions [$sims count] executions [$market execution_count] paused_traders [$traders paused_count] tax_receipts [llength $taxes]]
    }
    method sae_log {} { return [$sae log] }
    method decision_log {} { return [$conductor log] }
    method execution_count {} { return [$market execution_count] }
    method live_execution {} { return 0 }
}
unset __stomach_dir
