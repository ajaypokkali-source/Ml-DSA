`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name : tb_poly_sub
// Layer       : 5 - Polynomial Arithmetic
//
// Self-checking testbench for poly_sub.
//
// Golden model : reference_mod_sub(x,y) = (x - y) mod Q, applied per-coefficient
// Coverage     : directed corner cases + random vectors
// Properties   : every output coefficient must lie in [0, Q-1]
//////////////////////////////////////////////////////////////////////////////////

module tb_poly_sub;

    parameter WIDTH = 24;
    parameter Q     = 8380417;
    parameter N     = 256;

    reg  [N*WIDTH-1:0] a;
    reg  [N*WIDTH-1:0] b;
    wire [N*WIDTH-1:0] result;

    integer errors;
    integer tests;
    integer t, i;

    reg [WIDTH-1:0] a_coeff, b_coeff, exp_coeff, got_coeff;

    poly_sub #(
        .Q     (Q),
        .WIDTH (WIDTH),
        .N     (N)
    ) uut (
        .a      (a),
        .b      (b),
        .result (result)
    );

    // ---------------------------------------------------------------
    // Golden reference model for a single coefficient
    // ---------------------------------------------------------------
    function [WIDTH-1:0] reference_mod_sub;
        input [WIDTH-1:0] x;
        input [WIDTH-1:0] y;
        begin
            reference_mod_sub = (x >= y) ? (x - y) : (x + Q - y);
        end
    endfunction

    // ---------------------------------------------------------------
    // Check the whole 256-coefficient result against the golden model
    // ---------------------------------------------------------------
    task check_result;
        input [8*32-1:0] label;
        begin
            #1;
            for (i = 0; i < N; i = i + 1) begin
                a_coeff   = a[i*WIDTH +: WIDTH];
                b_coeff   = b[i*WIDTH +: WIDTH];
                exp_coeff = reference_mod_sub(a_coeff, b_coeff);
                got_coeff = result[i*WIDTH +: WIDTH];

                tests = tests + 1;

                if (got_coeff !== exp_coeff) begin
                    $display("MISMATCH [%0s] coeff=%0d a=%0d b=%0d expected=%0d got=%0d",
                              label, i, a_coeff, b_coeff, exp_coeff, got_coeff);
                    errors = errors + 1;
                end

                // Property check: output must be canonical, in [0, Q-1]
                if (got_coeff >= Q) begin
                    $display("RANGE VIOLATION [%0s] coeff=%0d result=%0d (Q=%0d)",
                              label, i, got_coeff, Q);
                    errors = errors + 1;
                end
            end
        end
    endtask

    task fill_constant;
        input [WIDTH-1:0] a_val;
        input [WIDTH-1:0] b_val;
        begin
            for (i = 0; i < N; i = i + 1) begin
                a[i*WIDTH +: WIDTH] = a_val;
                b[i*WIDTH +: WIDTH] = b_val;
            end
        end
    endtask

    task fill_random;
        begin
            for (i = 0; i < N; i = i + 1) begin
                a[i*WIDTH +: WIDTH] = $urandom_range(0, Q-1);
                b[i*WIDTH +: WIDTH] = $urandom_range(0, Q-1);
            end
        end
    endtask

    initial begin

        errors = 0;
        tests  = 0;

        // -------------------------------------------------------
        // Directed tests (same pattern across all 256 coefficients)
        // -------------------------------------------------------

        fill_constant(0, 0);
        check_result("zero");

        fill_constant(5, 5);
        check_result("equal_values");

        fill_constant(0, 1);
        check_result("underflow_wrap");

        fill_constant(Q-1, Q-1);
        check_result("max_minus_max");

        fill_constant(0, Q-1);
        check_result("zero_minus_max");

        // -------------------------------------------------------
        // Directed test: distinct value per coefficient (i, i+1)
        // forces every coefficient through the underflow path
        // -------------------------------------------------------
        for (i = 0; i < N; i = i + 1) begin
            a[i*WIDTH +: WIDTH] = i;
            b[i*WIDTH +: WIDTH] = i + 1;
        end
        check_result("ramp_underflow");

        // -------------------------------------------------------
        // Random tests
        // -------------------------------------------------------
        for (t = 0; t < 500; t = t + 1) begin
            fill_random;
            check_result("random");
        end

        $display("");
        $display("======================================");
        $display("POLY_SUB TEST COMPLETE");
        $display("======================================");
        $display("Total coefficient checks : %0d", tests);
        $display("Errors                   : %0d", errors);

        if (errors == 0)
            $display("RESULT : ALL TESTS PASSED");
        else
            $display("RESULT : TEST FAILED");

        $display("======================================");

        $finish;

    end

endmodule
