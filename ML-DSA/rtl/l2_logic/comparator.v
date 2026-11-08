`timescale 1ns / 1ps

module comparator #(
    parameter WIDTH = 32
)(
    input  wire [WIDTH-1:0] a,
    input  wire [WIDTH-1:0] b,

    output wire eq,
    output wire gt,
    output wire lt
);

assign eq = (a == b);
assign gt = (a > b);
assign lt = (a < b);

endmodule