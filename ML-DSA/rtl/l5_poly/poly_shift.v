`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name : poly_shift
// Layer       : 5 - Polynomial Arithmetic
//
// Description :
//   Coefficient-wise left shift by D bits:
//
//       c[i] = a[i] << D,   for i = 0 .. N-1
//
//   Used to rescale t1 (the high-order output of Power2Round, Algorithm 35)
//   back up by 2^D before it is combined/compared with full-width values
//   during Verify, i.e. t1 * 2^D.
//
//   ASSUMPTION: FIPS 204 does not define a numbered algorithm named "Shift".
//   Section 3.6.4 only mentions bit-shifts generically as a division
//   avoidance technique. This module's semantics (plain left shift by D,
//   matching the reference Dilithium implementation's poly_shiftl) are an
//   assumption on my part, not a direct spec citation. If the project's own
//   design documents define poly_shift differently, this module should be
//   corrected to match - nothing downstream depends on this assumption yet.
//
// Interface :
//   Fully parallel. All N coefficients presented/returned simultaneously as
//   flattened buses (combinational, 0-cycle latency). Coefficient i occupies
//   bits [i*WIDTH +: WIDTH] of each bus.
//
// Representation :
//   Unsigned canonical, WIDTH bits per coefficient - matches poly_add/poly_sub.
//
// IMPORTANT - no modular reduction here:
//   This is a raw hardware left shift. The output is truncated to WIDTH
//   bits, like any fixed-width shift. It is the caller's responsibility to
//   ensure the input magnitude is small enough that a[i] << D does not
//   overflow WIDTH bits.
//
//   For the real FIPS 204 usage (shifting t1, which by construction satisfies
//   t1 <= (Q-1) >> D =~ 1023), the shifted result stays below Q and fits
//   safely within WIDTH=24 bits - no overflow occurs in that case.
//
//   For an arbitrary/oversized input this module does NOT reduce mod Q and
//   does NOT flag overflow. Follow with poly_reduce if range safety against
//   arbitrary inputs is ever required.
//
// Depends on : none (pure combinational wiring, no Layer 4 primitive needed)
//////////////////////////////////////////////////////////////////////////////////

module poly_shift #(
    parameter Q     = 8380417,
    parameter WIDTH = 24,
    parameter N     = 256,
    parameter D     = 13
)(
    input  wire [N*WIDTH-1:0] a,
    output wire [N*WIDTH-1:0] result
);

genvar i;
generate
    for (i = 0; i < N; i = i + 1) begin : COEFF

        assign result[i*WIDTH +: WIDTH] = a[i*WIDTH +: WIDTH] << D;

    end
endgenerate

endmodule
