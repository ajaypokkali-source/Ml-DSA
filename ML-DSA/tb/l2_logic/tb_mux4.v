`timescale 1ns / 1ps

module tb_mux4;

parameter WIDTH = 32;

reg [WIDTH-1:0] in0, in1, in2, in3;
reg [1:0] sel;

wire [WIDTH-1:0] out;

mux4 #(
    .WIDTH(WIDTH)
) uut (
    .in0(in0),
    .in1(in1),
    .in2(in2),
    .in3(in3),
    .sel(sel),
    .out(out)
);

initial begin

    in0 = 32'hAAAAAAAA;
    in1 = 32'hBBBBBBBB;
    in2 = 32'hCCCCCCCC;
    in3 = 32'hDDDDDDDD;

    sel = 2'b00; #10;
    sel = 2'b01; #10;
    sel = 2'b10; #10;
    sel = 2'b11; #10;

    $finish;

end

endmodule