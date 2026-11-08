#!/usr/bin/env python3
"""
Independent golden models and contract checks for the ML-DSA-87 RTL
(Layers 4 and 5). Pure Python; numpy is used for the exhaustive sweep if present.

These are bit-accurate models written from the RTL, checked against reference
mathematics (plain modular arithmetic / pow(R, -1, Q)). They are a second,
simulator-independent line of evidence next to the Verilog testbenches.

Usage:  python3 sim/golden_models.py [--quick]
        --quick skips the 2^24 exhaustive poly_reduce sweep.
Exit status is non-zero if any check fails.
"""
import random
import sys

Q = 8380417          # ML-DSA modulus (FIPS 204)
D = 13               # dropped bits (FIPS 204, Power2Round)
R = 1 << 32          # Montgomery radix used by montgomery_reduce_mult
Q_PRIME = 4236238847 # montgomery_reduce_mult's Q_PRIME
R_MOD_Q = 4193792    # R mod Q, as used in the Montgomery testbenches

failures = 0


def report(name, ok, detail=""):
    global failures
    if not ok:
        failures += 1
    print(f"[{'PASS' if ok else 'FAIL'}] {name}" + (f"  ({detail})" if detail else ""))


# --------------------------------------------------------------------------
# Layer 4: Montgomery reduction (montgomery_reduce_mult.v)
# --------------------------------------------------------------------------
def redc_rtl(T):
    """Bit-accurate model of montgomery_reduce_mult.v (T is 64-bit)."""
    t_qprime = (T * Q_PRIME) & ((1 << 96) - 1)
    m = t_qprime & 0xFFFFFFFF
    m_times_q = (m * Q) & ((1 << 64) - 1)
    s = (T + m_times_q) & ((1 << 65) - 1)
    u = (s >> 32) & ((1 << 33) - 1)
    return (u - Q) & 0xFFFFFFFF if u >= Q else u & 0xFFFFFFFF


def redc_ref(T):
    return (T * pow(R, -1, Q)) % Q


def check_montgomery(n=200_000):
    report("Q * Q_PRIME == -1 (mod 2^32)", (Q * Q_PRIME) % R == R - 1)
    report("R mod Q == 4193792 (constant used by the testbenches)", R % Q == R_MOD_Q)
    rng = random.Random(42)
    bad = 0
    pairs = [(0, 0), (1, 1), (1, 5), (5, 7), (100, 200), (1234, 5678), (Q - 1, 1), (Q - 1, Q - 1)]
    pairs += [(rng.randrange(Q), rng.randrange(Q)) for _ in range(n)]
    for a, b in pairs:
        if redc_rtl(a * b) != redc_ref(a * b):
            bad += 1
    report("montgomery_reduce_mult == T * R^-1 mod Q", bad == 0, f"{len(pairs)} vectors, {bad} mismatches")


def check_tb_montgomery_reduce_expectation(n=10_000):
    """tb_montgomery_reduce__mult.v expects ((a*b % Q) * R_MOD_Q) % Q.
    The RTL computes a*b * R^-1 mod Q. Count how often they disagree."""
    rng = random.Random(1)
    pairs = [(0, 0), (1, 1), (1, 5), (5, 7), (100, 200), (1234, 5678), (Q - 1, 1), (Q - 1, Q - 1)]
    pairs += [(rng.randrange(Q), rng.randrange(Q)) for _ in range(n)]
    disagree = sum(1 for a, b in pairs if ((a * b % Q) * R_MOD_Q) % Q != redc_rtl(a * b))
    zero_products = sum(1 for a, b in pairs if a * b % Q == 0)
    # A testbench written for the RTL's behaviour would show 0 disagreements.
    # Reported as informational (not counted as a failure of the RTL checks):
    # it is a finding about the testbench, see docs/verification.md.
    status = "OK" if disagree == 0 else "KNOWN-ISSUE"
    print(f"[{status}] tb_montgomery_reduce__mult expected value vs RTL output  "
          f"({disagree} of {len(pairs)} vectors disagree; {zero_products} have a zero product)")
    return disagree


# --------------------------------------------------------------------------
# Layer 4: mod_add / mod_sub (single coefficient)
# --------------------------------------------------------------------------
def mod_add_rtl(a, b):
    s = a + b
    return (s - Q if s >= Q else s) & 0xFFFFFF


def mod_sub_rtl(a, b):
    return ((a - b) if a >= b else (a + Q - b)) & 0xFFFFFF


def check_mod_add_sub(n=2_000_000):
    rng = random.Random(7)
    corners = [0, 1, 2, Q // 2, Q - 2, Q - 1]
    pairs = [(a, b) for a in corners for b in corners]
    pairs += [(rng.randrange(Q), rng.randrange(Q)) for _ in range(n)]
    bad_add = sum(1 for a, b in pairs if mod_add_rtl(a, b) != (a + b) % Q)
    bad_sub = sum(1 for a, b in pairs if mod_sub_rtl(a, b) != (a - b) % Q)
    report("mod_add == (a+b) mod Q on [0,Q-1]^2", bad_add == 0, f"{len(pairs)} pairs, {bad_add} mismatches")
    report("mod_sub == (a-b) mod Q on [0,Q-1]^2", bad_sub == 0, f"{len(pairs)} pairs, {bad_sub} mismatches")


# --------------------------------------------------------------------------
# Layer 5: poly_shift contract (single coefficient)
# --------------------------------------------------------------------------
def check_poly_shift():
    t1_max = (Q - 1) >> D
    ok = all(((t << D) < Q) and ((t << D) < (1 << 24)) and ((t << D) == t * 2**D) for t in range(t1_max + 1))
    report("poly_shift: exact and < Q for every t1 in [0, (Q-1)>>13]", ok, f"t1_max = {t1_max}")
    report("poly_shift: contract boundary is exact ((Q-1)>>13)<<13 == Q-1 and next value overflows Q",
           (t1_max << D) == Q - 1 and ((t1_max + 1) << D) >= Q)


# --------------------------------------------------------------------------
# Layer 5: poly_reduce contract (single coefficient), exhaustive over 24 bits
# --------------------------------------------------------------------------
def reduce32(x):
    t = (x + 4194304) >> 23
    return x - t * Q


def poly_reduce_ref(x):
    r = reduce32(x)
    return r + Q if r < 0 else r


def check_poly_reduce(quick):
    # raw reduce32 output range claimed for barrett_reduce
    probe = [0, 1, Q - 1, Q, Q + 1, 2 * Q, (1 << 24) - 1]
    report("reduce32 stays within [-6283008, 6283008] on probe values",
           all(-6283008 <= reduce32(x) <= 6283008 for x in probe))
    if quick:
        report("poly_reduce exhaustive sweep", True, "skipped (--quick)")
        return
    try:
        import numpy as np
        x = np.arange(1 << 24, dtype=np.int64)
        r = x - ((x + 4194304) >> 23) * Q
        c = np.where(r < 0, r + Q, r)
        in_range = bool(((c >= 0) & (c < Q)).all())
        congruent = bool((((x - c) % Q) == 0).all())
        n = x.size
    except ImportError:
        in_range = congruent = True
        n = 1 << 24
        for v in range(n):
            c = poly_reduce_ref(v)
            if not (0 <= c < Q) or (v - c) % Q:
                in_range = congruent = False
                break
    report("poly_reduce: output in [0, Q-1] for every 24-bit input", in_range, f"{n} inputs")
    report("poly_reduce: output == input (mod Q) for every 24-bit input", congruent, f"{n} inputs")


if __name__ == "__main__":
    quick = "--quick" in sys.argv
    check_montgomery()
    check_tb_montgomery_reduce_expectation()
    check_mod_add_sub()
    check_poly_shift()
    check_poly_reduce(quick)
    print()
    print("ALL CHECKS PASSED" if failures == 0 else f"{failures} CHECK(S) FAILED")
    sys.exit(1 if failures else 0)
