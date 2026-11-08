`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name : tb_poly_shift
// Layer       : 5 - Polynomial Arithmetic
//
// Self-checking testbench for poly_shift.
//
// Golden model : reference_shift(x) = (x << D) truncated to WIDTH bits
//                (matches the RTL's raw hardware shift exactly)
//
// Coverage     : directed corner cases + random vectors
// Property     : for the REAL spec usage range (t1-like inputs, i.e.
//                x <= (Q-1) >> D), the shift must be exact (no truncation)
//                and the result must land in [0, Q-1]. This is checked
//                separately from the raw bit-truncation check below, since
//                poly_shift makes no range promises for out-of-range inputs.
//////////////////////////////////////////////////////////////////////////////////

module tb_poly_shift;

    parameter WIDTH = 24;
    parameter Q     = 8380417;
    parameter N     = 256;
    parameter D     = 13;

    // Max legal t1-like coefficient per Power2Round: (Q-1) >> D
    localparam T1_MAX = (Q-1) >> D;

    reg  [N*WIDTH-1:0] a;
    wire [N*WIDTH-1:0] result;

    integer errors;
    integer tests;
    integer t, i;

    reg [WIDTH-1:0] a_coeff, exp_coeff, got_coeff;

    poly_shift #(
        .Q     (Q),
        .WIDTH (WIDTH),
        .N     (N),
        .D     (D)
    ) uut (
        .a      (a),
        .result (result)
    );

    // ---------------------------------------------------------------
    // Golden reference model for a single coefficient - raw shift,
    // truncated to WIDTH bits, exactly matching the hardware behavior.
    // ---------------------------------------------------------------
    function [WIDTH-1:0] reference_shift;
        input [WIDTH-1:0] x;
        begin
            reference_shift = x << D;   // implicit truncation to WIDTH bits
        end
    endfunction

    // ---------------------------------------------------------------
    // Check the whole 256-coefficient result against the golden model,
    // plus (optionally) the t1-range property check.
    // ---------------------------------------------------------------
    task check_result;
        input [8*32-1:0] label;
        input            check_t1_property;
        begin
            #1;
            for (i = 0; i < N; i = i + 1) begin
                a_coeff   = a[i*WIDTH +: WIDTH];
                exp_coeff = reference_shift(a_coeff);
                got_coeff = result[i*WIDTH +: WIDTH];

                tests = tests + 1;

                if (got_coeff !== exp_coeff) begin
                    $display("MISMATCH [%0s] coeff=%0d a=%0d expected=%0d got=%0d",
                              label, i, a_coeff, exp_coeff, got_coeff);
                    errors = errors + 1;
                end

                if (check_t1_property) begin
                    // Property: for legal t1 inputs, shift must be exact
                    // (no truncation) and result must be canonical (< Q).
                    if (a_coeff <= T1_MAX) begin
                        if (got_coeff != (a_coeff * (1 << D))) begin
                            $display("T1-PROPERTY VIOLATION (exactness) [%0s] coeff=%0d a=%0d got=%0d",
                                      label, i, a_coeff, got_coeff);
                            errors = errors + 1;
                        end
                        if (got_coeff >= Q) begin
                            $display("T1-PROPERTY VIOLATION (range) [%0s] coeff=%0d a=%0d got=%0d (Q=%0d)",
                                      label, i, a_coeff, got_coeff, Q);
                            errors = errors + 1;
                        end
                    end
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

    task fill_random_t1_range;
        begin
            for (i = 0; i < N; i = i + 1)
                a[i*WIDTH +: WIDTH] = $urandom_range(0, T1_MAX);
        end
    endtask

    task fill_random_full_width;
        begin
            for (i = 0; i < N; i = i + 1)
                a[i*WIDTH +: WIDTH] = $urandom_range(0, (1 << WIDTH) - 1);
        end
    endtask

    initial begin

        errors = 0;
        tests  = 0;

        $display("T1_MAX = (Q-1) >> D = %0d", T1_MAX);

        // -------------------------------------------------------
        // Directed tests - t1-range corner cases (real spec usage)
        // -------------------------------------------------------

        fill_constant(0);
        check_result("zero", 1);

        fill_constant(1);
        check_result("one", 1);

        fill_constant(T1_MAX);
        check_result("t1_max", 1);

        fill_constant(T1_MAX - 1);
        check_result("t1_max_minus_1", 1);

        // Distinct ramp across all 256 coefficients, within t1 range
        for (i = 0; i < N; i = i + 1)
            a[i*WIDTH +: WIDTH] = i % (T1_MAX + 1);
        check_result("ramp_t1_range", 1);

        // -------------------------------------------------------
        // Directed tests - raw truncation behavior outside t1 range
        // (no t1-property check here; module makes no range promise)
        // -------------------------------------------------------

        fill_constant((1 << WIDTH) - 1);  // all-ones, forces truncation
        check_result("all_ones_overflow", 0);

        fill_constant(Q - 1);
        check_result("q_minus_1_overflow", 0);

        // -------------------------------------------------------
        // Random tests - realistic t1-range inputs (property-checked)
        // -------------------------------------------------------
        for (t = 0; t < 300; t = t + 1) begin
            fill_random_t1_range;
            check_result("random_t1_range", 1);
        end

        // -------------------------------------------------------
        // Random tests - full-width inputs (bit-truncation sanity only)
        // -------------------------------------------------------
        for (t = 0; t < 200; t = t + 1) begin
            fill_random_full_width;
            check_result("random_full_width", 0);
        end

        $display("");
        $display("======================================");
        $display("POLY_SHIFT TEST COMPLETE");
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
