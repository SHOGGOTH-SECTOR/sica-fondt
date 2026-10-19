namespace eval ::stomach {}

oo::class create ::stomach::HorizonClock {
    variable ratios simulated
    constructor {} {
        set ratios [dict create tick_hourly 90 daily 2160 weekly 15120 monthly 64800 annual 788000 five_year 3942000]
        set simulated {}
        dict for {h r} $ratios { dict set simulated $h 0.0 }
    }
    method horizons {} { return [dict keys $ratios] }
    method ratio {horizon} {
        if {![dict exists $ratios $horizon]} { error "unknown_horizon" }
        return [dict get $ratios $horizon]
    }
    method advance {wall_seconds} {
        if {![string is double -strict $wall_seconds] || $wall_seconds < 0} { error "invalid_wall_seconds" }
        dict for {h r} $ratios { dict set simulated $h [expr {[dict get $simulated $h] + $wall_seconds*$r}] }
        return $simulated
    }
    method state {} { return $simulated }
}
