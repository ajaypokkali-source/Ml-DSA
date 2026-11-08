`timescale 1ns / 1ps

module tb_register_en;

parameter WIDTH = 32;

reg clk;
reg rst;
reg en;
reg [WIDTH-1:0] d;

wire [WIDTH-1:0] q;

// DUT
register_en #(
    .WIDTH(WIDTH)
) uut (
    .clk(clk),
    .rst(rst),
    .en(en),
    .d(d),
    .q(q)
);

// Clock
always #5 clk = ~clk;

// Test
initial begin

    clk = 0;
    rst = 1;
    en  = 0;
    d   = 0;

    #10;
    rst = 0;

    // Enable ON
    en = 1;
    d = 32'h11111111;
    #10;

    d = 32'h22222222;
    #10;

    // Disable register
    en = 0;
    d = 32'h33333333;
    #10;

    d = 32'h44444444;
    #10;

    // Enable again
    en = 1;
    d = 32'h55555555;
    #10;

    // Reset
    rst = 1;
    #10;

    rst = 0;
    en = 1;
    d = 32'hAAAAAAAA;
    #10;

    $finish;

end

endmodule