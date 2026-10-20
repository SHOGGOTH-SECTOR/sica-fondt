namespace eval ::stomach {}

oo::class create ::stomach::Feeds {
    variable history_cap feeds
    constructor {cap} {
        if {![string is integer -strict $cap] || $cap < 1} { error "history_cap_must_be_positive" }
        set history_cap $cap
        set feeds {}
    }
    method publish {feed_type source timestamp payload confidence} {
        if {![string is double -strict $confidence] || $confidence < 0 || $confidence > 10} { error "confidence_out_of_range" }
        set history [expr {[dict exists $feeds $feed_type] ? [dict get $feeds $feed_type] : {}}]
        if {[llength $history] >= $history_cap} { return [dict create status backpressure feed_type $feed_type buffered [llength $history]] }
        lappend history [dict create feed_type $feed_type source $source timestamp $timestamp payload $payload confidence $confidence]
        dict set feeds $feed_type $history
        return [dict create status accepted feed_type $feed_type buffered [llength $history]]
    }
    method history {feed_type} {
        if {![dict exists $feeds $feed_type]} { return {} }
        return [dict get $feeds $feed_type]
    }
}
