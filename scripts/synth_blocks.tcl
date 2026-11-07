# Out-of-context Vivado synthesis check for the Phase 1 CPU blocks.
#
# build.tcl only synthesizes the modules under its top level, and the Phase 1
# blocks are not connected to the blink top yet. This script synthesizes each
# block on its own, so Vivado proves it is synthesizable and latch-free, and
# writes a utilization report per block into build/vivado/blocks/.
#
# Usage (Windows, repository root, Vivado on PATH):
#   vivado -mode batch -nojournal -nolog -source scripts/synth_blocks.tcl
#
# The script exits nonzero if a block fails to synthesize or infers a latch.
# Numbers are for each block alone, not for a connected CPU.

set part   xc7a35tcpg236-1
set blocks {alu branch_unit decoder imm_gen regfile}

set repo   [file normalize [file join [file dirname [info script]] ..]]
set outdir [file join $repo build vivado blocks]
file mkdir $outdir
cd $outdir

# Packages (*_pkg.sv) first, then the blocks themselves.
set core [file join $repo rtl core]
set srcs [list [file join $core rv32i_pkg.sv]]
foreach block $blocks { lappend srcs [file join $core $block.sv] }

set summary {}
set failed  0
foreach block $blocks {
    puts "== Synthesizing $block (out of context)"
    catch {close_design}
    read_verilog -sv $srcs
    if {[catch {synth_design -top $block -part $part -mode out_of_context} msg]} {
        puts "== $block: SYNTHESIS FAILED: $msg"
        lappend summary [format "%-12s FAILED" $block]
        incr failed
        continue
    }
    report_utilization -file [file join $outdir ${block}_utilization.rpt]
    set luts    [llength [get_cells -hier -quiet -filter {PRIMITIVE_GROUP == LUT}]]
    set ffs     [llength [get_cells -hier -quiet -filter {REF_NAME =~ FD*}]]
    set lutram  [llength [get_cells -hier -quiet -filter {PRIMITIVE_GROUP == DMEM}]]
    set latches [llength [get_cells -hier -quiet -filter {REF_NAME =~ LD*}]]
    lappend summary [format "%-12s LUT %5d   FF %5d   LUTRAM %3d   latch %d" \
        $block $luts $ffs $lutram $latches]
    if {$latches > 0} {
        puts "== $block: LATCH INFERRED"
        incr failed
    }
}

puts "\n== Phase 1 block synthesis ($part, each block alone)"
foreach line $summary { puts "   $line" }
puts "== Reports: $outdir"
if {$failed > 0} {
    puts "== BLOCK SYNTHESIS FAILED ($failed problem(s))"
    exit 1
}
puts "== ALL BLOCKS SYNTHESIZED, NO LATCHES"
