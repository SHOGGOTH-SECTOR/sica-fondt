namespace eval ::stomach {}

oo::class create ::stomach::SAEMonitor {
    variable events
    constructor {} { set events {} }
    method log_tool {trader_id tool detail} {
        lappend events [dict create trader_id $trader_id tool $tool detail $detail timestamp [clock seconds]]
    }
    method alert {trader_id alert_type evidence severity timestamp} {
        if {![string is double -strict $severity] || $severity < 0 || $severity > 10} { error "severity_out_of_range" }
        return [dict create trader_id $trader_id alert_type $alert_type evidence $evidence severity $severity timestamp $timestamp]
    }
    method log {} { return $events }
    method count {} { return [llength $events] }
}
