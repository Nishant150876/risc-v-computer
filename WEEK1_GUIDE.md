# Week 1 Guide — Setup & Validation

## The Mindset

Week 1 is **not** about building anything impressive. It's about removing every piece of friction between you and the Week 2-12 work. By Friday evening you need:

1. A toolchain that works end-to-end (Verilog source → synthesized bitstream → FPGA running it)
2. A blinking LED on your Basys 3 (this proves #1)
3. A clean Git repo with the project structure committed
4. An advisor's reply on the ECE 337 prerequisite question
5. Harris & Harris chapter 7 intro read

The blink LED isn't impressive on its own — it's a *toolchain validation test*. If anything in your chain is broken (synthesis fails, programmer can't connect, constraints wrong, clock not declared), you find out *now* while the only code at stake is 15 lines. Finding the same problem in Week 5 when you're bringing up your CPU costs days.

---

## Day-by-Day Plan

### Monday — Critical Path Day

**Send the advisor email first thing.** This is the longest-feedback-loop item in the entire summer. Template at the bottom of this file. Send before you touch any code.

Then kick off the Vivado download in the background:

1. Go to amd.com/en/products/software/adaptive-socs-and-fpgas/vivado.html
2. Create an AMD account (free)
3. Download "Vivado ML Standard 2024.1" — Linux or Windows installer
4. **Important**: during installation, select **only the Artix-7 device family** under device support. This trims the install from ~70GB to ~30GB.

While it runs:

- Install VS Code + the "Verilog-HDL/SystemVerilog" extension
- Install Git, set up GitHub if you haven't already
- Create a new GitHub repo: `risc-v-computer`, public
- Clone it locally
- Set up the directory structure (commands below)

### Tuesday — Toolchain Round Two

By now Vivado should be installed. Verify by launching it. Just open it, don't create a project yet — confirming it opens without license errors is the goal.

Install Verilator + GTKWave:

**Mac:**
```bash
brew install verilator gtkwave
verilator --version  # should be 5.0+
```

**Ubuntu:**
```bash
sudo apt update
sudo apt install verilator gtkwave
```

**Windows:**
Use WSL2 with Ubuntu and follow the Ubuntu steps. (Verilator on native Windows is painful.)

### Wednesday — RISC-V GCC + Reading

The RISC-V toolchain build is the longest single install. Start it in the morning, read while it builds.

**Mac (easiest, pre-built):**
```bash
brew tap riscv-software-src/riscv
brew install riscv-tools
```

**Linux (build from source):**
```bash
git clone https://github.com/riscv-collab/riscv-gnu-toolchain
cd riscv-gnu-toolchain
./configure --prefix=/opt/riscv --with-arch=rv32i --with-abi=ilp32
sudo make  # 1-3 hours depending on cores
```

Add `/opt/riscv/bin` to your PATH. Verify:
```bash
riscv32-unknown-elf-gcc --version
```

While it builds, **read Harris ch 1-2** (skim if you know the digital logic basics from ECE 270) and **ch 7 intro** carefully. Chapter 7 introduces the single-cycle RISC-V architecture you'll build starting Week 3 — internalize the high-level datapath.

### Thursday — First Verilog

Time to write code. Open Vivado, create a new RTL project:

1. File → Project → New
2. Project name: `blink`. Location: anywhere outside your Git repo (Vivado generates a lot of intermediate files; keep your source in Git but Vivado's project mess outside).
3. Project type: RTL Project (uncheck "Do not specify sources at this time")
4. Add the `blink.sv` source file
5. Add the `blink.xdc` constraints file
6. Default part: type `xc7a35tcpg236-1` in the search box — this is the Basys 3's FPGA
7. Finish

Click **Generate Bitstream** in the left panel. This runs synthesis → implementation → bitstream generation. Takes ~3-5 minutes on a fast machine, ~10 on slower machines or VMs.

If it fails, the most common Week 1 issues:
- Constraint file pins don't match the Basys 3 — copy them exactly from the provided `blink.xdc`
- Clock period not specified — `create_clock` line in XDC is required
- Module name mismatch between SV file and project top module

### Friday — Hardware Bring-Up

The fun day.

1. Plug Basys 3 into your laptop via USB
2. Set the power switch to ON (top of the board, near the USB port)
3. In Vivado: **Open Hardware Manager** → **Open Target** → **Auto Connect**
4. Right-click your Basys 3 in the Hardware panel → **Program Device**
5. Browse to the `.bit` file (in your Vivado project's `.runs/impl_1/` folder)
6. Click **Program**

LED0 should now blink at 1Hz.

**If it doesn't blink:**
- Check the LED you're looking at — LED0 is the rightmost LED in the row
- Verify your XDC pin is `U16` (LED0's pin)
- Verify the bitstream programmed successfully (Vivado will show "Programming completed")
- Try power-cycling the board after programming

**When it works**: commit your code, push to GitHub, take a 5-second video, and message yourself something dumb like "I did it." You've now done what 95% of people who *think* about doing this never actually do.

### Weekend — Read, Sketch, Plan

- Finish Harris ch 7 intro if you haven't
- On paper, sketch the single-cycle RV32I datapath *from memory* — don't copy from the book. Then check against Harris fig 7.11 to find your gaps.
- Plan Week 2: which testbench style to use in Verilator, what your ALU testbench will look like

---

## Repo Structure Setup

Run this in your cloned repo directory:

```bash
mkdir -p rtl/core rtl/memory rtl/peripherals tb sw/examples sw/runtime scripts synth docs

# Placeholder files so git tracks empty directories
touch rtl/.gitkeep tb/.gitkeep sw/examples/.gitkeep scripts/.gitkeep docs/.gitkeep

# Initial README
cat > README.md << 'EOF'
# RISC-V Computer

A from-scratch RISC-V (RV32I) computer in SystemVerilog, synthesized to Xilinx Artix-7 (Basys 3).

- Project plan: see [ROADMAP.md](./ROADMAP.md)
- Current week: see [WEEK1_GUIDE.md](./WEEK1_GUIDE.md)
EOF

git add .
git commit -m "Initial repo structure"
git push
```

---

## End-of-Week Checklist

- [ ] Advisor emailed re: ECE 337 prerequisite (Monday)
- [ ] Vivado installed and launches without errors
- [ ] Verilator installed (`verilator --version` works)
- [ ] RISC-V GCC installed (`riscv32-unknown-elf-gcc --version` works)
- [ ] VS Code with SystemVerilog extension
- [ ] GitHub repo created and cloned
- [ ] Repo structure committed
- [ ] `blink.sv` and `blink.xdc` in repo
- [ ] Vivado bitstream generated successfully
- [ ] LED blinking on Basys 3 at 1 Hz
- [ ] Short video of blinking LED in `docs/`
- [ ] Harris ch 1-2 read (or skimmed if review)
- [ ] Harris ch 7 intro read carefully
- [ ] Single-cycle datapath sketched on paper

---

## Advisor Email Template

Customize and send Monday morning:

> **Subject:** ECE 337 prerequisite question — Fall 2026 schedule
>
> Hi Professor [Name],
>
> I'm Nishant Bonthala, a Computer Engineering sophomore (PUID 037509430). I'm planning my Fall 2026 schedule and have a prerequisite question.
>
> I'm registered to take ECE 337 in Fall 2026, but ECE 270 is a listed prerequisite. I attempted ECE 270 in Spring 2026 but withdrew before the end of the term — though I achieved 100% on all lab assignments and have a strong working command of the material (sequential logic, FSMs, K-maps, datapath/control design).
>
> I had planned to retake ECE 270 in Summer 2026, but I've decided to commit the summer to a major personal project — a pipelined RV32I processor implementation in SystemVerilog on FPGA — which covers and extends the ECE 270 material in practice.
>
> Would it be possible to take ECE 337 in Fall 2026 with either:
>
> - ECE 270 as a co-requisite,
> - A prerequisite override based on my Spring 2026 lab performance, or
> - ECE 337 deferred to Spring 2027 if it's offered then?
>
> This is important to my BS/MS 4+1 plan. I'm happy to share my Spring 2026 ECE 270 lab grades or discuss further by email or in office hours.
>
> Thank you,
>
> Nishant Bonthala
> Nbonthal@purdue.edu

---

## Reading Focus

**Harris & Harris, Chapter 1-2** — most of this overlaps with ECE 270. Skim for gaps. Pay attention to: number systems (signed, unsigned, sign extension), boolean algebra, CMOS intuition (don't need depth).

**Harris & Harris, Chapter 7 introduction** — read carefully, this sets up the entire summer.
- Sections 7.1 and 7.2: RISC-V ISA overview
- Section 7.3: single-cycle architecture (the foundation of Weeks 3-5)
- Skim 7.4-7.5 for now; you'll revisit when pipelining in Weeks 6-7

When reading 7.3: close the book and draw the datapath from memory. Where you can't, those are your weak spots. Re-read those sections.

---

## Common Week 1 Mistakes

1. **Starting the blink LED before the toolchain is verified.** If Vivado isn't fully working, you'll waste hours on a code problem that's actually an install problem.
2. **Not selecting only the Artix-7 family in the Vivado installer.** 40GB of disk wasted otherwise.
3. **Editing the constraints file in a way that breaks syntax.** XDC files are Tcl — quotes and braces matter.
4. **Copying random Vivado tutorials from YouTube.** Vivado UI changes between versions. Use the official 2024.1 docs.
5. **Treating the LED blink as "too easy" and skipping the validation step.** This is what prevents Week 5 disasters.

---

## If You Get Stuck

Specific error messages have specific solutions. Drop the exact error text in chat — install issues, synthesis errors, bitstream failures, programmer errors — and we'll debug. The most common Week 1 problems all have known fixes.
