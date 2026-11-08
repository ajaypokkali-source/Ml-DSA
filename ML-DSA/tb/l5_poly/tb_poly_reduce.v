`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name : tb_poly_reduce
// Layer       : 5 - Polynomial Arithmetic
//
// Self-checking testbench for poly_reduce.
//
// Golden model : the SAME reference_reduce32 used to verify barrett_reduce
//                itself (Layer 4), plus the single conditional +Q
//                canonicalization step poly_reduce adds on top.
//
// Coverage     : directed corner cases + random vectors across the full
//                unsigned WIDTH-bit input domain (not just [0, Q-1]),
//                since poly_reduce's bus contract is WIDTH bits wide.
//
// Properties   : (1) every output coefficient must lie in [0, Q-1]
//                (2) modular equivalence: (a - result) mod Q == 0
//                    (uses a 64-bit signed temporary to avoid overflow,
//                    matching the property check used for barrett_reduce)
//////////////////////////////////////////////////////////////////////////////////

module tb_poly_reduce;

    parameter WIDTH = 24;
    parameter Q     = 8380417;
    parameter N     = 256;

    reg  [N*WIDTH-1:0] a;
    wire [N*WIDTH-1:0] result;

    integer errors;
    integer tests;
    integer t, i;

    reg [WIDTH-1:0]      a_coeff, got_coeff;
    reg signed [31:0]     reduce32_out, exp_coeff;
    reg signed [63:0]     diff;

    poly_reduce #(
        .Q     (Q),
        .WIDTH (WIDTH),
        .N     (N)
    ) uut (
        .a      (a),
        .result (result)
    );

    // ---------------------------------------------------------------
    // Golden reference model - identical to barrett_reduce's own
    // verified golden model, plus poly_reduce's canonicalization step.
    // ---------------------------------------------------------------
    function signed [31:0] reference_reduce32;
        input signed [31:0] x;
        reg   signed [31:0] tt;
        begin
            tt = (x + 32'sd4194304) >>> 23;
            reference_reduce32 = x - (tt * Q);
        end
    endfunction

    function [WIDTH-1:0] reference_poly_reduce;
        input [WIDTH-1:0] x;
        reg signed [31:0] r_raw;
        begin
            r_raw = reference_reduce32($signed({{(32-WIDTH){1'b0}}, x}));
            reference_poly_reduce = (r_raw < 0) ? (r_raw + Q) : r_raw;
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
                exp_coeff = reference_poly_reduce(a_coeff);
                got_coeff = result[i*WIDTH +: WIDTH];

                tests = tests + 1;

                if (got_coeff !== exp_coeff[WIDTH-1:0]) begin
                    $display("MISMATCH [%0s] coeff=%0d a=%0d expected=%0d got=%0d",
                              label, i, a_coeff, exp_coeff, got_coeff);
                    errors = errors + 1;
                end

                // Property 1: canonical range
                if (got_coeff >= Q) begin
                    $display("RANGE VIOLATION [%0s] coeff=%0d result=%0d (Q=%0d)",
                              label, i, got_coeff, Q);
                    errors = errors + 1;
                end

                // Property 2: modular equivalence, (a - result) mod Q == 0
                // 64-bit signed temporary to avoid overflow, same as the
                // barrett_reduce property check.
                diff = $signed({32'd0, a_coeff}) - $signed({32'd0, got_coeff});
                if ((diff % Q) != 0) begin
                    $display("MODULAR EQUIVALENCE VIOLATION [%0s] coeff=%0d a=%0d result=%0d diff=%0d",
                              label, i, a_coeff, got_coeff, diff);
                    errors = errors + 1;
                end
            end
        end
    endtask

    task fill_constant;
        input [WIDTH-1:0] a_val;
        begin
            for (i = 0; i < N; i = i + 1)
                a[i*WIDTH +: WIDTH] = a_val;
        end
    endtask

    task fill_random_full_width;
        begin
            for (i = 0; i < N; i = i + 1)
                a[i*WIDTH +: WIDTH] = $urandom_range(0, (1 << WIDTH) - 1);
        end
    endtask

    task fill_random_canonical;
        begin
            for (i = 0; i < N; i = i + 1)
                a[i*WIDTH +: WIDTH] = $urandom_range(0, Q-1);
        end
    endtask

    initial begin

        errors = 0;
        tests  = 0;

        // -------------------------------------------------------
        // Directed tests - boundary values around Q, 2Q, and the
        // full WIDTH-bit range
        // -------------------------------------------------------

        fill_constant(0);
        check_result("zero");

        fill_constant(1);
        check_result("one");

        fill_constant(Q-1);
        check_result("q_minus_1");

        fill_constant(Q);
        check_result("q_exact");

        fill_constant(Q+1);
        check_result("q_plus_1");

        fill_constant(2*Q);
        check_result("two_q");

        fill_constant(2*Q - 1);
        check_result("two_q_minus_1");

        fill_constant((1 << WIDTH) - 1);
        check_result("max_width_value");

        fill_constant((1 << WIDTH) - 1 - Q);
        check_result("max_width_minus_q");

        // Distinct ramp across all 256 coefficients, spanning > Q
        for (i = 0; i < N; i = i + 1)
            a[i*WIDTH +: WIDTH] = (i * 65536) % (1 << WIDTH);
        check_result("ramp_distinct");

        // -------------------------------------------------------
        // Random tests - full unsigned WIDTH-bit domain
        // -------------------------------------------------------
        for (t = 0; t < 400; t = t + 1) begin
            fill_random_full_width;
            check_result("random_full_width");
        end

        // -------------------------------------------------------
        // Random tests - already-canonical domain (realistic case:
        // poly_reduce applied to poly_add/poly_sub/poly_shift output)
        // -------------------------------------------------------
        for (t = 0; t < 200; t = t + 1) begin
            fill_random_canonical;
            check_result("random_canonical");
        end

        $display("");
        $display("======================================");
        $display("POLY_REDUCE TEST COMPLETE");
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
