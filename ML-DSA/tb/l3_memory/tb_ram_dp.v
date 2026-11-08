`timescale 1ns / 1ps

module tb_ram_dp;

parameter DATA_WIDTH = 32;
parameter ADDR_WIDTH = 8;

reg clk;

// Port A
reg we_a;
reg [ADDR_WIDTH-1:0] addr_a;
reg [DATA_WIDTH-1:0] data_in_a;
wire [DATA_WIDTH-1:0] data_out_a;

// Port B
reg we_b;
reg [ADDR_WIDTH-1:0] addr_b;
reg [DATA_WIDTH-1:0] data_in_b;
wire [DATA_WIDTH-1:0] data_out_b;

ram_dp #(
    .DATA_WIDTH(DATA_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH)
) uut (
    .clk(clk),

    .we_a(we_a),
    .addr_a(addr_a),
    .data_in_a(data_in_a),
    .data_out_a(data_out_a),

    .we_b(we_b),
    .addr_b(addr_b),
    .data_in_b(data_in_b),
    .data_out_b(data_out_b)
);

// Clock
initial begin
    clk = 0;
    forever #5 clk = ~clk;
end

initial begin

    // Initialize
    we_a = 0;
    we_b = 0;
    addr_a = 0;
    addr_b = 0;
    data_in_a = 0;
    data_in_b = 0;

    //------------------------------------------------
    // Write AAAAAAAA to Address 10 using Port A
    //------------------------------------------------
    we_a = 1;
    addr_a = 8'd10;
    data_in_a = 32'hAAAAAAAA;
    #10;

    //------------------------------------------------
    // Write BBBBBBBB to Address 20 using Port B
    //------------------------------------------------
    we_a = 0;
    we_b = 1;
    addr_b = 8'd20;
    data_in_b = 32'hBBBBBBBB;
    #10;

    //------------------------------------------------
    // Read both locations simultaneously
    //------------------------------------------------
    we_b = 0;

    addr_a = 8'd10;
    addr_b = 8'd20;

    #20;

    $finish;

end

endmodule