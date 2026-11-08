`timescale 1ns / 1ps

module tb_register;

parameter WIDTH = 32;

reg clk;
reg rst;
reg [WIDTH-1:0] d;

wire [WIDTH-1:0] q;

// Instantiate DUT
register #(
    .WIDTH(WIDTH)
) uut (
    .clk(clk),
    .rst(rst),
    .d(d),
    .q(q)
);

// Clock generation
always #5 clk = ~clk;

// Test sequence
initial begin

    clk = 0;
    rst = 1;
    d = 0;

    #10;
    rst = 0;

    d = 32'h12345678;
    #10;

    d = 32'hAAAAAAAA;
    #10;

    d = 32'h55555555;
    #10;

    rst = 1;
    #10;

    rst = 0;
    d = 32'hDEADBEEF;
    #10;

    $finish;

end

endmodule