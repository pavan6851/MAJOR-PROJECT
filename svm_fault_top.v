// =============================================================================
//  svm_fault_top.v  - PMDC Motor Fault Detection - Linear SVM Inference Core
//
//  Input  : 15 normalised features, Q8.24 signed 32-bit
//  Output : 2-bit class  0=Healthy  1=Fault1  2=Fault2  3=Fault3
//  Latency: 5 clock cycles @ 100 MHz = 50 ns per inference
//
//  Compatible: Verilog-2001 and SystemVerilog
// =============================================================================

`timescale 1ns/1ps
`include "svm_params.vh"

module svm_fault_top (
    input  wire        clk,
    input  wire        rst_n,

    input  wire        feat_valid,
    input  wire signed [31:0] feat_data_0,
    input  wire signed [31:0] feat_data_1,
    input  wire signed [31:0] feat_data_2,
    input  wire signed [31:0] feat_data_3,
    input  wire signed [31:0] feat_data_4,
    input  wire signed [31:0] feat_data_5,
    input  wire signed [31:0] feat_data_6,
    input  wire signed [31:0] feat_data_7,
    input  wire signed [31:0] feat_data_8,
    input  wire signed [31:0] feat_data_9,
    input  wire signed [31:0] feat_data_10,
    input  wire signed [31:0] feat_data_11,
    input  wire signed [31:0] feat_data_12,
    input  wire signed [31:0] feat_data_13,
    input  wire signed [31:0] feat_data_14,

    output reg         result_valid,
    output reg  [1:0]  result_class,
    output reg  [11:0] result_votes_dbg  // {v3[2:0], v2[2:0], v1[2:0], v0[2:0]}
);

    // -------------------------------------------------------------------------
    // 6 OvO dot-product units - all receive same 15 features simultaneously
    // -------------------------------------------------------------------------
    wire signed [63:0] dp_score [0:5];
    wire               dp_valid [0:5];

    svm_dot_product #(.CLASSIFIER(0)) u_dp0 (
        .clk(clk), .rst_n(rst_n), .in_valid(feat_valid),
        .x0(feat_data_0),  .x1(feat_data_1),  .x2(feat_data_2),
        .x3(feat_data_3),  .x4(feat_data_4),  .x5(feat_data_5),
        .x6(feat_data_6),  .x7(feat_data_7),  .x8(feat_data_8),
        .x9(feat_data_9),  .x10(feat_data_10),.x11(feat_data_11),
        .x12(feat_data_12),.x13(feat_data_13),.x14(feat_data_14),
        .score(dp_score[0]), .out_valid(dp_valid[0])
    );
    svm_dot_product #(.CLASSIFIER(1)) u_dp1 (
        .clk(clk), .rst_n(rst_n), .in_valid(feat_valid),
        .x0(feat_data_0),  .x1(feat_data_1),  .x2(feat_data_2),
        .x3(feat_data_3),  .x4(feat_data_4),  .x5(feat_data_5),
        .x6(feat_data_6),  .x7(feat_data_7),  .x8(feat_data_8),
        .x9(feat_data_9),  .x10(feat_data_10),.x11(feat_data_11),
        .x12(feat_data_12),.x13(feat_data_13),.x14(feat_data_14),
        .score(dp_score[1]), .out_valid(dp_valid[1])
    );
    svm_dot_product #(.CLASSIFIER(2)) u_dp2 (
        .clk(clk), .rst_n(rst_n), .in_valid(feat_valid),
        .x0(feat_data_0),  .x1(feat_data_1),  .x2(feat_data_2),
        .x3(feat_data_3),  .x4(feat_data_4),  .x5(feat_data_5),
        .x6(feat_data_6),  .x7(feat_data_7),  .x8(feat_data_8),
        .x9(feat_data_9),  .x10(feat_data_10),.x11(feat_data_11),
        .x12(feat_data_12),.x13(feat_data_13),.x14(feat_data_14),
        .score(dp_score[2]), .out_valid(dp_valid[2])
    );
    svm_dot_product #(.CLASSIFIER(3)) u_dp3 (
        .clk(clk), .rst_n(rst_n), .in_valid(feat_valid),
        .x0(feat_data_0),  .x1(feat_data_1),  .x2(feat_data_2),
        .x3(feat_data_3),  .x4(feat_data_4),  .x5(feat_data_5),
        .x6(feat_data_6),  .x7(feat_data_7),  .x8(feat_data_8),
        .x9(feat_data_9),  .x10(feat_data_10),.x11(feat_data_11),
        .x12(feat_data_12),.x13(feat_data_13),.x14(feat_data_14),
        .score(dp_score[3]), .out_valid(dp_valid[3])
    );
    svm_dot_product #(.CLASSIFIER(4)) u_dp4 (
        .clk(clk), .rst_n(rst_n), .in_valid(feat_valid),
        .x0(feat_data_0),  .x1(feat_data_1),  .x2(feat_data_2),
        .x3(feat_data_3),  .x4(feat_data_4),  .x5(feat_data_5),
        .x6(feat_data_6),  .x7(feat_data_7),  .x8(feat_data_8),
        .x9(feat_data_9),  .x10(feat_data_10),.x11(feat_data_11),
        .x12(feat_data_12),.x13(feat_data_13),.x14(feat_data_14),
        .score(dp_score[4]), .out_valid(dp_valid[4])
    );
    svm_dot_product #(.CLASSIFIER(5)) u_dp5 (
        .clk(clk), .rst_n(rst_n), .in_valid(feat_valid),
        .x0(feat_data_0),  .x1(feat_data_1),  .x2(feat_data_2),
        .x3(feat_data_3),  .x4(feat_data_4),  .x5(feat_data_5),
        .x6(feat_data_6),  .x7(feat_data_7),  .x8(feat_data_8),
        .x9(feat_data_9),  .x10(feat_data_10),.x11(feat_data_11),
        .x12(feat_data_12),.x13(feat_data_13),.x14(feat_data_14),
        .score(dp_score[5]), .out_valid(dp_valid[5])
    );

    // -------------------------------------------------------------------------
    // Intercept sign-extension - FIX: use intermediate wires (legal V-2001)
    // Macro expansion inside replication {{32{`B_0[31]}}} is illegal in V-2001
    // -------------------------------------------------------------------------
    wire signed [31:0] b0_w = `B_0;
    wire signed [31:0] b1_w = `B_1;
    wire signed [31:0] b2_w = `B_2;
    wire signed [31:0] b3_w = `B_3;
    wire signed [31:0] b4_w = `B_4;
    wire signed [31:0] b5_w = `B_5;

    wire signed [63:0] score_b0 = dp_score[0] + {{32{b0_w[31]}}, b0_w};
    wire signed [63:0] score_b1 = dp_score[1] + {{32{b1_w[31]}}, b1_w};
    wire signed [63:0] score_b2 = dp_score[2] + {{32{b2_w[31]}}, b2_w};
    wire signed [63:0] score_b3 = dp_score[3] + {{32{b3_w[31]}}, b3_w};
    wire signed [63:0] score_b4 = dp_score[4] + {{32{b4_w[31]}}, b4_w};
    wire signed [63:0] score_b5 = dp_score[5] + {{32{b5_w[31]}}, b5_w};
    wire all_valid;
    assign all_valid = dp_valid[0] & dp_valid[1] & dp_valid[2] &
                   dp_valid[3] & dp_valid[4] & dp_valid[5];

    // -------------------------------------------------------------------------
    // OvO majority vote - registered (pipeline cycle 5)
    //
    // Pairs (sklearn ordering for n_classes=4):
    //   k=0: class 0 vs 1   k=1: class 0 vs 2   k=2: class 0 vs 3
    //   k=3: class 1 vs 2   k=4: class 1 vs 3   k=5: class 2 vs 3
    //
    // If score_bk >= 0 → vote for first class of pair, else second class
    // result_votes_dbg packing: {v3[2:0], v2[2:0], v1[2:0], v0[2:0]}
    // -------------------------------------------------------------------------
    reg [2:0] v0, v1, v2, v3;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            result_valid     <= 1'b0;
            result_class     <= 2'd0;
            result_votes_dbg <= 12'd0;
        end else if (all_valid) begin

            // Blocking assignments for vote accumulation (combinational within clocked block)
            v0 = 3'd0; v1 = 3'd0; v2 = 3'd0; v3 = 3'd0;

            if (score_b0 >= 64'sd0) v0 = v0 + 3'd1; else v1 = v1 + 3'd1; // 0 vs 1
            if (score_b1 >= 64'sd0) v0 = v0 + 3'd1; else v2 = v2 + 3'd1; // 0 vs 2
            if (score_b2 >= 64'sd0) v0 = v0 + 3'd1; else v3 = v3 + 3'd1; // 0 vs 3
            if (score_b3 >= 64'sd0) v1 = v1 + 3'd1; else v2 = v2 + 3'd1; // 1 vs 2
            if (score_b4 >= 64'sd0) v1 = v1 + 3'd1; else v3 = v3 + 3'd1; // 1 vs 3
            if (score_b5 >= 64'sd0) v2 = v2 + 3'd1; else v3 = v3 + 3'd1; // 2 vs 3

            // Argmax with explicit priority for ties (matches sklearn behaviour)
            if      (v0 >= v1 && v0 >= v2 && v0 >= v3) result_class <= 2'd0;
            else if (v1 >= v2 && v1 >= v3)              result_class <= 2'd1;
            else if (v2 >= v3)                          result_class <= 2'd2;
            else                                        result_class <= 2'd3;

            // Debug: pack votes [11:9]=v3, [8:6]=v2, [5:3]=v1, [2:0]=v0
            result_votes_dbg <= {v3, v2, v1, v0};
            result_valid     <= 1'b1;

        end else begin
            result_valid <= 1'b0;
        end
    end

endmodule
