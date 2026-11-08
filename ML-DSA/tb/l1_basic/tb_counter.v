`timescale 1ns / 1ps

module tb_counter;

parameter WIDTH = 8;

reg clk;
reg rst;
reg en;

wire [WIDTH-1:0] count;

// DUT
counter #(
    .WIDTH(WIDTH)
) uut (
    .clk(clk),
    .rst(rst),
    .en(en),
    .count(count)
);

// Clock
always #5 clk = ~clk;

initial begin

    clk = 0;
    rst = 1;
    en  = 0;

    #10;
    rst = 0;

    // Count
    en = 1;
    #50;

    // Pause
    en = 0;
    #20;

    // Count again
    en = 1;
    #40;

    // Reset
    rst = 1;
    #10;

    rst = 0;
    en = 1;
    #30;

    $finish;

end

endmodule