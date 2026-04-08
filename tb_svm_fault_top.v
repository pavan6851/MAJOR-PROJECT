// =============================================================================
//  tb_svm_fault_top.v  - Self-checking testbench
//  PMDC Motor Fault Detection - SVM Inference Core
//
//  Reads tb_vectors.txt:  15 Q8.24 integers + expected_class per line
//  Expected result: 87.08% accuracy (209/240 correct)
//
//  Results printed to TCL console via $display.
//  Compatible: Verilog-2001 and SystemVerilog
// =============================================================================
`timescale 1ns/1ps

module tb_svm_fault_top;

    // -------------------------------------------------------------------------
    // Parameters
    // -------------------------------------------------------------------------
    parameter CLK_PERIOD  = 10;   // 10 ns = 100 MHz
    parameter PIPE_CYCLES = 6;    

    // -------------------------------------------------------------------------
    // DUT signals
    // -------------------------------------------------------------------------
    reg        clk, rst_n;
    reg        feat_valid;

    reg signed [31:0] feat_data_0,  feat_data_1,  feat_data_2,  feat_data_3;
    reg signed [31:0] feat_data_4,  feat_data_5,  feat_data_6,  feat_data_7;
    reg signed [31:0] feat_data_8,  feat_data_9,  feat_data_10, feat_data_11;
    reg signed [31:0] feat_data_12, feat_data_13, feat_data_14;

    wire        result_valid;
    wire [1:0]  result_class;
    wire [11:0] result_votes_dbg;  // {v3[2:0], v2[2:0], v1[2:0], v0[2:0]}

    // -------------------------------------------------------------------------
    // DUT instantiation
    // -------------------------------------------------------------------------
    svm_fault_top dut (
        .clk              (clk),
        .rst_n            (rst_n),
        .feat_valid       (feat_valid),
        .feat_data_0      (feat_data_0),
        .feat_data_1      (feat_data_1),
        .feat_data_2      (feat_data_2),
        .feat_data_3      (feat_data_3),
        .feat_data_4      (feat_data_4),
        .feat_data_5      (feat_data_5),
        .feat_data_6      (feat_data_6),
        .feat_data_7      (feat_data_7),
        .feat_data_8      (feat_data_8),
        .feat_data_9      (feat_data_9),
        .feat_data_10     (feat_data_10),
        .feat_data_11     (feat_data_11),
        .feat_data_12     (feat_data_12),
        .feat_data_13     (feat_data_13),
        .feat_data_14     (feat_data_14),
        .result_valid     (result_valid),
        .result_class     (result_class),
        .result_votes_dbg (result_votes_dbg)
    );

    // -------------------------------------------------------------------------
    // Clock generation
    // -------------------------------------------------------------------------
    initial clk = 0;
    always #(CLK_PERIOD / 2) clk = ~clk;

    // -------------------------------------------------------------------------
    // Helper task: drive one feature vector onto DUT inputs
    // -------------------------------------------------------------------------
    task drive_features;
        input signed [31:0] f0,f1,f2,f3,f4,f5,f6,f7,f8,f9,f10,f11,f12,f13,f14;
        begin
            feat_data_0  = f0;  feat_data_1  = f1;  feat_data_2  = f2;
            feat_data_3  = f3;  feat_data_4  = f4;  feat_data_5  = f5;
            feat_data_6  = f6;  feat_data_7  = f7;  feat_data_8  = f8;
            feat_data_9  = f9;  feat_data_10 = f10; feat_data_11 = f11;
            feat_data_12 = f12; feat_data_13 = f13; feat_data_14 = f14;
        end
    endtask

    // -------------------------------------------------------------------------
    // Test stimulus and checker
    // -------------------------------------------------------------------------
    integer fv [0:14];
    integer expected_class;
    integer n_pass, n_fail, n_total;
    integer fd, r;
    integer n_healthy_pass, n_fault1_pass, n_fault2_pass, n_fault3_pass;
    integer n_healthy_total,n_fault1_total,n_fault2_total,n_fault3_total;

    initial begin
        $dumpfile("tb_svm_fault_top.vcd");
        $dumpvars(0, tb_svm_fault_top);

        // Initialise counters and signals
        rst_n      = 0;
        feat_valid = 0;
        n_pass = 0; n_fail = 0; n_total = 0;
        n_healthy_pass=0; n_fault1_pass=0; n_fault2_pass=0; n_fault3_pass=0;
        n_healthy_total=0;n_fault1_total=0;n_fault2_total=0;n_fault3_total=0;
        drive_features(0,0,0,0,0,0,0,0,0,0,0,0,0,0,0);

        // Reset sequence
        repeat (4) @(posedge clk);
        rst_n = 1;
        @(posedge clk);

        // ── Open test vector file ─────────────────────────────────────────
        fd = $fopen("tb_vectors.txt", "r");
        if (fd == 0) begin
            $display("ERROR: tb_vectors.txt not found in xsim working directory.");
            $display("Path: F:/XILINX/ML Inference/SVM/SVM.sim/sim_1/behav/xsim/");
            $display("Copy tb_vectors.txt into that folder and re-run.");
            $finish;
        end

        $display("");
        $display("========================================");
        $display("  SVM FPGA INFERENCE - SAMPLE LOG");
        $display("  Format: [n] got=X exp=Y  v0 v1 v2 v3");
        $display("========================================");

        // ── Process all test vectors ──────────────────────────────────────
        while (!$feof(fd)) begin
            r = $fscanf(fd, "%d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d\n",
                fv[0],  fv[1],  fv[2],  fv[3],  fv[4],
                fv[5],  fv[6],  fv[7],  fv[8],  fv[9],
                fv[10], fv[11], fv[12], fv[13], fv[14],
                expected_class);
                
            if (r != 16) begin
                if (!$feof(fd))
                    $display("WARNING: Malformed line (%0d fields), skipping", r);
            end else begin
        
                // Drive inputs for one clock cycle
                drive_features(fv[0],fv[1],fv[2],fv[3],fv[4],fv[5],fv[6],
                               fv[7],fv[8],fv[9],fv[10],fv[11],fv[12],fv[13],fv[14]);
        
                feat_valid = 1'b1;
                @(posedge clk);
                feat_valid = 1'b0;
        
                // Wait for pipeline output
                repeat (PIPE_CYCLES) @(posedge clk);
        
                // Per-class total tracking
                n_total = n_total + 1;
                case (expected_class)
                    0: n_healthy_total = n_healthy_total + 1;
                    1: n_fault1_total  = n_fault1_total  + 1;
                    2: n_fault2_total  = n_fault2_total  + 1;
                    3: n_fault3_total  = n_fault3_total  + 1;
                endcase
        
                // Check result
                if (!result_valid) begin
                    $display("[%0d] ERROR: result_valid not asserted - pipeline timing issue", n_total);
                    n_fail = n_fail + 1;
                end else if (result_class == expected_class[1:0]) begin
                    n_pass = n_pass + 1;
                    case (expected_class)
                        0: n_healthy_pass = n_healthy_pass + 1;
                        1: n_fault1_pass  = n_fault1_pass  + 1;
                        2: n_fault2_pass  = n_fault2_pass  + 1;
                        3: n_fault3_pass  = n_fault3_pass  + 1;
                    endcase
                end else begin
                    n_fail = n_fail + 1;
                    $display("[%0d] FAIL: got=%0d exp=%0d  votes: Healthy=%0d F1=%0d F2=%0d F3=%0d",
                        n_total,
                        result_class,
                        expected_class,
                        result_votes_dbg[2:0],
                        result_votes_dbg[5:3],
                        result_votes_dbg[8:6],
                        result_votes_dbg[11:9]);
                end
        
            end
        end  
        $fclose(fd);

        // ── Final accuracy report (visible in TCL console) ────────────────
        $display("");
        $display("========================================");
        $display("  BEHAVIORAL SIMULATION COMPLETE");
        $display("  PMDC Motor Fault Detection - SVM Q8.24");
        $display("========================================");
        $display("  Total samples tested : %0d", n_total);
        $display("  Correct predictions  : %0d", n_pass);
        $display("  Wrong  predictions   : %0d", n_fail);
        $display("  Overall accuracy     : %0.2f%%",
                  100.0 * n_pass / n_total);
        $display("----------------------------------------");
        $display("  Per-class accuracy:");
        $display("    Healthy  : %0d / %0d", n_healthy_pass, n_healthy_total);
        $display("    Fault 1  : %0d / %0d", n_fault1_pass,  n_fault1_total);
        $display("    Fault 2  : %0d / %0d", n_fault2_pass,  n_fault2_total);
        $display("    Fault 3  : %0d / %0d", n_fault3_pass,  n_fault3_total);
        $display("----------------------------------------");
        $display("  Python reference accuracy : 87.08%%");
        if (n_total > 0 && (n_pass * 10000 / n_total >= 8600))
            $display("  Status : PASS - FPGA matches Python model");
        else
            $display("  Status : CHECK - accuracy below 86%% threshold");
        $display("========================================");
        $finish;
    end

    // -------------------------------------------------------------------------
    // Timeout watchdog
    // -------------------------------------------------------------------------
    initial begin
        #(CLK_PERIOD * 1_000_000);
        $display("TIMEOUT: simulation exceeded 1M cycles");
        $finish;
    end

endmodule
