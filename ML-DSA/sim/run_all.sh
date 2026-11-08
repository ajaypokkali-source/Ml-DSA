#!/usr/bin/env bash
# Run every testbench with Icarus Verilog and print a one-line verdict each.
#
#   sim/run_all.sh                 # all testbenches
#   sim/run_all.sh tb_poly_reduce  # one or more, by file name (without .v)
#
# Needs iverilog + vvp (Icarus Verilog 11 or newer, for -g2012 and $urandom_range).
# NOTE: this script has not been run by its author yet (no simulator was available
# when the repo was assembled). The testbenches themselves were run in Vivado XSim.
#
# Verdicts:
#   PASS    self-checking testbench printed "ALL TESTS PASSED"
#   FAIL    log contains FAILED / ERROR / MISMATCH / VIOLATION (or compile error)
#   RAN     stimulus-only testbench: ran to $finish, nothing is checked automatically
#           (inspect the waveform / log by hand)
set -u

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD="$ROOT/sim/build"
mkdir -p "$BUILD"

# rom.v loads "rom_init.mem" by relative path, so run the simulations next to a copy.
cp "$ROOT/rtl/l3_memory/rom_init.mem" "$BUILD/"

RTL=$(find "$ROOT/rtl" -name '*.v' | sort)

if [ "$#" -gt 0 ]; then
  TB_FILES=""
  for name in "$@"; do TB_FILES="$TB_FILES $(find "$ROOT/tb" -name "$name.v")"; done
else
  TB_FILES=$(find "$ROOT/tb" -name 'tb_*.v' | sort)
fi

n_pass=0; n_fail=0; n_ran=0

for tb in $TB_FILES; do
  # Take the top module name from the file: it is not always the file name
  # (tb_montgomery_reduce__mult.v declares "module tb_montgomery").
  top=$(sed -n 's/^[[:space:]]*module[[:space:]]\+\([A-Za-z0-9_]\+\).*/\1/p' "$tb" | head -1)
  vvp_file="$BUILD/$top.vvp"
  log="$BUILD/$top.log"

  if ! iverilog -g2012 -s "$top" -o "$vvp_file" $RTL "$tb" > "$BUILD/$top.compile.log" 2>&1; then
    printf '%-6s %-28s (compile error, see %s)\n' FAIL "$top" "sim/build/$top.compile.log"
    n_fail=$((n_fail+1)); continue
  fi

  ( cd "$BUILD" && timeout 900 vvp -n "$vvp_file" > "$log" 2>&1 )

  if grep -Eq 'FAILED|ERROR|MISMATCH|VIOLATION' "$log"; then
    verdict=FAIL; n_fail=$((n_fail+1))
  elif grep -q 'ALL TESTS PASSED' "$log"; then
    verdict=PASS; n_pass=$((n_pass+1))
  else
    verdict=RAN;  n_ran=$((n_ran+1))
  fi
  printf '%-6s %-28s (%s)\n' "$verdict" "$top" "sim/build/$top.log"
done

echo
echo "pass: $n_pass   fail: $n_fail   ran (stimulus-only): $n_ran"
[ "$n_fail" -eq 0 ]
