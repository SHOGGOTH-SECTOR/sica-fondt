# Polyglot M3 test driver. Missing externally hosted runtimes are reported as
# SKIP by default; pass --strict to make a missing runtime fail the run.
set here [file dirname [file normalize [info script]]]
set strict [expr {[lsearch -exact $argv --strict] >= 0}]
set failures 0
set skipped 0

proc have {cmd} { expr {[auto_execok $cmd] ne ""} }
proc run_cmd {label cwd cmd} {
    global failures
    puts "=== $label ==="
    set old [pwd]
    cd $cwd
    set code [catch {exec {*}$cmd 2>@1} out opts]
    cd $old
    if {$out ne ""} { puts $out }
    if {$code} {
        incr failures
        puts "FAIL: $label"
        return 0
    }
    if {[string match "*Failed*" $out] && ![regexp {Failed[[:space:]]+0} $out]} {
        incr failures
        puts "FAIL: $label reported test failures"
        return 0
    }
    puts "PASS: $label"
    return 1
}
proc require_runtime {label cmd} {
    global strict failures skipped
    if {[have $cmd]} { return 1 }
    if {$strict} {
        incr failures
        puts "FAIL: $label runtime '$cmd' missing"
    } else {
        incr skipped
        puts "SKIP: $label runtime '$cmd' missing"
    }
    return 0
}

run_cmd "M3 hub registry + clocks" [file join $here tests] [list tclsh hub_runtime.test]

set build /tmp/sica-m3-build
file mkdir $build
foreach spec {
    {M3d-MEV mev mev_engine.f90 test_mev.f90}
    {M3e-tokenomics tokenomics tokenomics_engine.f90 test_tokenomics.f90}
    {M3g-microstructure microstructure microstructure_engine.f90 test_microstructure.f90}
} {
    lassign $spec label dir engine test
    if {[require_runtime $label gfortran]} {
        set exe [file join $build $dir-test]
        set src [file join $here $dir src $engine]
        set tst [file join $here $dir test $test]
        if {[run_cmd "$label compile" $here [list gfortran -std=f2018 -Wall -Wextra -Werror -pedantic -J $build $src $tst -o $exe]]} {
            run_cmd "$label executable" $here [list $exe]
        }
    }
}

if {[require_runtime M3a-statistical Rscript]} {
    run_cmd M3a-statistical [file join $here statistical] [list Rscript tests.R]
}
if {[require_runtime M3b-sociological eclipse]} {
    run_cmd M3b-sociological [file join $here sociological] [list eclipse -b test.ecl -e halt]
}
if {[require_runtime M3f-consensus eclipse]} {
    run_cmd M3f-consensus [file join $here consensus] [list eclipse -b test.ecl -e halt]
}
if {[require_runtime M3c-AMM forge]} {
    run_cmd M3c-AMM [file join $here amm] [list forge test]
}

puts "=== M3 RESULT ==="
puts "failures=$failures skipped=$skipped strict=$strict"
exit [expr {$failures > 0 ? 1 : 0}]
