`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name : poly_reduce
// Layer       : 5 - Polynomial Arithmetic
//
// Description :
//   Coefficient-wise Barrett reduction into canonical range, applied to a
//   whole polynomial:
//
//       result[i] = a[i] mod Q,   in [0, Q-1],   for i = 0 .. N-1
//
//   Built from N copies of the VERIFIED/FROZEN Layer 4 barrett_reduce block
//   (reduce32), plus a small per-coefficient canonicalization step.
//
// Why the canonicalization step is needed :
//   barrett_reduce's own verified contract is a *non-canonical* "roughly
//   reduced" signed output: r in [-6283008, 6283008], not necessarily >= 0.
//   That is intentional and correct for barrett_reduce itself (it is sized
//   for Layer 6's NTT butterfly intermediates, which are signed and can be
//   negative). poly_reduce's job, however, is to hand back a polynomial in
//   the same unsigned canonical [0, Q-1] convention that poly_add/poly_sub/
//   poly_shift already use, so every Layer 5 block composes cleanly.
//
//   Correction: if barrett_reduce's raw output r is negative, add Q once.
//   Proof this single correction always suffices (no loop needed):
//     - r in [-6283008, 6283008]  (verified barrett_reduce output range)
//     - if r < 0: r + Q in [8380417-6283008, 8380417-1] = [2097409, Q-1]  -> canonical
//     - if r >= 0: r already in [0, 6283008] subset of [0, Q-1]          -> canonical
//   Same single-conditional-add pattern already used in mod_sub.
//
// Note on scope :
//   poly_reduce is NOT a generic drop-in replacement for barrett_reduce.
//   It assumes an unsigned WIDTH-bit input bus (not an arbitrary signed
//   32-bit butterfly intermediate) and always canonicalizes its output.
//   Layer 6 (NTT/INTT) should instantiate barrett_reduce directly for its
//   own signed, wider-range internal reduction needs rather than reusing
//   this block.
//
// Interface :
//   Fully parallel. All N coefficients presented/returned simultaneously as
//   flattened buses (combinational, 0-cycle latency). Coefficient i occupies
//   bits [i*WIDTH +: WIDTH] of each bus.
//
// Representation :
//   Unsigned canonical, WIDTH bits per coefficient in, WIDTH bits per
//   coefficient out, always in [0, Q-1] - matches poly_add/poly_sub/poly_shift.
//
// Depends on : barrett_reduce (Layer 4, VERIFIED/FROZEN)
//////////////////////////////////////////////////////////////////////////////////

module poly_reduce #(
    parameter Q     = 8380417,
    parameter WIDTH = 24,
    parameter N     = 256
)(
    input  wire [N*WIDTH-1:0] a,
    output wire [N*WIDTH-1:0] result
);

genvar i;
generate
    for (i = 0; i < N; i = i + 1) begin : COEFF

        wire signed [31:0] a_signed;
        wire signed [31:0] r_raw;
        wire signed [31:0] r_canonical;

        // Unsigned WIDTH-bit input -> signed 32-bit, zero-extended.
        // Always non-negative and well within barrett_reduce's verified
        // input domain, so this cast is lossless and safe.
        assign a_signed = $signed({{(32-WIDTH){1'b0}}, a[i*WIDTH +: WIDTH]});

        barrett_reduce u_barrett_reduce (
            .a (a_signed),
            .r (r_raw)
        );

        // Single conditional correction - see proof above.
        assign r_canonical = (r_raw < 0) ? (r_raw + Q) : r_raw;

        // Canonical result fits safely in WIDTH bits ([0, Q-1] < 2^WIDTH).
        assign result[i*WIDTH +: WIDTH] = r_canonical[WIDTH-1:0];

    end
endgenerate

endmodule
