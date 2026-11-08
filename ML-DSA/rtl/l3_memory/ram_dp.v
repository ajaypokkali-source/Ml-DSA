`timescale 1ns / 1ps

module ram_dp #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 8
)(
    input wire clk,

    // -------- Port A --------
    input wire we_a,
    input wire [ADDR_WIDTH-1:0] addr_a,
    input wire [DATA_WIDTH-1:0] data_in_a,
    output reg [DATA_WIDTH-1:0] data_out_a,

    // -------- Port B --------
    input wire we_b,
    input wire [ADDR_WIDTH-1:0] addr_b,
    input wire [DATA_WIDTH-1:0] data_in_b,
    output reg [DATA_WIDTH-1:0] data_out_b
);

    // Memory Array
    reg [DATA_WIDTH-1:0] memory [0:(1<<ADDR_WIDTH)-1];

    always @(posedge clk) begin

        // -------- Port A --------
        if (we_a)
            memory[addr_a] <= data_in_a;

        data_out_a <= memory[addr_a];

        // -------- Port B --------
        if (we_b)
            memory[addr_b] <= data_in_b;

        data_out_b <= memory[addr_b];

    end

endmodule