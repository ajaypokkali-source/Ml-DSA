`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 27.08.2026 22:42:30
// Design Name: 
// Module Name: montgomery_reduce_mult
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
module montgomery_reduce_mult (
    input         clk,
    input         rst,
    input         start,
    input  [63:0] T,
    output reg [31:0] result,
    output reg        done
);

    parameter [31:0] Q       = 32'd8380417;
    parameter [31:0] Q_PRIME = 32'd4236238847;

    reg [95:0] T_times_qprime;
    reg [31:0] m;
    reg [63:0] m_times_q;
    reg [64:0] sum;
    reg [32:0] u;

    always @(posedge clk) begin

        if (rst) begin
            result <= 32'd0;
            done   <= 1'b0;
        end

        else begin

            done <= 1'b0;

            if (start) begin

                T_times_qprime =
                    {32'd0, T} * {64'd0, Q_PRIME};

                m = T_times_qprime[31:0];

                m_times_q = m * Q;

                sum = {1'b0, T} + {1'b0, m_times_q};

                u = sum[64:32];

                if (u >= Q)
                    result <= u - Q;
                else
                    result <= u[31:0];

                done <= 1'b1;

            end

        end

    end

endmodule