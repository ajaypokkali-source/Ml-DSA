`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 15.09.2026 09:42:38
// Design Name: 
// Module Name: montgomery_mult_top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module montgomery_mult_top (
    input         clk,
    input         rst,
    input         start,

    input  [31:0] a_bar,
    input  [31:0] b_bar,

    output [63:0] product,
    output [31:0] result,
    output        done
);

    multiplier u_multiplier (
        .a(a_bar),
        .b(b_bar),
        .product(product)
    );

    montgomery_reduce_mult u_montgomery_reduce (
        .clk(clk),
        .rst(rst),
        .start(start),
        .T(product),
        .result(result),
        .done(done)
    );

endmodule