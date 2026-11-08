module barrett_reduce (
    input  signed [31:0] a,
    output signed [31:0] r
);

localparam signed [31:0] Q     = 32'sd8380417;
localparam signed [31:0] ROUND = 32'sd4194304;

wire signed [31:0] temp_add;
wire signed [31:0] temp_shift;
wire signed [63:0] temp_mult;
assign temp_add = a + ROUND;
assign temp_shift = temp_add >>> 23;
assign temp_mult = temp_shift * Q;
assign r = a - $signed(temp_mult[31:0]);
endmodule
