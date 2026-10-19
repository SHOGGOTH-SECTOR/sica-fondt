namespace eval ::stomach {}

oo::class create ::stomach::HorizonClock {
    variable ratios simulated is_running after_id last_ms interval_ms
    constructor {} {
        set ratios [dict create tick_hourly 90 daily 2160 weekly 15120 monthly 64800 annual 788000 five_year 3942000]
        set simulated {}
        dict for {h r} $ratios { dict set simulated $h 0.0 }
        set is_running 0
        set after_id ""
        set last_ms 0
        set interval_ms 1000
    }
    destructor { my stop }
    method horizons {} { return [dict keys $ratios] }
    method ratio {horizon} {
        if {![dict exists $ratios $horizon]} { error "unknown_horizon" }
        return [dict get $ratios $horizon]
    }
    method advance {wall_seconds} {
        if {![string is double -strict $wall_seconds] || $wall_seconds < 0} { error "invalid_wall_seconds" }
        dict for {h r} $ratios {
            dict set simulated $h [expr {[dict get $simulated $h] + $wall_seconds*$r}]
        }
        return $simulated
    }
    method start {{pulse_ms 1000}} {
        if {![string is integer -strict $pulse_ms] || $pulse_ms < 1} { error "invalid_pulse_ms" }
        if {$is_running} { return }
        set interval_ms $pulse_ms
        set is_running 1
        set last_ms [clock milliseconds]
        set after_id [after $interval_ms [list [self] pulse]]
    }
    method pulse {} {
        if {!$is_running} { return }
        set now [clock milliseconds]
        set elapsed [expr {double($now-$last_ms)/1000.0}]
        set last_ms $now
        my advance $elapsed
        set after_id [after $interval_ms [list [self] pulse]]
    }
    method stop {} {
        if {$after_id ne ""} { after cancel $after_id }
        set after_id ""
        set is_running 0
    }
    method running {} { return $is_running }
    method state {} { return $simulated }
}
