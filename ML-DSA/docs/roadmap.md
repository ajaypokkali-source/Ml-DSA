# Roadmap

Layer list as planned by the author. Checked = RTL exists and its testbench passes (see `verification.md` for what each
testbench actually checks).

- [x] **Layer 1** register, register_en, counter
- [x] **Layer 2** mux2, mux4, mux8, decoder, encoder, comparator
- [x] **Layer 3** ram_sp, ram_dp, rom, shift_register, fifo
- [x] **Layer 4** mod_add, mod_sub, barrett_reduce, montgomery_reduce, mod_mult
- [ ] **Layer 5** poly_add [x], poly_sub [x], poly_shift [x], poly_reduce [x], pointwise_mult [ ]
- [ ] **Layer 6** ntt, intt, twiddle_rom
- [ ] **Layer 7** theta, rho, pi, chi, iota, keccak_round, keccak_f1600, shake256
- [ ] **Layer 8** ExpandA, ExpandS, ExpandMask, Power2Round, Decompose, MakeHint, UseHint, Pack, Unpack
- [ ] **Layer 9** KeyGen
- [ ] **Layer 10** Signing
- [ ] **Layer 11** Verification

Immediate next step: `pointwise_mult` (FIPS 204 Algorithm 45), then freeze Layer 5.

## How the pieces are used (FIPS 204)

- **KeyGen (Algorithm 6):** seed to `rho`, `rho'`, `K` with SHAKE256; `A = ExpandA(rho)`; `s1, s2 = ExpandS(rho')`;
  `t = A*s1 + s2` in the NTT domain; `Power2Round` splits `t` into `(t1, t0)`; public key `(rho, t1)`.
- **Sign (Algorithm 7), loops until a candidate passes:** `y = ExpandMask`; `w = A*y`; `w1 = HighBits(w)`;
  `c~ = H(mu || w1)`, `c = SampleInBall(c~)`; `z = y + c*s1`; norm checks on `z` and `LowBits(w - c*s2)`; `MakeHint`.
  Signature `(c~, z, h)`.
- **Verify (Algorithm 8):** unpack, rebuild `A`; `w'_Approx = A*z - c*t1*2^d` (this is where `poly_shift` is used);
  `w1' = UseHint(h, w'_Approx)`; accept if the hash of `w1'` matches `c~` and the norm and hint-count checks pass.

## Items the layer list does not name yet

Found by comparing the list with FIPS 204; these are proposals for the author to confirm, not part of the plan.

- **SHAKE128.** `ExpandA` builds each matrix entry with `RejNTTPoly` (Algorithm 30), which uses `G` = SHAKE128
  (`G` is defined on printed page 14; `RejBoundedPoly` and `H` use SHAKE256). Layer 7 lists only SHAKE256;
  SHAKE128 uses the same Keccak-f[1600] core with a different rate and padding.
- **SampleInBall (Algorithm 29).** Builds the challenge polynomial `c`; needed by Sign and Verify.
- **Norm checks.** Sign and Verify compare infinity norms against bounds such as `gamma1 - beta` and `gamma2 - beta`.
- **Vector and matrix operations (Algorithms 46-48).** `AddVectorNTT`, `ScalarVectorNTT`, `MatrixVectorNTT` loop the
  Layer 5 blocks over `k x l` matrices; likely control logic inside Layers 9-11 rather than separate blocks.
