`timescale 1ns / 1ps

module tb_rom;

parameter DATA_WIDTH = 32;
parameter ADDR_WIDTH = 8;

reg clk;
reg [ADDR_WIDTH-1:0] addr;
wire [DATA_WIDTH-1:0] data_out;

rom #(
    .DATA_WIDTH(DATA_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH)
) uut (
    .clk(clk),
    .addr(addr),
    .data_out(data_out)
);

// Clock Generation
initial begin
    clk = 0;
    forever #5 clk = ~clk;
end

initial begin

    addr = 0;
    #10;

    addr = 1;
    #10;

    addr = 2;
    #10;

    addr = 3;
    #10;

    addr = 4;
    #10;

    $finish;

end

endmodule