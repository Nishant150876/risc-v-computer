#!/usr/bin/env python3
"""Build and run every Verilator testbench and print a pass/fail table.

Discovery rules:
  * every tb/**/<name>_tb.sv is one test; its top module must be <name>_tb
  * every rtl/**/*.sv file is compiled with each test (packages, *_pkg.sv,
    go first so later files can import them)

A test passes only when Verilator builds it, the simulation exits with
status 0 within the timeout, and its output contains a line starting with
"PASS". A bench that finishes without saying PASS is treated as a failure,
so a missing $display cannot hide a test that checked nothing.

Usage (WSL, from anywhere):
    python3 scripts/run_tests.py                # all tests
    python3 scripts/run_tests.py counter        # tests whose name contains "counter"
    python3 scripts/run_tests.py -v             # show each test's output
    python3 scripts/run_tests.py --list         # list tests without running
"""

from __future__ import annotations

import argparse
import os
import shutil
import subprocess
import sys
import time
from dataclasses import dataclass
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
RTL_DIR = REPO / "rtl"
TB_DIR = REPO / "tb"
# Keep generated files off the Windows/OneDrive mount (see docs/PHASE0_SMOKE_TEST.md).
DEFAULT_BUILD = Path(os.environ.get(
    "RVC_BUILD_DIR", Path.home() / ".cache" / "risc-v-computer" / "tests"))

VERILATOR_FLAGS = ["--binary", "--timing", "--assert", "-Wall"]


@dataclass
class Result:
    name: str
    status: str  # PASS, FAIL, BUILD, TIMEOUT
    seconds: float
    detail: str
    log: str


def rtl_sources() -> list[Path]:
    files = sorted(RTL_DIR.rglob("*.sv"))
    pkgs = [f for f in files if f.stem.endswith("_pkg")]
    return pkgs + [f for f in files if f not in pkgs]


def find_tests(pattern: str | None) -> list[Path]:
    tests = sorted(TB_DIR.rglob("*_tb.sv"))
    if pattern:
        tests = [t for t in tests if pattern in t.stem]
    return tests


def last_line(text: str) -> str:
    lines = [l.strip() for l in text.strip().splitlines() if l.strip()]
    return lines[-1][:100] if lines else ""


def first_error(text: str) -> str:
    text = text.replace(str(REPO) + os.sep, "")
    for line in text.splitlines():
        if line.startswith("%Error") or line.startswith("%Warning"):
            return line.strip()[:100]
    return last_line(text)


def run_one(tb: Path, build_root: Path, jobs: int, timeout: float) -> Result:
    name = tb.stem
    mdir = build_root / name
    if mdir.exists():
        shutil.rmtree(mdir)
    mdir.mkdir(parents=True)
    start = time.monotonic()

    cmd = ["verilator", *VERILATOR_FLAGS, "-j", str(jobs),
           "--top-module", name, "--Mdir", str(mdir),
           *[str(s) for s in rtl_sources()], str(tb)]
    build = subprocess.run(cmd, cwd=REPO, capture_output=True, text=True)
    build_log = build.stdout + build.stderr
    if build.returncode != 0:
        return Result(name, "BUILD", time.monotonic() - start,
                      first_error(build_log), build_log)

    try:
        sim = subprocess.run([str(mdir / f"V{name}")], cwd=REPO,
                             capture_output=True, text=True, timeout=timeout)
    except subprocess.TimeoutExpired as exc:
        out = (exc.stdout or b"").decode() if isinstance(exc.stdout, bytes) else (exc.stdout or "")
        return Result(name, "TIMEOUT", time.monotonic() - start,
                      f"no exit after {timeout:.0f} s", out)

    log = sim.stdout + sim.stderr
    elapsed = time.monotonic() - start
    said_pass = any(l.startswith("PASS") for l in sim.stdout.splitlines())
    if sim.returncode == 0 and said_pass:
        pass_line = next(l for l in sim.stdout.splitlines() if l.startswith("PASS"))
        return Result(name, "PASS", elapsed, pass_line[:100], log)
    if sim.returncode == 0:
        return Result(name, "FAIL", elapsed, "exited 0 but never printed PASS", log)
    return Result(name, "FAIL", elapsed,
                  f"exit {sim.returncode}: {first_error(log) or last_line(log)}", log)


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("pattern", nargs="?", help="only run tests whose name contains this")
    ap.add_argument("-v", "--verbose", action="store_true", help="print every test's output")
    ap.add_argument("--list", action="store_true", help="list tests and exit")
    ap.add_argument("--build-dir", type=Path, default=DEFAULT_BUILD,
                    help=f"where generated files go (default {DEFAULT_BUILD})")
    ap.add_argument("-j", "--jobs", type=int, default=max(1, min(4, os.cpu_count() or 1)),
                    help="Verilator compile jobs per test")
    ap.add_argument("--timeout", type=float, default=60.0,
                    help="seconds a simulation may run before it fails")
    args = ap.parse_args()

    tests = find_tests(args.pattern)
    if args.list:
        for t in tests:
            print(t.relative_to(REPO))
        return 0
    if not tests:
        print(f"No testbenches found in {TB_DIR.relative_to(REPO)}/"
              + (f" matching '{args.pattern}'" if args.pattern else ""))
        return 1
    if shutil.which("verilator") is None:
        print("verilator not found on PATH (run this from WSL)")
        return 1

    ver = subprocess.run(["verilator", "--version"], capture_output=True, text=True)
    print(f"{ver.stdout.strip()}  |  {len(tests)} test(s)  |  build: {args.build_dir}\n")

    results = []
    for tb in tests:
        print(f"  running {tb.stem} ...", end="", flush=True)
        r = run_one(tb, args.build_dir, args.jobs, args.timeout)
        print(f" {r.status}")
        results.append(r)
        if args.verbose or r.status != "PASS":
            print("    " + "\n    ".join(r.log.strip().splitlines()[-40:]))

    w = max(len("Test"), *(len(r.name) for r in results))
    print(f"\n{'Test':<{w}}  {'Result':<7}  {'Time':>6}  Detail")
    print(f"{'-' * w}  {'-' * 7}  {'-' * 6}  {'-' * 40}")
    for r in results:
        print(f"{r.name:<{w}}  {r.status:<7}  {r.seconds:5.1f}s  {r.detail}")
    passed = sum(r.status == "PASS" for r in results)
    print(f"\n{passed}/{len(results)} passed")
    return 0 if passed == len(results) else 1


if __name__ == "__main__":
    sys.exit(main())
