`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 15.09.2026 09:46:17
// Design Name: 
// Module Name: tb_montgomery_mult_top
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
/////////////////////////////////////////////////////////////////////////////////
`timescale 1ns/1ps

`timescale 1ns/1ps

module tb_montgomery_mult_top;

    parameter [63:0] Q       = 64'd8380417;
    parameter [63:0] R_MOD_Q = 64'd4193792;

    reg clk;
    reg rst;
    reg start;

    reg [31:0] a_bar;
    reg [31:0] b_bar;

    wire [63:0] product;
    wire [31:0] result;
    wire done;

    integer errors;
    integer tests;
    integer i;

    reg [63:0] a_mod;
    reg [63:0] b_mod;

    reg [63:0] expected_a_bar;
    reg [63:0] expected_b_bar;

    reg [63:0] expected_product;
    reg [63:0] expected_result;

    reg [63:0] ab_mod;


    montgomery_mult_top dut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .a_bar(a_bar),
        .b_bar(b_bar),
        .product(product),
        .result(result),
        .done(done)
    );


    always #5 clk = ~clk;


    initial begin

        clk = 1'b0;
        rst = 1'b1;
        start = 1'b0;

        a_bar = 32'd0;
        b_bar = 32'd0;

        errors = 0;
        tests = 0;

        #20;

        rst = 1'b0;

        run_test(0, 0);
        run_test(1, 1);
        run_test(1, 5);
        run_test(5, 7);
        run_test(100, 200);
        run_test(1234, 5678);
        run_test(8380416, 1);
        run_test(1, 8380416);
        run_test(8380416, 8380416);

        for (i = 0; i < 9; i = i + 1) begin
            run_test(
                $urandom_range(0, 8380416),
                $urandom_range(0, 8380416)
            );
        end

        $display("");
        $display("============================================");
        $display("TEST COMPLETE");
        $display("TOTAL TESTS = %0d", tests);
        $display("ERRORS      = %0d", errors);
        $display("============================================");

        if (errors == 0)
            $display("ALL TESTS PASSED!");
        else
            $display("TEST FAILED!");

        $finish;

    end


    task run_test;

        input [63:0] test_a;
        input [63:0] test_b;

        begin

            tests = tests + 1;

            a_mod = test_a % Q;
            b_mod = test_b % Q;

            expected_a_bar =
                (a_mod * R_MOD_Q) % Q;

            expected_b_bar =
                (b_mod * R_MOD_Q) % Q;

            a_bar = expected_a_bar[31:0];
            b_bar = expected_b_bar[31:0];

            expected_product =
                expected_a_bar * expected_b_bar;

            ab_mod =
                (a_mod * b_mod) % Q;

            expected_result =
                (ab_mod * R_MOD_Q) % Q;


            /*
             * Start the DUT.
             */

            @(negedge clk);

            start = 1'b1;

            /*
             * DUT executes at this posedge.
             */

            @(posedge clk);

            #1;

            /*
             * Check immediately after the DUT clock.
             */

            if (product !== expected_product) begin

                $display("MULTIPLIER ERROR");
                $display("a        = %0d", test_a);
                $display("b        = %0d", test_b);
                $display("a_bar    = %0d", a_bar);
                $display("b_bar    = %0d", b_bar);
                $display("Expected = %0d", expected_product);
                $display("Got      = %0d", product);

                errors = errors + 1;

            end


            if (result !== expected_result[31:0]) begin

                $display("MONTGOMERY ERROR");
                $display("a        = %0d", test_a);
                $display("b        = %0d", test_b);
                $display("a_bar    = %0d", a_bar);
                $display("b_bar    = %0d", b_bar);
                $display("Product  = %0d", product);
                $display("Expected = %0d", expected_result);
                $display("Got      = %0d", result);

                errors = errors + 1;

            end
            else if ((test_a < 10) && (test_b < 10)) begin

                $display(
                    "PASS | a=%0d b=%0d | a_bar=%0d b_bar=%0d | T=%0d | result=%0d",
                    test_a,
                    test_b,
                    a_bar,
                    b_bar,
                    product,
                    result
                );

            end


            /*
             * Release start.
             */

            start = 1'b0;

            /*
             * Wait one complete cycle before
             * beginning the next test.
             */

            @(negedge clk);

        end

    endtask

endmodule