`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name : poly_add
// Layer       : 5 - Polynomial Arithmetic
//
// Description :
//   Coefficient-wise polynomial addition over Z_q, matching FIPS 204
//   Algorithm 44 (AddNTT):
//
//       c[i] = (a[i] + b[i]) mod Q,   for i = 0 .. N-1
//
//   Structural wrapper only - no new arithmetic. Instantiates N copies of
//   the VERIFIED/FROZEN Layer 4 mod_add block, one per coefficient.
//
// Interface :
//   Fully parallel. All N coefficients are presented and returned
//   simultaneously as flattened buses (combinational, 0-cycle latency).
//   Coefficient i occupies bits [i*WIDTH +: WIDTH] of each bus.
//
// Representation :
//   Unsigned canonical, coefficients in [0, Q-1]. Matches mod_add as-is.
//
// Depends on : mod_add (Layer 4, VERIFIED/FROZEN)
//////////////////////////////////////////////////////////////////////////////////

module poly_add #(
    parameter Q     = 8380417,
    parameter WIDTH = 24,
    parameter N     = 256
)(
    input  wire [N*WIDTH-1:0] a,
    input  wire [N*WIDTH-1:0] b,
    output wire [N*WIDTH-1:0] result
);

genvar i;
generate
    for (i = 0; i < N; i = i + 1) begin : COEFF

        mod_add #(
            .Q     (Q),
            .WIDTH (WIDTH)
        ) u_mod_add (
            .a      (a[i*WIDTH +: WIDTH]),
            .b      (b[i*WIDTH +: WIDTH]),
            .result (result[i*WIDTH +: WIDTH])
        );

    end
endgenerate

endmodule
