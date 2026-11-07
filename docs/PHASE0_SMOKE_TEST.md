# Phase 0 counter smoke test

Verified November 7, 2026 in Ubuntu under WSL 2. This is the first working
simulation check. CPU RTL, the general test runner, Vivado builds, CI, and
board operation are still pending.

## Run it from Cursor

1. Open this project in Cursor connected to **WSL: Ubuntu**.
2. Save any source edits, then press **Ctrl+Shift+B**.
3. The default task is **Smoke: build and run counter**. You can also choose
   it through **Terminal > Run Build Task**.

Expected result:

```text
PASS: counter reset, counting, wraparound and restart (25 checks)
```

The shared [.vscode/tasks.json](../.vscode/tasks.json) prepares output, compiles
with Verilator, then runs the executable. A failed compile prevents the run;
a failed assertion gives a nonzero process exit status. Verilator compile
diagnostics are linked to source locations in the editor where available.
Use this task in a WSL window: its tools and generated executable are Linux
programs, not Windows executables.

## What the two files do

- [rtl/core/counter.sv](../rtl/core/counter.sv) is a four-bit counter. At each
  rising clock edge, active-high `rst` clears it; otherwise it increments.
  Four-bit arithmetic wraps from 15 to 0. It is a simulation smoke module,
  not a completed CPU block or an FPGA blink design.
- [tb/counter_tb.sv](../tb/counter_tb.sv) generates the clock and checks initial
  reset, held reset, twenty increments including wraparound, reset asserted
  between clock edges, reset at the next rising edge, and counting afterward.
  A separate timeout fails the test if it stops making progress.

The bench samples at falling edges, after rising-edge state changes have
settled. Assertions require `--assert`; timed clock generation requires
`--timing`. Both are included in the task, along with Verilator `-Wall`.

## Build location and terminal reproduction

Generated C++/object files and the executable go in
`$HOME/.cache/risc-v-computer/smoke` **inside Ubuntu**. This avoids timestamp
skew and object-file churn on the Windows/OneDrive-backed source directory.
No global clock or WSL configuration was changed. Other project jobs may
still use the ignored repository `build/` directory as documented.

From a WSL terminal at the repository root, the same steps are:

```bash
mkdir -p "$HOME/.cache/risc-v-computer/smoke"
verilator --binary --timing --assert -Wall -j 2 \
    --top-module counter_tb \
    --Mdir "$HOME/.cache/risc-v-computer/smoke" \
    "$PWD/rtl/core/counter.sv" "$PWD/tb/counter_tb.sv"
"$HOME/.cache/risc-v-computer/smoke/Vcounter_tb"
```

## Recorded verification

Source snapshot: local changes on `codex/feature/verilator-smoke-test`, based
on `4c1c07897c320d43c002d2675c1d87c524ae5e14`. No commit, push, or PR was made.

| Check | Observed result |
| --- | --- |
| Cursor task dependencies and commands | Executed from the actual task JSON in Ubuntu; prepare, compile, then run succeeded. |
| Verilator flags | `--binary --timing --assert -Wall -j 2`; no HDL warnings. |
| Normal test | PASS, 25 checks, process exit 0. |
| Intentional failure | `+force_failure` asked the same checker to expect 1 during reset; it detected `expected 1, got 0`, exited nonzero (SIGABRT / -6). |
| Timeout guard | Present in the testbench; the normal run completes before its 1,000 ns limit. |
| Build location | Final native-Ubuntu-cache build completed without the mounted-folder clock-skew warning seen on the initial attempt. |

Tools observed: Verilator 5.020, g++ 13.3.0, GNU Make 4.3, Python 3.12.3.
The IDE button itself is for the owner to run; its configured commands were
verified programmatically. GTKWave, RISC-V GCC and Vivado were not checked by
this smoke test. No synthesis, FPGA programming, or hardware timing result
is implied.

To inspect the intentional failure manually in Ubuntu:

```bash
ulimit -c 0
"$HOME/.cache/risc-v-computer/smoke/Vcounter_tb" +force_failure
```

That command is **supposed to fail**. `ulimit` disables core-dump files for
that shell; no normal simulation source is changed to trigger the test.

## Next task

Phase 0 is now **2/6 tasks complete**: skeleton and smoke test. Next is the
general `scripts/run_tests.py` runner; scripted Vivado blink builds and CI
must still pass before the Phase 0 gate can be marked complete.
