`timescale 1ns / 1ps

module ram_sp #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 8
)(
    input wire clk,
    input wire we,
    input wire [ADDR_WIDTH-1:0] addr,
    input wire [DATA_WIDTH-1:0] data_in,
    output reg [DATA_WIDTH-1:0] data_out
);

    // Memory Array
    reg [DATA_WIDTH-1:0] memory [0:(1<<ADDR_WIDTH)-1];

    always @(posedge clk) begin
        if (we)
            memory[addr] <= data_in;

        data_out <= memory[addr];
    end

endmodule