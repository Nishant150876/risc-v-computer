# Vivado non-project build for the Basys 3.
#
# Reads every rtl/**/*.sv file and fpga/basys3.xdc, runs synthesis,
# placement and routing, and writes into build/vivado/:
#   <top>.bit                    the bitstream
#   timing_summary.rpt           check "WNS" is not negative
#   utilization.rpt              LUTs, flip-flops, BRAM, DSP used
#   drc.rpt, post_synth_*.rpt    extra detail for debugging
#
# Usage (Windows, repository root, Vivado on PATH):
#   vivado -mode batch -nojournal -nolog -source scripts/build.tcl
#   vivado -mode batch -nojournal -nolog -source scripts/build.tcl -tclargs <top_module>
#
# Building and programming are separate steps: see scripts/program.tcl.
# The script exits nonzero if timing fails (negative setup or hold slack).

set part   xc7a35tcpg236-1
set top    basys3_top
if {[llength $argv] >= 1} { set top [lindex $argv 0] }

set repo   [file normalize [file join [file dirname [info script]] ..]]
set outdir [file join $repo build vivado]
file mkdir $outdir
# Vivado writes scratch files (clockInfo.txt, .Xil/, dfx_runtime.txt) into the
# working directory. Run from the ignored output folder so they never land in
# the repository root. Every path below is absolute, so this is safe.
cd $outdir

# Collect sources: packages (*_pkg.sv) first, then everything else.
proc find_sv {dir} {
    set files [glob -nocomplain -directory $dir -types f *.sv]
    foreach sub [glob -nocomplain -directory $dir -types d *] {
        set files [concat $files [find_sv $sub]]
    }
    return $files
}
set all  [lsort [find_sv [file join $repo rtl]]]
set pkgs [lsearch -all -inline -glob $all *_pkg.sv]
set rest [lsearch -all -inline -not -glob $all *_pkg.sv]
set srcs [concat $pkgs $rest]
if {[llength $srcs] == 0} { error "no .sv files found under rtl/" }

puts "== Top: $top   Part: $part"
puts "== Sources:"
foreach f $srcs { puts "   $f" }

read_verilog -sv $srcs
read_xdc [file join $repo fpga basys3.xdc]

# Memory images (.mem) used by $readmemh live next to the RTL or in sw/;
# add them here when Phase 3 introduces them.

synth_design -top $top -part $part
report_utilization     -file [file join $outdir post_synth_utilization.rpt]
report_timing_summary  -file [file join $outdir post_synth_timing.rpt]

opt_design
place_design
phys_opt_design
route_design

report_timing_summary -max_paths 10 -file [file join $outdir timing_summary.rpt]
report_utilization                 -file [file join $outdir utilization.rpt]
report_drc                         -file [file join $outdir drc.rpt]

write_bitstream -force [file join $outdir $top.bit]

set wns [get_property SLACK [get_timing_paths -delay_type max]]
set whs [get_property SLACK [get_timing_paths -delay_type min]]
puts "== Bitstream: [file join $outdir $top.bit]"
puts "== Worst setup slack (WNS): $wns ns   Worst hold slack (WHS): $whs ns"
if {$wns < 0 || $whs < 0} {
    puts "== TIMING FAILED: negative slack, see build/vivado/timing_summary.rpt"
    exit 1
}
puts "== TIMING MET"
