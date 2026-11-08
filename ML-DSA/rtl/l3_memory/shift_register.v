`timescale 1ns / 1ps

module shift_register #(
    parameter WIDTH = 32,
    parameter DEPTH = 8
)(
    input wire clk,
    input wire rst,
    input wire shift_en,
    input wire [WIDTH-1:0] data_in,
    output wire [WIDTH-1:0] data_out
);

    reg [WIDTH-1:0] shift_reg [0:DEPTH-1];

    integer i;

    always @(posedge clk) begin

        if (rst) begin

            for(i=0;i<DEPTH;i=i+1)
                shift_reg[i] <= 0;

        end

        else if(shift_en) begin

            shift_reg[0] <= data_in;

            for(i=1;i<DEPTH;i=i+1)
                shift_reg[i] <= shift_reg[i-1];

        end

    end

    assign data_out = shift_reg[DEPTH-1];

endmodule