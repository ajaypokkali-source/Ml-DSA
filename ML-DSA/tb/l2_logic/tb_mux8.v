`timescale 1ns / 1ps

module tb_mux8;

parameter WIDTH = 32;

reg [WIDTH-1:0] in0,in1,in2,in3,in4,in5,in6,in7;
reg [2:0] sel;

wire [WIDTH-1:0] out;

mux8 #(
    .WIDTH(WIDTH)
) uut (
    .in0(in0),
    .in1(in1),
    .in2(in2),
    .in3(in3),
    .in4(in4),
    .in5(in5),
    .in6(in6),
    .in7(in7),
    .sel(sel),
    .out(out)
);

initial begin

    in0 = 0;
    in1 = 1;
    in2 = 2;
    in3 = 3;
    in4 = 4;
    in5 = 5;
    in6 = 6;
    in7 = 7;

    sel = 0; #10;
    sel = 1; #10;
    sel = 2; #10;
    sel = 3; #10;
    sel = 4; #10;
    sel = 5; #10;
    sel = 6; #10;
    sel = 7; #10;

    $finish;

end

endmodule