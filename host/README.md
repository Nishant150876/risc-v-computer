# 🐍 `host/`: development-side Python tools

> [!NOTE]
> **Status: 📋 PLANNED.** This folder holds only a `.gitkeep` placeholder. No tool exists yet.
> Status labels are defined in the [root README](../README.md#status).

[← Back to the project README](../README.md)

## What will live here

Python tools that run on the **development computer**, not on the CPU or the Tab5:

| Tool | Job | Milestone |
| --- | --- | --- |
| Protocol client | Speaks the [debug protocol](../docs/DEBUG_PROTOCOL.md) to the FPGA over a serial port, so the debug hardware can be tested before the Tab5 is involved | T2 onward |
| Program preparation | Generates program manifests (sizes, CRC-32, `.bss` and stack bounds) from the real ELF and linker output, ready for microSD | T5 |
| Reference tools | Produce independent expected results for comparison tests | T12 |

```mermaid
flowchart LR
    ELF["prog.elf from sw/"] --> PREP["host preparation tool"]
    PREP --> SD["manifest.json + program.bin<br/>for the Tab5 microSD"]
    CLI["host protocol client"] <-- "debug UART" --> FPGA["FPGA debug hardware"]
    VEC["protocol/ golden vectors"] --> CLI
```

## Ground rules

- The protocol client is an **independent** implementation checked against the shared golden
  vectors in [`protocol/`](../protocol/README.md), so the FPGA codec is never tested only
  against itself.
- Prefer the Python standard library; declare a serial-port dependency when it is introduced.
- These tools are for development and testing. The final portable demonstration must work
  without a laptop, so nothing here is required at runtime.

## Related

- The protocol: [DEBUG_PROTOCOL.md](../docs/DEBUG_PROTOCOL.md)
- Manifest rules: [TAB5_INTEGRATION.md](../docs/TAB5_INTEGRATION.md#program-images-loading-and-launch)
- Build scripts (separate from these tools): [scripts/README.md](../scripts/README.md)
