# Verification status

Method used for the arithmetic layers: RTL, golden reference model, self-checking testbench with directed and
random vectors, mathematical property checks, then "frozen" (not modified without a functional reason).
Layers 1-3 and `mod_add`/`mod_sub` predate that method: their testbenches only drive inputs.

"Author-run" means the author ran the testbench in Vivado XSim and reported the result; those runs are not
reproduced by anything in this repo's automation yet. "Python" means `sim/golden_models.py`, which was run
when the repo was assembled.

## Layers 1-3 and `mod_add` / `mod_sub`: stimulus only

These testbenches apply a handful of inputs and end with `$finish`. They contain no assertions and print nothing,
so a pass or fail has to be judged by reading the waveform. `sim/run_all.sh` reports them as `RAN`.

| Testbench | Stimulus |
|---|---|
| `tb_register`, `tb_register_en`, `tb_counter` | a few values, reset, enable on/off |
| `tb_mux2`, `tb_mux4`, `tb_mux8`, `tb_decoder`, `tb_encoder` | every select / one-hot input once |
| `tb_comparator` | 4 pairs (equal, greater, less, greater by one) |
| `tb_ram_sp`, `tb_ram_dp`, `tb_rom`, `tb_shift_register`, `tb_fifo` | one write/read sequence each |
| `tb_mod_add`, `tb_mod_sub` | 4 vectors each (normal, wrap, zero, `Q-1`) |

Independent evidence for `mod_add` / `mod_sub` (Python): the RTL formulas match `(a+b) mod Q` and `(a-b) mod Q`
on 2,000,036 pairs from `[0, Q-1]` (36 corner pairs plus 2,000,000 random), 0 mismatches.

## `barrett_reduce` (Layer 4)

Self-checking. Golden model: the ML-DSA `reduce32` (`t = (x + 2^22) >> 23; r = x - t*Q`).
30 directed tests (small values, around `Q` and `2Q`, negative, extreme positive and negative) plus 500 random.
Property checks: `-6283008 <= r <= 6283008` and `(a - r) mod Q == 0` (64-bit signed difference).
Result (author-run, from the project notes): 530 total, 530 passed, 0 failed.

## `multiplier`, `montgomery_reduce_mult`, `montgomery_mult_top` (Layer 4)

`montgomery_reduce_mult` computes `T * R^-1 mod Q` with `R = 2^32` and `Q_PRIME = 4236238847`.

- Python: `Q * Q_PRIME == -1 (mod 2^32)`; a bit-accurate model of the RTL equals `T * R^-1 mod Q` on 200,008
  vectors (8 directed products plus 200,000 random pairs from `[0, Q-1]`), 0 mismatches.
- `tb_montgomery_mult_top.v`: inputs are converted to Montgomery form (`a * R mod Q`) before the DUT and the
  expected result is `(a*b mod Q) * R mod Q`. That is consistent with the RTL. 18 vectors (9 directed, 9 random).
  Not yet reported as run.
- `tb_montgomery_reduce__mult.v` (module name `tb_montgomery`): **expected value looks wrong.**
  It expects `((a*b) mod Q) * R mod Q` from the reduction block, but the block returns `(a*b) * R^-1 mod Q`.
  `R^2 mod Q = 2365951`, not 1, so these differ. In Python, 10,007 of the 10,008 vectors it uses (8 directed plus
  10,000 random) disagree with the RTL; only `(0, 0)` agrees. Expected outcome in simulation: `MONTGOMERY ERROR`
  on almost every vector. The RTL is not suspected; the fix would be to compute the expected value as
  `(a*b) * 8265825 mod Q` (`8265825 = R^-1 mod Q`). Not changed here because Layer 4 is marked frozen.
  Not yet reported as run.

## Layer 5

All four testbenches are self-checking and report `ALL TESTS PASSED` when clean. Author-run result in Vivado XSim:
all four pass. Coefficient checks per run follow from each testbench's vector count (vectors x 256 coefficients).

| Module | Golden model | Vectors | Coefficient checks | Extra property checks |
|---|---|---|---|---|
| `poly_add` | `(x+y)` then subtract `Q` if `>= Q` | 6 directed + 500 random | 129,536 | output `< Q` |
| `poly_sub` | `x-y`, add `Q` if `x < y` | 6 directed + 500 random | 129,536 | output `< Q` |
| `poly_shift` | `x << 13`, truncated to 24 bits | 7 directed + 500 random (300 in the `t1` range, 200 full width) | 129,792 (matches the printed count) | for `t1 <= (Q-1)>>13`: exact `t1 * 2^13` and `< Q` |
| `poly_reduce` | the `reduce32` model above, plus `+Q` if negative | 10 directed + 600 random (400 full 24-bit, 200 canonical) | 156,160 | output in `[0, Q-1]`; `(a - r) mod Q == 0` |

Python adds exhaustive single-coefficient evidence for the two modules whose input space is small enough:

- `poly_reduce`: for every one of the 16,777,216 possible 24-bit inputs, the output is in `[0, Q-1]` and congruent to the input.
- `poly_shift`: for every `t1` in `[0, 1023]` the shift is exact and below `Q`; `1023 << 13 = Q - 1`, and `1024 << 13 >= Q`.

## Not covered anywhere yet

- Hardware results: no synthesis, timing or resource numbers exist.
- Integration: no test connects Layer 5 blocks to each other or to Layer 4 beyond what each wrapper instantiates.
- Known-answer tests against FIPS 204 / reference vectors start with Layer 6.
