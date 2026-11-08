`timescale 1ns / 1ps

module rom #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 8
)(
    input wire clk,
    input wire [ADDR_WIDTH-1:0] addr,
    output reg [DATA_WIDTH-1:0] data_out
);

    // ROM Memory
    reg [DATA_WIDTH-1:0] memory [0:(1<<ADDR_WIDTH)-1];

    // Initialize ROM
    initial begin
        $readmemh("rom_init.mem", memory);
    end


    // Synchronous Read
    always @(posedge clk) begin
        data_out <= memory[addr];
    end

endmodule