namespace eval ::stomach {}

oo::class create ::stomach::SimsHub {
    variable predictions
    constructor {} { set predictions {} }
    method publish {sim_type prediction} {
        foreach required {value lower_bound upper_bound confidence correctness certainty time_horizon token_ticker recent_shift timestamp} {
            if {![dict exists $prediction $required]} { error "prediction_missing_$required" }
        }
        foreach numeric {value lower_bound upper_bound confidence correctness certainty recent_shift timestamp} {
            if {![string is double -strict [dict get $prediction $numeric]]} { error "prediction_${numeric}_not_numeric" }
        }
        set value [dict get $prediction value]; set lo [dict get $prediction lower_bound]; set hi [dict get $prediction upper_bound]
        if {$lo > $value || $value > $hi} { error "prediction_out_of_bounds" }
        foreach metric {confidence correctness certainty} {
            set v [dict get $prediction $metric]
            if {$v < 0 || $v > 10} { error "prediction_${metric}_out_of_range" }
        }
        dict set prediction sim_type $sim_type
        dict set prediction running 1
        dict set predictions $sim_type $prediction
        return [dict create status published sim_type $sim_type]
    }
    method query {sim_type} {
        if {![dict exists $predictions $sim_type]} { error "prediction_unavailable" }
        return [dict get $predictions $sim_type]
    }
    method count {} { return [dict size $predictions] }
}
