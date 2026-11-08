`timescale 1ns / 1ps

module tb_mod_add;

parameter WIDTH = 24;
parameter Q = 8380417;

reg  [WIDTH-1:0] a;
reg  [WIDTH-1:0] b;
wire [WIDTH-1:0] result;

mod_add #(
    .Q(Q),
    .WIDTH(WIDTH)
) uut (
    .a(a),
    .b(b),
    .result(result)
);

initial begin

    // Normal addition
    a = 100;
    b = 200;
    #10;

    // Overflow modulo q
    a = 8380400;
    b = 100;
    #10;

    // Edge case
    a = Q-1;
    b = 1;
    #10;

    // Zero
    a = 0;
    b = 0;
    #10;

    $finish;

end

endmodule