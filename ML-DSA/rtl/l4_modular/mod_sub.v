`timescale 1ns / 1ps

module mod_sub #(
    parameter Q = 8380417,
    parameter WIDTH = 24
)(
    input  wire [WIDTH-1:0] a,
    input  wire [WIDTH-1:0] b,
    output wire [WIDTH-1:0] result
);

assign result = (a >= b) ? (a - b) : (a + Q - b);

endmodule