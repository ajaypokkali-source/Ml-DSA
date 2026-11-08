`timescale 1ns / 1ps

module tb_comparator;

parameter WIDTH = 32;

reg [WIDTH-1:0] a;
reg [WIDTH-1:0] b;

wire eq;
wire gt;
wire lt;

comparator #(
    .WIDTH(WIDTH)
) uut (
    .a(a),
    .b(b),
    .eq(eq),
    .gt(gt),
    .lt(lt)
);

initial begin

    a = 10; b = 10; #10;
    a = 20; b = 10; #10;
    a = 5;  b = 10; #10;
    a = 100; b = 99; #10;

    $finish;

end

endmodule