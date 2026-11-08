`timescale 1ns / 1ps

module tb_fifo;

parameter DATA_WIDTH = 32;
parameter DEPTH = 4;

reg clk;
reg rst;
reg wr_en;
reg rd_en;
reg [DATA_WIDTH-1:0] data_in;

wire [DATA_WIDTH-1:0] data_out;
wire full;
wire empty;

fifo #(
    .DATA_WIDTH(DATA_WIDTH),
    .DEPTH(DEPTH)
) uut (
    .clk(clk),
    .rst(rst),
    .wr_en(wr_en),
    .rd_en(rd_en),
    .data_in(data_in),
    .data_out(data_out),
    .full(full),
    .empty(empty)
);

initial begin
    clk = 0;
    forever #5 clk = ~clk;
end

initial begin

    rst = 1;
    wr_en = 0;
    rd_en = 0;
    data_in = 0;

    #10;

    rst = 0;

    // Write 4 values
    wr_en = 1;

    data_in = 32'h11111111; #10;
    data_in = 32'h22222222; #10;
    data_in = 32'h33333333; #10;
    data_in = 32'h44444444; #10;

    wr_en = 0;

    // Read 4 values
    rd_en = 1;

    #10;
    #10;
    #10;
    #10;

    rd_en = 0;

    #20;

    $finish;

end

endmodule