# RISC-V Computer

A from-scratch computer for the Digilent Basys 3 (Xilinx Artix-7): a 5-stage
pipelined RV32I CPU written in SystemVerilog, with RAM, UART and VGA, running
C programs compiled with GCC.

**Status:** fresh start, November 2026. Work begins with Phase 0: the repo
skeleton, a one-command test runner, and scripted Vivado builds.

**Plan:** [docs/BUILD_PLAN.md](docs/BUILD_PLAN.md) has the 8 build phases and
their gates, design decisions, memory map, repo layout and testing strategy.

Earlier work (the Week 1 LED blink demo and the original roadmap) is still in
the git history (commit 9341a22 and earlier).
