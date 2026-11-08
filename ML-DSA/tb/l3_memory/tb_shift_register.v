`timescale 1ns / 1ps

module tb_shift_register;

parameter WIDTH = 32;
parameter DEPTH = 4;

reg clk;
reg rst;
reg shift_en;
reg [WIDTH-1:0] data_in;

wire [WIDTH-1:0] data_out;

shift_register #(
    .WIDTH(WIDTH),
    .DEPTH(DEPTH)
) uut (

    .clk(clk),
    .rst(rst),
    .shift_en(shift_en),
    .data_in(data_in),
    .data_out(data_out)

);

// Clock

initial begin
    clk = 0;
    forever #5 clk = ~clk;
end

initial begin

    rst = 1;
    shift_en = 0;
    data_in = 0;

    #10;

    rst = 0;
    shift_en = 1;

    data_in = 32'h11111111;
    #10;

    data_in = 32'h22222222;
    #10;

    data_in = 32'h33333333;
    #10;

    data_in = 32'h44444444;
    #10;

    data_in = 32'h55555555;
    #10;

    #30;

    $finish;

end

endmodule