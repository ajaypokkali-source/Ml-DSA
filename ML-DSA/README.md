# ML-DSA-87 hardware accelerator (Verilog RTL)

Verilog RTL for an FPGA accelerator of **ML-DSA-87** (NIST FIPS 204, formerly CRYSTALS-Dilithium).
The design is built bottom-up in layers; each block gets a testbench before the layer above uses it.

- Modulus `Q = 8380417`, polynomials of 256 coefficients, ML-DSA-87 parameters `(k, l) = (8, 7)`.
- Target tool flow: Vivado (XSim). Everything here is plain Verilog.

## Status

| Layer | Blocks | Testbench status |
|---|---|---|
| 1 | `register`, `register_en`, `counter` | stimulus only (inspect waveform) |
| 2 | `mux2`, `mux4`, `mux8`, `decoder`, `encoder`, `comparator` | stimulus only |
| 3 | `ram_sp`, `ram_dp`, `rom`, `shift_register`, `fifo` | stimulus only; see known issue in `fifo` |
| 4 | `mod_add`, `mod_sub` | stimulus only (4 vectors each) |
| 4 | `barrett_reduce` | self-checking: 530 tests + range and modular-equivalence checks |
| 4 | `multiplier`, `montgomery_reduce_mult`, `montgomery_mult_top` | self-checking; one testbench has a wrong expected value |
| 5 | `poly_add`, `poly_sub`, `poly_shift`, `poly_reduce` | self-checking, all pass in Vivado XSim |
| 5 | `pointwise_mult` | not started |
| 6-11 | NTT/INTT, Keccak/SHAKE, sampling and rounding, KeyGen, Sign, Verify | not started |

Details, including what each testbench does and does not prove: [docs/verification.md](docs/verification.md).
Design decisions, assumptions and known issues: [docs/design-notes.md](docs/design-notes.md).
Remaining work: [docs/roadmap.md](docs/roadmap.md).

## Layout

```
rtl/
  common/       constants.v (ML-DSA-87 parameters as `define macros, not yet used by the modules)
  l1_basic/     register, register_en, counter
  l2_logic/     mux2, mux4, mux8, decoder, encoder, comparator
  l3_memory/    ram_sp, ram_dp, rom (+ rom_init.mem), shift_register, fifo
  l4_modular/   mod_add, mod_sub, barrett_reduce, multiplier, montgomery_reduce_mult, montgomery_mult_top
  l5_poly/      poly_add, poly_sub, poly_shift, poly_reduce
tb/             one tb_<module>.v per module, same folder split as rtl/
sim/            run_all.sh, create_vivado_project.tcl, golden_models.py
docs/           verification.md, design-notes.md, roadmap.md
```

Layer 4 names differ from the original roadmap: `montgomery_reduce` is `montgomery_reduce_mult.v`,
and `mod_mult` is `montgomery_mult_top.v` (which wires `multiplier` into `montgomery_reduce_mult`).

## Conventions (Layer 5)

- A polynomial is a flat bus of `N*WIDTH` bits (`N = 256`, `WIDTH = 24`); coefficient `i` is `bus[i*WIDTH +: WIDTH]`.
- Coefficients are unsigned and canonical, in `[0, Q-1]`, unless a module's header says otherwise.
- Layer 5 blocks are fully parallel and combinational: one frozen Layer 4 primitive per coefficient
  (`poly_shift` is plain wiring and needs no primitive).

## Running the tests

Vivado: `vivado -mode batch -source sim/create_vivado_project.tcl`, then set a `tb_*` module as the simulation top.
Icarus Verilog: `sim/run_all.sh` (prints PASS / FAIL / RAN per testbench).
Python models (no simulator needed): `python3 sim/golden_models.py`.

`run_all.sh` and `create_vivado_project.tcl` were written without access to a simulator and have **not been run yet**.
The testbenches themselves were run in Vivado XSim by the author.

## References

- NIST FIPS 204, Module-Lattice-Based Digital Signature Standard: https://doi.org/10.6028/NIST.FIPS.204
- NIST FIPS 202, SHA-3 Standard (needed for the later Keccak/SHAKE layers): https://doi.org/10.6028/NIST.FIPS.202
