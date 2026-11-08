`timescale 1ns / 1ps

module fifo #(
    parameter DATA_WIDTH = 32,
    parameter DEPTH = 16
)(
    input wire clk,
    input wire rst,
    input wire wr_en,
    input wire rd_en,
    input wire [DATA_WIDTH-1:0] data_in,

    output reg [DATA_WIDTH-1:0] data_out,
    output wire full,
    output wire empty
);

    reg [DATA_WIDTH-1:0] memory [0:DEPTH-1];

    reg [$clog2(DEPTH):0] wr_ptr;
    reg [$clog2(DEPTH):0] rd_ptr;
    reg [$clog2(DEPTH+1)-1:0] count;

    integer i;

    always @(posedge clk) begin

        if (rst) begin

            wr_ptr <= 0;
            rd_ptr <= 0;
            count  <= 0;
            data_out <= 0;

            for(i=0;i<DEPTH;i=i+1)
                memory[i] <= 0;

        end
        else begin

            // Write
            if (wr_en && !full) begin
                memory[wr_ptr] <= data_in;
                wr_ptr <= (wr_ptr + 1) % DEPTH;
                count <= count + 1;
            end

            // Read
            if (rd_en && !empty) begin
                data_out <= memory[rd_ptr];
                rd_ptr <= (rd_ptr + 1) % DEPTH;
                count <= count - 1;
            end

        end

    end

    assign empty = (count == 0);
    assign full  = (count == DEPTH);

endmodule