# RISC-V Computer Project — Summer 2026 Roadmap

A complete homebrew computer built from scratch in SystemVerilog over 12 weeks. The end goal: walk into the Fall 2026 career fair with a working FPGA-based RISC-V machine, on hardware, running my own compiled C programs and rendering output to a VGA monitor.

## The Pitch

Five-stage pipelined RV32I processor with full hazard detection and data forwarding, integrated with UART and VGA peripherals over a memory-mapped bus, synthesized to a Xilinx Artix-7 FPGA. Self-compiled C programs (Game of Life, prime sieve, console games) running on hardware I designed.

This puts me well above the sophomore baseline at chip-design recruiting booths and front-loads most of the content from ECE 337 (ASIC Design Lab).

---

## Hardware (~$200 total)

### Core kit

| Item | Cost | Notes |
|------|------|-------|
| Digilent Basys 3 | $159 | Academic price at digilent.com — student verification required, 1-2 day approval |
| USB-A to USB-B cable | ~$5 | Probably in a drawer already |
| VGA monitor + cable | free–$10 | Ask around the engineering building; if HDMI-only, buy an **active** VGA-to-HDMI converter ($10) |

### Recommended additions

| Item | Cost | Why |
|------|------|-----|
| Saleae Logic 8 clone | $15 | Saves hours debugging peripheral integration |
| Breadboard + jumpers + buttons/LEDs | $15 | Bench testing |

### Skip these

- External clock modules (Basys 3 has 100MHz onboard, plenty)
- Any "RISC-V development kit" (those are for buying pre-made cores — defeats the point)
- PMOD SD card adapter (not needed for v1)

---

## Software Stack

### Apple Silicon caveat (important)

Vivado does not run natively on Apple Silicon. Options:
- Use a Windows or Linux machine if available
- Run UTM/VMware on the M4 Mac Mini with an x86 Linux VM — works, but ~3x slower

### Install order (Week 1)

1. **Xilinx Vivado WebPACK 2024.1** — ~70GB, 2-4 hours install. Free, no license needed for Artix-7.
2. **Verilator + GTKWave** — `brew install verilator gtkwave` (Mac) or `apt install verilator gtkwave` (Linux). Fast simulator — Vivado's built-in sim is too slow for the 100+ test runs ahead.
3. **RISC-V GNU Toolchain** — clone `riscv-gnu-toolchain` from GitHub:
   ```bash
   git clone https://github.com/riscv-collab/riscv-gnu-toolchain
   cd riscv-gnu-toolchain
   ./configure --prefix=/opt/riscv --with-arch=rv32i --with-abi=ilp32
   make
   ```
   Takes ~1 hour. Provides `riscv32-unknown-elf-gcc`.
4. **VS Code** + "Verilog-HDL/SystemVerilog" extension
5. **Git** + GitHub repo set up day one

---

## Reading List (priority ordered)

1. **Digital Design and Computer Architecture: RISC-V Edition** by Harris & Harris — the bible. Chapter 7 (microarchitecture) is the entire backbone of the summer. ~$30 used on eBay.
2. **RISC-V Unprivileged ISA Specification** (free at riscv.org) — read chapters 1-2 carefully, use chapter 24 as the instruction encoding reference.
3. **Onur Mutlu — Digital Design and Computer Architecture** (YouTube, ETH Zurich) — the clearest free explanation of pipelining and hazards.
4. **MIT 6.191 lecture videos** — supplementary, when Harris doesn't click.

Read Harris ch 7 in Week 1; pull the rest as each topic comes up.

---

## Repo Structure

```
risc-v-computer/
├── README.md
├── ROADMAP.md          <- this file
├── rtl/                <- SystemVerilog source
│   ├── core/           <- CPU pipeline stages
│   ├── memory/         <- BRAM modules, memory controllers
│   ├── peripherals/    <- UART, VGA, GPIO
│   └── top.sv          <- top-level module
├── tb/                 <- testbenches
├── sw/                 <- C programs and assembly
│   ├── examples/       <- demo programs (fib, sieve, game of life)
│   ├── runtime/        <- startup code, putc, printf
│   └── linker.ld       <- linker script
├── scripts/            <- Python build scripts (bin → memory init)
├── synth/              <- Vivado project, constraints, timing reports
└── docs/               <- block diagrams, ISA notes
```

---

## Week-by-Week Plan

### Week 1 — Toolchain + Foundations

**Goal:** Working FPGA dev environment. Blink an LED on hardware.

- Install Vivado, Verilator, RISC-V GCC, VS Code
- Read Harris ch 1-2 and ch 7 intro
- Set up GitHub repo with the structure above
- Write a 2-bit counter that blinks the Basys 3 LEDs at 1Hz
- Verify the entire toolchain works end-to-end before committing to anything bigger
- **Email ECE advisor** about ECE 270 → ECE 337 prerequisite override

**Estimated hours:** ~20

---

### Week 2 — Simulation Discipline + Isolated Blocks

**Goal:** Three building blocks, each tested in isolation. VGA risk addressed early.

Build and verify with SystemVerilog testbenches in Verilator:

- **32-bit ALU** — add, sub, and, or, xor, sll, srl, sra, slt, sltu
- **Register file** — 32 registers, 2 read ports, 1 write port, x0 hardwired to zero
- **Instruction decoder** — R-type and I-type for now

Also: drive a VGA test pattern (color bars) from the Basys 3. Get this working now, not in Week 10.

**Estimated hours:** ~20

---

### Week 3 — Single-Cycle Datapath

**Goal:** First instruction executes in simulation.

- Wire blocks together: PC, instruction memory (BRAM), decoder, register file, ALU, data memory (BRAM)
- Hardcode control signals for one instruction type initially
- Verify in simulation: an R-type ADD reads two registers, adds them, writes the result back

**Estimated hours:** ~20

---

### Week 4 — Single-Cycle Complete

**Goal:** Real program runs in simulation.

- Full control unit
- Every RV32I base instruction: R-type, I-type (immediate + loads), S-type (stores), B-type (branches), U-type (LUI, AUIPC), J-type (JAL, JALR)
- Write Fibonacci in RISC-V assembly by hand, run it in simulation, verify the output

**Checkpoint:** Single-cycle RV32I executing a real program in simulation.

**Estimated hours:** ~25-30

---

### Week 5 — Hardware Bring-Up + C Toolchain

**Goal:** Compiled C code running on physical hardware.

- Synthesize single-cycle to Basys 3
- Write a Python script that converts RISC-V GCC binary output (`.bin`) into a Vivado memory init file (`.mem` or `.coe`)
- Compile `int main() { return 1+1; }`, load on hardware, see "2" on the LEDs

**Checkpoint:** Hardware running compiled C. This is the moment the project gets real.

**Estimated hours:** ~25-30

---

### Week 6 — Pipeline Structural Conversion

**Goal:** Five-stage pipeline structure in place (no hazard handling yet).

- Split single-cycle into IF / ID / EX / MEM / WB stages
- Add pipeline registers between every stage
- Verify single-instruction correctness
- Run programs with NOPs between every real instruction so no hazards exist

**Estimated hours:** ~20

---

### Week 7 — Hazard Handling (the hard week)

**Goal:** Pipeline handles all hazard patterns correctly.

- Hazard detection unit
- Forwarding for EX→EX, MEM→EX, WB→ID/EX
- Load-use stall (one bubble)
- Branch resolution in EX with flush-on-taken
- "Hazard zoo" test program with every possible hazard pattern

**Budget extra hours here.** A bug taking two days is normal. Every pipeline conversion in history has gone this way.

**Estimated hours:** ~30+

---

### Week 8 — Pipeline Complete on Hardware

**Goal:** Pipelined RV32I running real programs on FPGA.

- Synthesize pipelined version
- Run Fibonacci and other programs on hardware
- Measure clock frequency, CPI, LUT/FF/BRAM utilization
- Save timing reports

**Checkpoint:** Pipelined RV32I on FPGA — resume bullet earned.

**Estimated hours:** ~25

---

### Week 9 — Memory-Mapped I/O + UART

**Goal:** Hardware prints "hello, world!" to laptop's serial terminal.

- Address decoder: loads/stores to 0x80000000+ hit peripherals instead of RAM
- UART transmitter (115200 baud)
- Memory-map the UART
- C `putc()` writing to UART address, then `printf` on top

**Checkpoint:** Hardware printing text.

**Estimated hours:** ~20

---

### Week 10 — VGA Controller

**Goal:** CPU drawing pixels to a monitor.

- VGA timing generator (640×480 @ 60Hz, pixel clock 25.175 MHz)
- Framebuffer in BRAM — start small (80×60 monochrome, 4800 bits)
- Memory-map the framebuffer
- Draw rectangles, then text via a tiny embedded bitmap font

**Estimated hours:** ~25-30

---

### Week 11 — Demo Programs

**Goal:** Three impressive demos running on hardware.

- Conway's Game of Life on the VGA framebuffer
- Prime sieve printing to UART
- Simple console snake game (optional, if time permits)

Polish: fix display glitches, tune timing, make them look professional.

**Estimated hours:** ~20

---

### Week 12 — Polish + Deliverables

**Goal:** Everything publishable and pitch-ready.

- GitHub README: project overview, block diagram (draw.io), build instructions, performance numbers, timing reports, hardware photos
- 60-second demo video
- Blog post on the hardest bug — working title: *"Why my RISC-V CPU computed 1+1=3 for a week"*
- LinkedIn update
- Resume bullet finalized

**Estimated hours:** ~15

---

## Risks & Mitigations

| Risk | Mitigation |
|------|------------|
| Pipeline conversion (Week 7) eats the timeline | Build directed testbenches obsessively from Week 3 onward; every instruction gets a directed test |
| Vivado on Mac is painfully slow | Use a Windows/Linux machine if available; otherwise budget extra time per synthesis run |
| VGA timing turns out tricky in Week 10 | Already de-risked in Week 2 with the test pattern |
| ECE 301 (Signals) eats brain energy | Alternate days — don't debug pipeline hazards right after a Fourier transforms problem set |
| Toolchain switching mid-project | Pick Vivado + Verilator and stay there. Every toolchain switch costs a week. |
| ECE 270 prerequisite blocking ECE 337 in Fall | Email advisor in Week 1 — co-req override or alternative pathway |

---

## End-of-Summer Deliverables

By September:

- Working Basys 3 with the full system, ready to plug into a career fair monitor
- GitHub repo: ~3,000 lines of SystemVerilog + ~500 lines of C + comprehensive testbenches + docs
- 60-second demo video on phone (backup for booths without monitors)
- One-page architecture sheet: block diagram, ISA table, performance numbers — printed copies to hand to recruiters
- Resume bullet:

> *Designed and verified a 5-stage pipelined RV32I processor in SystemVerilog with hazard detection and full operand forwarding; integrated UART and VGA peripherals over a memory-mapped bus; synthesized to Xilinx Artix-7 at [X] MHz with [Y]% resource utilization; demonstrated running self-compiled C programs (Game of Life, prime sieve).*

- Published blog post that recruiters find when they Google me
- Functional equivalent of ECE 337 content already internalized

---

## Stretch Goals (only after Week 12 deliverables are done)

- Add an instruction cache (direct-mapped, 4KB)
- Implement RV32M extension (multiply/divide)
- 16-color VGA framebuffer
- Simple bootloader that loads programs over UART
- SD card support via PMOD adapter
- Submit a small block of the design to Tiny Tapeout for real silicon

---

## Career Fair Prep Checklist

Two weeks before the fair:

- [ ] Resume bullet polished, project at top of resume
- [ ] LinkedIn updated with project post
- [ ] One-page architecture sheet printed (10-20 copies)
- [ ] Demo video downloaded to phone for offline access
- [ ] Basys 3 + cables + VGA-HDMI adapter packed in a small bag
- [ ] 60-second elevator pitch rehearsed
- [ ] List of target companies (NVIDIA, AMD, Intel, Apple, Qualcomm, Texas Instruments, Analog Devices, Micron, Marvell) with their booth locations
- [ ] Tailored questions prepared for each company

---

## Progress Log

*Use this section to track weekly progress, bugs encountered, and lessons learned throughout the summer.*

### Week 1
- [ ] Vivado installed
- [ ] Verilator installed
- [ ] RISC-V GCC built
- [ ] Repo initialized
- [ ] LED blink working on Basys 3
- [ ] Advisor emailed re: ECE 337 prereq

### Week 2
- [ ] ALU + testbench
- [ ] Register file + testbench
- [ ] Decoder (R/I-type) + testbench
- [ ] VGA color bars on hardware

*(Continue weekly...)*
