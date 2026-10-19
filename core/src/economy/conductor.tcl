namespace eval ::stomach {}

oo::class create ::stomach::Conductor {
    variable traders decisions veto_next
    constructor {traders_obj} { set traders $traders_obj; set decisions {}; set veto_next {} }

    method veto_next {trader_id reason} {
        if {![$traders exists $trader_id]} { error "unknown_trader" }
        dict set veto_next $trader_id $reason
        return [dict create status armed trader_id $trader_id]
    }
    method consume_veto {trader_id} {
        if {![dict exists $veto_next $trader_id]} { return [dict create approved 1] }
        set reason [dict get $veto_next $trader_id]
        dict unset veto_next $trader_id
        lappend decisions [dict create decision veto trader_id $trader_id reason $reason timestamp [clock seconds]]
        return [dict create approved 0 reason $reason]
    }
    method pause {trader_id reason} {
        $traders pause $trader_id
        set d [dict create decision pause trader_id $trader_id reason $reason timestamp [clock seconds]]
        lappend decisions $d
        return $d
    }
    method resume {trader_id reason} {
        $traders resume $trader_id
        set d [dict create decision resume trader_id $trader_id reason $reason timestamp [clock seconds]]
        lappend decisions $d
        return $d
    }
    method receive_alert {alert} {
        set trader_id [dict get $alert trader_id]
        if {[dict get $alert severity] >= 8.0} {
            $traders pause $trader_id
            set d [dict create decision pause trader_id $trader_id reason "sae:[dict get $alert alert_type]" alert $alert timestamp [clock seconds]]
        } else {
            set d [dict create decision dismiss trader_id $trader_id reason below_pause_threshold alert $alert timestamp [clock seconds]]
        }
        lappend decisions $d
        return $d
    }
    method log {} { return $decisions }
}
