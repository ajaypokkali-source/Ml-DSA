`timescale 1ns / 1ps

module tb_ram_sp;

parameter DATA_WIDTH = 32;
parameter ADDR_WIDTH = 8;

reg clk;
reg we;
reg [ADDR_WIDTH-1:0] addr;
reg [DATA_WIDTH-1:0] data_in;

wire [DATA_WIDTH-1:0] data_out;

ram_sp #(
    .DATA_WIDTH(DATA_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH)
) uut (
    .clk(clk),
    .we(we),
    .addr(addr),
    .data_in(data_in),
    .data_out(data_out)
);

// Clock Generation
initial begin
    clk = 0;
    forever #5 clk = ~clk;
end

initial begin

    we = 1;
    addr = 8'd10;
    data_in = 32'hDEADBEEF;
    #10;
    
    we = 0;
    addr = 8'd10;
    #20;    // Stay here longer so you can clearly see DEADBEEF
    
    addr = 8'd20;
    #20;
    
   $finish;
    
end

endmodule