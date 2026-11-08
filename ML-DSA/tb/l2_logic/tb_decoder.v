`timescale 1ns / 1ps

module tb_decoder;

reg [2:0] in;
wire [7:0] out;

decoder uut(
    .in(in),
    .out(out)
);

initial begin

    in = 0; #10;
    in = 1; #10;
    in = 2; #10;
    in = 3; #10;
    in = 4; #10;
    in = 5; #10;
    in = 6; #10;
    in = 7; #10;

    $finish;

end

endmodule