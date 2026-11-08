`timescale 1ns / 1ps

module tb_barrett_reduce;

    //====================================================
    // Inputs / Outputs
    //====================================================

    reg signed [31:0] a;
    wire signed [31:0] r;

    // ML-DSA Modulus
    localparam signed [31:0] Q = 32'sd8380417;

    // Verification Counters
    integer total_tests;
    integer passed_tests;
    integer failed_tests;

    //====================================================
    // Instantiate the Unit Under Test (UUT)
    //====================================================

    barrett_reduce uut (
        .a(a),
        .r(r)
    );

    //====================================================
    // Golden Reference Model
    //====================================================

    function signed [31:0] reference_reduce32;
        input signed [31:0] x;

        reg signed [31:0] t;

        begin
            t = (x + 32'sd4194304) >>> 23;
            reference_reduce32 = x - (t * Q);
        end
    endfunction

    //====================================================
    // Self-checking Task
    //====================================================

    task check_result;

        reg signed [31:0] expected;
        reg signed [63:0] diff;

        begin

            expected = reference_reduce32(a);

            total_tests = total_tests + 1;

            if (r === expected) begin

                passed_tests = passed_tests + 1;

                $display("PASS | Test %0d | Input = %0d | Output = %0d",
                         total_tests, a, r);

            end
            else begin

                failed_tests = failed_tests + 1;

                $display("FAIL | Test %0d", total_tests);
                $display("Input    : %0d", a);
                $display("Expected : %0d", expected);
                $display("Received : %0d", r);

            end
//----------------------------------------------------
// Property Check 1 : Output Range
//----------------------------------------------------

if ((r < -32'sd6283008) || (r > 32'sd6283008))
begin
    failed_tests = failed_tests + 1;

    $display("PROPERTY FAIL : Output Range (Test %0d)", total_tests);
    $display("Input  = %0d", a);
    $display("Output = %0d", r);
end

//----------------------------------------------------
// Property Check 2 : Modulo Property
//----------------------------------------------------

diff = $signed(a) - $signed(r);

if ((diff % Q) != 0)
begin
    failed_tests = failed_tests + 1;

    $display("PROPERTY FAIL : Modulo Property (Test %0d)", total_tests);
    $display("Input      = %0d", a);
    $display("Output     = %0d", r);
    $display("Difference = %0d", diff);
end

        end

    endtask
    task run_random_tests;

    integer i;

    begin

        $display("");
        $display("======================================");
        $display(" Random Verification");
        $display("======================================");

        for(i = 0; i < 500; i = i + 1)
        begin
            a = $random;
            #10;
            check_result();
        end

    end

endtask

    //====================================================
    // Test Sequence
    //====================================================

    initial begin

        total_tests  = 0;
        passed_tests = 0;
        failed_tests = 0;

        //====================================================
        // Directed Tests - Small Values
        //====================================================

        a = 0;      #10; check_result();
        a = 1;      #10; check_result();
        a = 2;      #10; check_result();
        a = 3;      #10; check_result();
        a = 4;      #10; check_result();
        a = 5;      #10; check_result();
        a = 10;     #10; check_result();
        a = 100;    #10; check_result();
        a = 1000;   #10; check_result();

        //====================================================
        // Directed Tests - Around Q
        //====================================================

        a = Q-2;    #10; check_result();
        a = Q-1;    #10; check_result();
        a = Q;      #10; check_result();
        a = Q+1;    #10; check_result();
        a = Q+2;    #10; check_result();

        //====================================================
        // Directed Tests - Around 2Q
        //====================================================

        a = (2*Q)-2;   #10; check_result();
        a = (2*Q)-1;   #10; check_result();
        a = (2*Q);     #10; check_result();
        a = (2*Q)+1;   #10; check_result();
        a = (2*Q)+2;   #10; check_result();

        //====================================================
        // Directed Tests - Negative Values
        //====================================================

        a = -1;        #10; check_result();
        a = -2;        #10; check_result();
        a = -10;       #10; check_result();
        a = -Q;        #10; check_result();
        a = -(Q+1);    #10; check_result();

        //====================================================
        // Directed Tests - Extreme Values
        //====================================================

        a = 2143289343;   #10; check_result();
        a = 2143289342;   #10; check_result();
        a = 2143289341;   #10; check_result();

        a = -2143289343;  #10; check_result();
        a = -2143289342;  #10; check_result();
        a = -2143289341;  #10; check_result();
        run_random_tests();

        //====================================================
        // Verification Summary
        //====================================================

        $display("");
        $display("======================================");
        $display(" Barrett Reduction Verification");
        $display("======================================");
        $display("Total Tests : %0d", total_tests);
        $display("Passed      : %0d", passed_tests);
        $display("Failed      : %0d", failed_tests);
        $display("======================================");

        if ((failed_tests == 0) && (passed_tests == total_tests))
            $display("RESULT : ALL TESTS PASSED");
        else
            $display("RESULT : TESTS FAILED");

        $finish;

    end

endmodule