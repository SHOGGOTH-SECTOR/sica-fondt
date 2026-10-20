namespace eval ::stomach {}

oo::class create ::stomach::EngineRegistry {
    variable root engines
    constructor {root_dir} {
        set root [file normalize $root_dir]
        set engines [dict create             statistical [dict create lang r runtime Rscript source statistical/engine.R test statistical/tests.R]             sociological [dict create lang eclipse_prolog runtime eclipse source sociological/engine.ecl test sociological/test.ecl]             amm_liquidity [dict create lang solidity runtime forge source amm/src/AMMSim.sol test amm/test/AMMSim.t.sol]             mev_adversarial [dict create lang fortran runtime gfortran source mev/src/mev_engine.f90 test mev/test/test_mev.f90]             tokenomics_macro [dict create lang fortran runtime gfortran source tokenomics/src/tokenomics_engine.f90 test tokenomics/test/test_tokenomics.f90]             consensus_staking [dict create lang eclipse_prolog runtime eclipse source consensus/engine.ecl test consensus/test.ecl]             market_microstructure [dict create lang fortran runtime gfortran source microstructure/src/microstructure_engine.f90 test microstructure/test/test_microstructure.f90]]
    }
    method names {} { return [dict keys $engines] }
    method descriptor {name} {
        if {![dict exists $engines $name]} { error "unknown_engine" }
        set d [dict get $engines $name]
        dict set d source [file join $root [dict get $d source]]
        dict set d test [file join $root [dict get $d test]]
        return $d
    }
    method source_present {name} { return [file exists [dict get [my descriptor $name] source]] }
    method runtime_available {name} {
        set cmd [dict get [my descriptor $name] runtime]
        expr {[auto_execok $cmd] ne ""}
    }
    method status {} {
        set out {}
        foreach name [my names] {
            set d [my descriptor $name]
            dict set out $name [dict create lang [dict get $d lang] source_present [my source_present $name] runtime_available [my runtime_available $name]]
        }
        return $out
    }
}
