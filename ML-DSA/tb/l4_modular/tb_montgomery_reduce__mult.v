`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 27.08.2026 22:47:23
// Design Name: 
// Module Name: tb_montgomery_reduce__mult
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

module tb_montgomery;

    parameter [31:0] Q = 32'd8380417;
    parameter [31:0] R = 32'd4193792;

    reg clk;
    reg rst;
    reg start;

    reg  [31:0] a;
    reg  [31:0] b;

    wire [63:0] product;

    wire [31:0] result;
    wire done;

    integer i;
    integer errors;

    reg [63:0] expected;


    multiplier uut_multiplier (
        .a(a),
        .b(b),
        .product(product)
    );


    montgomery_reduce_mult uut_montgomery (
        .clk(clk),
        .rst(rst),
        .start(start),
        .T(product),
        .result(result),
        .done(done)
    );


    always #5 clk = ~clk;


    initial begin

        clk = 0;
        rst = 1;
        start = 0;
        a = 0;
        b = 0;
        errors = 0;

        #20;
        rst = 0;


        // Directed tests

        run_test(0, 0);
        run_test(1, 1);
        run_test(1, 5);
        run_test(5, 7);
        run_test(100, 200);
        run_test(1234, 5678);
        run_test(Q-1, 1);
        run_test(Q-1, Q-1);


        // Random tests

        for (i = 0; i < 10000; i = i + 1) begin
            run_test(
                $urandom_range(0, Q-1),
                $urandom_range(0, Q-1)
            );
        end


        $display("");
        $display("======================================");
        $display("TEST COMPLETE");
        $display("======================================");
        $display("Total tests : %0d", i + 8);
        $display("Errors      : %0d", errors);

        if (errors == 0)
            $display("ALL TESTS PASSED!");
        else
            $display("TEST FAILED!");

        $display("======================================");

        $finish;

    end


    task run_test;

        input [31:0] test_a;
        input [31:0] test_b;

        reg [63:0] product_expected;
        reg [63:0] expected_montgomery;

        begin

            a = test_a;
            b = test_b;

            #1;

            product_expected = test_a * test_b;

            expected_montgomery =
                ((product_expected % Q) * R) % Q;


            @(negedge clk);

            start = 1;

            @(negedge clk);

            start = 0;


            @(posedge clk);

            #1;

            if (product !== product_expected) begin

                $display("MULTIPLIER ERROR");
                $display("a        = %0d", test_a);
                $display("b        = %0d", test_b);
                $display("Expected = %0d", product_expected);
                $display("Got      = %0d", product);

                errors = errors + 1;

            end


            if (result !== expected_montgomery[31:0]) begin

                $display("MONTGOMERY ERROR");
                $display("a        = %0d", test_a);
                $display("b        = %0d", test_b);
                $display("Product  = %0d", product);
                $display("Expected = %0d",
                         expected_montgomery);
                $display("Got      = %0d", result);

                errors = errors + 1;

            end

            else begin

                if ((test_a < 10) && (test_b < 10)) begin

                    $display(
                        "PASS: a=%0d b=%0d product=%0d result=%0d",
                        test_a,
                        test_b,
                        product,
                        result
                    );

                end

            end

        end

    endtask
endmodule
