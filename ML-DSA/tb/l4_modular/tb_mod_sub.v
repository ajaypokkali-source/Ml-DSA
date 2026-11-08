`timescale 1ns / 1ps

module tb_mod_sub;

parameter WIDTH = 24;
parameter Q = 8380417;

reg  [WIDTH-1:0] a;
reg  [WIDTH-1:0] b;

wire [WIDTH-1:0] result;

mod_sub #(
    .Q(Q),
    .WIDTH(WIDTH)
) uut (
    .a(a),
    .b(b),
    .result(result)
);

initial begin

    // Normal subtraction
    a = 500;
    b = 200;
    #10;

    // Wrap around modulo q
    a = 50;
    b = 100;
    #10;

    // Edge case
    a = 0;
    b = 0;
    #10;

    // q-1
    a = Q-1;
    b = 1;
    #10;

    $finish;

end

endmodule