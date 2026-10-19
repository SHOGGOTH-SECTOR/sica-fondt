namespace eval ::stomach {}

oo::class create ::stomach::Traders {
    variable records paused
    constructor {} { set records {}; set paused {} }

    method register {trader_id specialization} {
        if {[dict exists $records $trader_id]} { error "trader_exists" }
        dict set records $trader_id [dict create specialization $specialization]
        dict set paused $trader_id 0
        return [dict create status registered trader_id $trader_id specialization $specialization]
    }
    method exists {trader_id} { return [dict exists $records $trader_id] }
    method pause {trader_id} {
        if {![my exists $trader_id]} { error "unknown_trader" }
        dict set paused $trader_id 1
    }
    method resume {trader_id} {
        if {![my exists $trader_id]} { error "unknown_trader" }
        dict set paused $trader_id 0
    }
    method is_paused {trader_id} {
        expr {[dict exists $paused $trader_id] && [dict get $paused $trader_id]}
    }
    method count {} { return [dict size $records] }
    method paused_count {} {
        set n 0
        dict for {id p} $paused { if {$p} { incr n } }
        return $n
    }
}
