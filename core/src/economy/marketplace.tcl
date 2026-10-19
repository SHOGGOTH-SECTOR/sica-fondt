namespace eval ::stomach {}

oo::class create ::stomach::Marketplace {
    variable traders wallets conductor sae sims executions tx_seq
    constructor {traders_obj wallets_obj conductor_obj sae_obj sims_obj} {
        set traders $traders_obj; set wallets $wallets_obj; set conductor $conductor_obj; set sae $sae_obj; set sims $sims_obj
        set executions {}; set tx_seq 0
    }
    method _reject {reason} { return [dict create status failed reason $reason] }
    method _law_check {action} {
        foreach required {type asset chain amount price} {
            if {![dict exists $action $required]} { return [dict create pass 0 reason "missing_$required"] }
        }
        if {[lsearch -exact {buy sell mint provide_liquidity withdraw_liquidity claim_rewards} [dict get $action type]] < 0} { return [dict create pass 0 reason action_not_allowed] }
        if {[lsearch -exact {ethereum solana arbitrum} [dict get $action chain]] < 0} { return [dict create pass 0 reason chain_not_allowed] }
        set amount [dict get $action amount]; set price [dict get $action price]
        if {![string is double -strict $amount] || ![string is double -strict $price] || $amount <= 0 || $price < 0} { return [dict create pass 0 reason invalid_notional] }
        return [dict create pass 1]
    }
    method submit {trader_id wallet_id action} {
        $sae log_tool $trader_id submit_action $action
        if {![$traders exists $trader_id]} { return [my _reject unknown_trader] }
        if {[$wallets binding_for $trader_id] eq ""} { return [my _reject missing_wallet] }
        if {![$wallets binding_matches $trader_id $wallet_id]} { return [my _reject wallet_binding] }
        if {[$traders is_paused $trader_id]} { return [my _reject trader_paused] }
        set law [my _law_check $action]
        if {![dict get $law pass]} { return [my _reject [dict get $law reason]] }
        set wc [$wallets spending_check $wallet_id $action]
        if {![dict get $wc pass]} { return [my _reject [dict get $wc reason]] }
        set veto [$conductor consume_veto $trader_id]
        if {![dict get $veto approved]} { return [my _reject [dict get $veto reason]] }

        # Simulation boundary: there is no signer, broadcaster, RPC client, or
        # chain-execution method in this scaffold. Success means the proposed
        # action cleared the organ's gates and was recorded in the sandbox.
        incr tx_seq
        set tx_id [format "simtx-%06d" $tx_seq]
        $wallets record_spend $wallet_id [dict get $wc notional]
        lappend executions [dict create tx_id $tx_id trader_id $trader_id wallet_id $wallet_id action $action execution simulated]
        return [dict create status succeeded execution simulated tx_id $tx_id]
    }
    method predictions {trader_id sim_type} {
        $sae log_tool $trader_id query_predictions [dict create sim_type $sim_type]
        if {![$traders exists $trader_id]} { error "unknown_trader" }
        if {[$traders is_paused $trader_id]} { error "trader_paused" }
        return [$sims query $sim_type]
    }
    method execution_count {} { return [llength $executions] }
}
