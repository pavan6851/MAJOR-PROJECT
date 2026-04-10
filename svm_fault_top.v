`timescale 1ns/1ps
`include "svm_params.vh"

module svm_fault_top (
    input  wire clk,
    input  wire rst_n,

    input  wire feat_valid,

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

    output reg result_valid,
    output reg [1:0] result_class,
    output reg [11:0] result_votes_dbg
);

    // -----------------------------
    // classifier outputs
    // -----------------------------
    wire signed [63:0] score[0:5];
    wire dp_valid[0:5];

    genvar i;

    generate
        for (i = 0; i < 6; i = i + 1) begin : DP
            svm_dot_product #(.CLASSIFIER(i)) u_dp (
                .clk(clk),
                .rst_n(rst_n),
                .in_valid(feat_valid),

                .x0(feat_data_0), .x1(feat_data_1), .x2(feat_data_2),
                .x3(feat_data_3), .x4(feat_data_4), .x5(feat_data_5),
                .x6(feat_data_6), .x7(feat_data_7), .x8(feat_data_8),
                .x9(feat_data_9), .x10(feat_data_10), .x11(feat_data_11),
                .x12(feat_data_12), .x13(feat_data_13), .x14(feat_data_14),

                .score(score[i]),
                .out_valid(dp_valid[i])
            );
        end
    endgenerate

    // -----------------------------
    // USE ANY ONE VALID (ALL SAME LATENCY)
    // -----------------------------
    wire valid_fire = dp_valid[0]; // all classifiers aligned

    // -----------------------------
    // VOTING
    // -----------------------------
    integer j;
    reg [2:0] vote[0:3];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            result_valid <= 0;
            result_class <= 0;
            result_votes_dbg <= 0;
        end else begin
            result_valid <= 0;

            if (valid_fire) begin

                vote[0] = 0;
                vote[1] = 0;
                vote[2] = 0;
                vote[3] = 0;

                if (score[0] >= 0) vote[0] = vote[0] + 1; else vote[1] = vote[1] + 1;
                if (score[1] >= 0) vote[0] = vote[0] + 1; else vote[2] = vote[2] + 1;
                if (score[2] >= 0) vote[0] = vote[0] + 1; else vote[3] = vote[3] + 1;
                if (score[3] >= 0) vote[1] = vote[1] + 1; else vote[2] = vote[2] + 1;
                if (score[4] >= 0) vote[1] = vote[1] + 1; else vote[3] = vote[3] + 1;
                if (score[5] >= 0) vote[2] = vote[2] + 1; else vote[3] = vote[3] + 1;

                if (vote[0] >= vote[1] && vote[0] >= vote[2] && vote[0] >= vote[3])
                    result_class <= 0;
                else if (vote[1] >= vote[2] && vote[1] >= vote[3])
                    result_class <= 1;
                else if (vote[2] >= vote[3])
                    result_class <= 2;
                else
                    result_class <= 3;

                result_votes_dbg <= {vote[3], vote[2], vote[1], vote[0]};
                result_valid <= 1'b1;
            end
        end
    end

endmodule
