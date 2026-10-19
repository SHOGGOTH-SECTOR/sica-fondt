namespace eval ::stomach {}

oo::class create ::stomach::Wallets {
    variable wallets wallet_for_trader spend
    constructor {} { set wallets {}; set wallet_for_trader {}; set spend {} }

    method bind {wallet_id trader_id daily_limit per_action_limit} {
        if {[dict exists $wallets $wallet_id]} { error "wallet_already_bound" }
        if {[dict exists $wallet_for_trader $trader_id]} { error "trader_already_bound" }
        foreach {name value} [list daily_limit $daily_limit per_action_limit $per_action_limit] {
            if {![string is double -strict $value] || $value <= 0} { error "${name}_must_be_positive" }
        }
        # No key material exists here. Binding/limits are implemented first; local
        # key generation/signing waits for the still-open M4 storage specification.
        dict set wallets $wallet_id [dict create trader_id $trader_id daily_limit $daily_limit per_action_limit $per_action_limit]
        dict set wallet_for_trader $trader_id $wallet_id
        dict set spend $wallet_id 0.0
        return [dict create status bound wallet_id $wallet_id trader_id $trader_id]
    }
    method binding_for {trader_id} {
        if {![dict exists $wallet_for_trader $trader_id]} { return "" }
        return [dict get $wallet_for_trader $trader_id]
    }
    method binding_matches {trader_id wallet_id} {
        expr {[dict exists $wallet_for_trader $trader_id] && [dict get $wallet_for_trader $trader_id] eq $wallet_id && [dict exists $wallets $wallet_id] && [dict get $wallets $wallet_id trader_id] eq $trader_id}
    }
    method spending_check {wallet_id action} {
        set w [dict get $wallets $wallet_id]
        set notional [expr {double([dict get $action amount]) * double([dict get $action price])}]
        if {$notional > double([dict get $w per_action_limit])} { return [dict create pass 0 reason wallet_limit] }
        set used [dict get $spend $wallet_id]
        if {$used + $notional > double([dict get $w daily_limit])} { return [dict create pass 0 reason wallet_daily_limit] }
        return [dict create pass 1 notional $notional]
    }
    method record_spend {wallet_id notional} {
        dict set spend $wallet_id [expr {[dict get $spend $wallet_id] + $notional}]
    }
    method count {} { return [dict size $wallets] }
}
