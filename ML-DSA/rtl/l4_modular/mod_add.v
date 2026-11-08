`timescale 1ns / 1ps

module mod_add #(
    parameter Q = 8380417,
    parameter WIDTH = 24
)(
    input  wire [WIDTH-1:0] a,
    input  wire [WIDTH-1:0] b,
    output wire [WIDTH-1:0] result
);

wire [WIDTH:0] sum;

assign sum = a + b;

assign result = (sum >= Q) ? (sum - Q) : sum;

endmodule