# Design notes

Decisions, preconditions, assumptions and known issues. Section references are to NIST FIPS 204.

## Conventions

- **Layer membership** follows the author's roadmap (see `roadmap.md`), not the FIPS section order.
- **Frozen modules.** A module whose testbench passed is not edited without a functional reason; new needs are met by
  wrapping it (this is why `poly_reduce` adapts `barrett_reduce` instead of changing it).
- **Layer 5 interface.** Flat `N*WIDTH` buses (`N = 256`, `WIDTH = 24`), coefficient `i` at `bus[i*WIDTH +: WIDTH]`,
  unsigned canonical `[0, Q-1]`, fully parallel and combinational. This was chosen because `mod_add`, `mod_sub`
  and the Montgomery blocks are unsigned; only `barrett_reduce` is signed 32-bit.
- **Area.** The fully parallel form is the simplest to verify and costs one primitive per coefficient (256 copies).
  A streaming or partly serial datapath is a later decision, driven by synthesis results.
- `rtl/common/constants.v` holds the ML-DSA-87 parameters as `` `define `` macros; no module includes it yet
  (modules take `Q`, `WIDTH`, `N`, `D` as parameters with defaults).

## Layer 4

### `mod_add`, `mod_sub`
Assume both inputs are already in `[0, Q-1]`. One conditional subtract (`mod_add`) or add (`mod_sub`) is enough only under
that assumption; inputs `>= Q` can give results `>= Q`.

### `barrett_reduce`
ML-DSA `reduce32`: `r = a - ((a + 2^22) >> 23) * Q`, signed 32-bit in and out.
- Documented input range: `|a| <= 2^31 - 2^22 - 1 = 2143289343` (the limit inherited from the Dilithium reference;
  beyond it `a + 2^22` wraps). The testbench's extreme values are exactly at that limit.
- Output range `[-6283008, 6283008]`: **not canonical**, can be negative. This is intended: Layer 6 butterflies
  chain signed values and only need them small, so the signed interface stays.

### `montgomery_reduce_mult`, `montgomery_mult_top`
- `montgomery_reduce_mult(T) = T * R^-1 mod Q`, `R = 2^32`, `Q_PRIME = -Q^-1 mod 2^32 = 4236238847`.
  `R mod Q = 4193792`, `R^-1 mod Q = 8265825`.
- Output is fully reduced to `[0, Q-1]` for `T < Q * 2^32` (the 33-bit `u` is below `2Q`, so one conditional subtract
  is enough). Any product of two values below `Q` satisfies this.
- **Latency: one clock.** `result` and `done` are registered; `start` must be high on the clock edge that samples `T`.
  The multiplier in front of it is combinational.
- **Montgomery form.** `montgomery_mult_top(a_bar, b_bar)` returns `a_bar * b_bar * R^-1 mod Q`. With inputs in Montgomery
  form (`x_bar = x * R mod Q`) the output is the Montgomery form of the product. For the plain product `a*b mod Q`
  the operands must be converted first; this matters for `pointwise_mult`.
- Hardware cost note: one block contains three wide multiplies (`a*b`, `T*Q_PRIME`, `m*Q`).

## Layer 5

### `poly_add`, `poly_sub`
256 copies of `mod_add` / `mod_sub`. `poly_add` is FIPS 204 Algorithm 44 (`AddNTT`); subtraction has no numbered
algorithm and follows the same pattern. Inputs must be canonical (`< Q`).

### `poly_shift`  (assumption)
`c[i] = a[i] << D`, `D = 13`.
**FIPS 204 does not define an algorithm called "Shift".** The implemented meaning is the `t1 * 2^d` rescaling in
verification: the verifier computes `w'_Approx = A*z - c*t1*2^d` (discussion of `ML-DSA.Verify_internal`, printed
page 26), where `t1` is the high part from `Power2Round` (Algorithm 35). If the project's own design documents define
`poly_shift` differently, this module is the only thing to change; nothing depends on it yet.
- It is a raw shift: no reduction, and the result is truncated to `WIDTH` bits.
- Safe range: `t1 <= (Q-1) >> 13 = 1023`; then `t1 << 13 <= Q-1` exactly (checked exhaustively in `sim/golden_models.py`).
  An input of 1024 already reaches `Q`.

### `poly_reduce`
256 copies of `barrett_reduce` (input zero-extended from 24 to 32 bits) followed by one correction: add `Q` if the Barrett
output is negative. One correction is enough: the Barrett output lies in `[-6283008, 6283008]`; a negative value plus `Q`
lands in `[2097409, Q-1]`, and a non-negative one is already below `Q`. Checked exhaustively over all 2^24 inputs in
`sim/golden_models.py`. This is the "polish a polynomial" block with the same canonical interface as the other Layer 5
modules. Layer 6 should instantiate `barrett_reduce` directly on its own signed, wider intermediates rather than reuse it.

### `pointwise_mult` (not started)
FIPS 204 Algorithm 45 (`MultiplyNTT`). Planned as 256 copies of `montgomery_mult_top` with a `start` / `done` handshake
(the Montgomery stage is registered). It will return `a*b*R^-1 mod Q`, which equals the `MultiplyNTT` result only if
operands are kept in Montgomery form; the testbench reference model must be built around that.

## Known issues

1. **`fifo.v`: simultaneous read and write loses an entry.** In one clock with `wr_en && !full` and `rd_en && !empty`,
   both `count <= count + 1` and `count <= count - 1` execute and the last non-blocking assignment wins, so `count`
   drops by one instead of staying the same. Found by reading the code; `tb_fifo` never reads and writes in the same
   cycle. Not fixed here.
2. **`tb_montgomery_reduce__mult.v`: expected value mismatch** (details and proposed fix in `verification.md`). The RTL is fine.
3. **Layers 1-3, `mod_add` and `mod_sub` testbenches do not check anything automatically.**
4. `rom.v` loads `rom_init.mem` with a relative path; run the simulation from a directory that contains it
   (`sim/run_all.sh` does this).
5. The poly and Montgomery blocks have only been simulated functionally; no timing, area or power data exists.
