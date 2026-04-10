// =============================================================================
//  svm_dot_product.v  (v6 - FIXED: bias added, casez→case)
//  One OvO binary classifier dot-product unit.
//
//  Computes:  score = sum_{j=0}^{14}  W[CLASSIFIER][j] * x[j]  +  B[CLASSIFIER]
//             (Q8.24 fixed-point, 32-bit signed inputs, 64-bit accumulator)
//
//  Fixed-point: Q8.24
//    w * x : Q8.24 x Q8.24 → Q16.48 in int64, then >>> 24 → Q8.24
//    bias  : already in Q8.24, sign-extended to 64-bit before addition
//
//  Pipeline latency: 5 registered clock cycles
//    Stage 1 (l0): 8 pairwise sums
//    Stage 2 (l1): 4 sums of l0 pairs
//    Stage 3 (l2): 2 sums of l1 pairs
//    Stage 4 (out): final sum l2[0]+l2[1] + bias → score, out_valid
// =============================================================================

`timescale 1ns/1ps
`include "svm_params.vh"

module svm_dot_product #(
    parameter integer CLASSIFIER = 0
)(
    input  wire        clk,
    input  wire        rst_n,
    input  wire        in_valid,

    // 15 flat feature ports (Verilog-2001 compatible - no array ports)
    input  wire signed [31:0] x0,
    input  wire signed [31:0] x1,
    input  wire signed [31:0] x2,
    input  wire signed [31:0] x3,
    input  wire signed [31:0] x4,
    input  wire signed [31:0] x5,
    input  wire signed [31:0] x6,
    input  wire signed [31:0] x7,
    input  wire signed [31:0] x8,
    input  wire signed [31:0] x9,
    input  wire signed [31:0] x10,
    input  wire signed [31:0] x11,
    input  wire signed [31:0] x12,
    input  wire signed [31:0] x13,
    input  wire signed [31:0] x14,

    output reg  signed [63:0] score,
    output reg                out_valid
);

    // -----------------------------------------------------------------------
    // Weight lookup - uses `define macros from svm_params.vh
    // FIXED: use 'case' not 'casez' to avoid wildcard matching on X/Z bits
    // -----------------------------------------------------------------------
    function automatic signed [31:0] get_w;
        input integer cls;
        input integer feat;
        reg [6:0] key;
        begin
            key = {cls[2:0], feat[3:0]};
            case (key)
                7'h00: get_w=`W_0_0;  7'h01: get_w=`W_0_1;  7'h02: get_w=`W_0_2;
                7'h03: get_w=`W_0_3;  7'h04: get_w=`W_0_4;  7'h05: get_w=`W_0_5;
                7'h06: get_w=`W_0_6;  7'h07: get_w=`W_0_7;  7'h08: get_w=`W_0_8;
                7'h09: get_w=`W_0_9;  7'h0A: get_w=`W_0_10; 7'h0B: get_w=`W_0_11;
                7'h0C: get_w=`W_0_12; 7'h0D: get_w=`W_0_13; 7'h0E: get_w=`W_0_14;

                7'h10: get_w=`W_1_0;  7'h11: get_w=`W_1_1;  7'h12: get_w=`W_1_2;
                7'h13: get_w=`W_1_3;  7'h14: get_w=`W_1_4;  7'h15: get_w=`W_1_5;
                7'h16: get_w=`W_1_6;  7'h17: get_w=`W_1_7;  7'h18: get_w=`W_1_8;
                7'h19: get_w=`W_1_9;  7'h1A: get_w=`W_1_10; 7'h1B: get_w=`W_1_11;
                7'h1C: get_w=`W_1_12; 7'h1D: get_w=`W_1_13; 7'h1E: get_w=`W_1_14;

                7'h20: get_w=`W_2_0;  7'h21: get_w=`W_2_1;  7'h22: get_w=`W_2_2;
                7'h23: get_w=`W_2_3;  7'h24: get_w=`W_2_4;  7'h25: get_w=`W_2_5;
                7'h26: get_w=`W_2_6;  7'h27: get_w=`W_2_7;  7'h28: get_w=`W_2_8;
                7'h29: get_w=`W_2_9;  7'h2A: get_w=`W_2_10; 7'h2B: get_w=`W_2_11;
                7'h2C: get_w=`W_2_12; 7'h2D: get_w=`W_2_13; 7'h2E: get_w=`W_2_14;

                7'h30: get_w=`W_3_0;  7'h31: get_w=`W_3_1;  7'h32: get_w=`W_3_2;
                7'h33: get_w=`W_3_3;  7'h34: get_w=`W_3_4;  7'h35: get_w=`W_3_5;
                7'h36: get_w=`W_3_6;  7'h37: get_w=`W_3_7;  7'h38: get_w=`W_3_8;
                7'h39: get_w=`W_3_9;  7'h3A: get_w=`W_3_10; 7'h3B: get_w=`W_3_11;
                7'h3C: get_w=`W_3_12; 7'h3D: get_w=`W_3_13; 7'h3E: get_w=`W_3_14;

                7'h40: get_w=`W_4_0;  7'h41: get_w=`W_4_1;  7'h42: get_w=`W_4_2;
                7'h43: get_w=`W_4_3;  7'h44: get_w=`W_4_4;  7'h45: get_w=`W_4_5;
                7'h46: get_w=`W_4_6;  7'h47: get_w=`W_4_7;  7'h48: get_w=`W_4_8;
                7'h49: get_w=`W_4_9;  7'h4A: get_w=`W_4_10; 7'h4B: get_w=`W_4_11;
                7'h4C: get_w=`W_4_12; 7'h4D: get_w=`W_4_13; 7'h4E: get_w=`W_4_14;

                7'h50: get_w=`W_5_0;  7'h51: get_w=`W_5_1;  7'h52: get_w=`W_5_2;
                7'h53: get_w=`W_5_3;  7'h54: get_w=`W_5_4;  7'h55: get_w=`W_5_5;
                7'h56: get_w=`W_5_6;  7'h57: get_w=`W_5_7;  7'h58: get_w=`W_5_8;
                7'h59: get_w=`W_5_9;  7'h5A: get_w=`W_5_10; 7'h5B: get_w=`W_5_11;
                7'h5C: get_w=`W_5_12; 7'h5D: get_w=`W_5_13; 7'h5E: get_w=`W_5_14;
                default: get_w = 32'sh00000000;
            endcase
        end
    endfunction

    // -----------------------------------------------------------------------
    // Bias lookup - Q8.24, sign-extended to 64 bits
    // Use 64-bit signed intermediates to avoid macro bit-index syntax errors
    // in Vivado Verilog-2001 parser (can't do `DEFINE[31] in replication).
    // Assigning a 32'sh literal to a signed [63:0] reg sign-extends correctly.
    // -----------------------------------------------------------------------
    function automatic signed [63:0] get_b;
        input integer cls;
        reg signed [63:0] tmp;
        begin
            case (cls)
                0: begin tmp = $signed(`B_0); get_b = tmp; end
                1: begin tmp = $signed(`B_1); get_b = tmp; end
                2: begin tmp = $signed(`B_2); get_b = tmp; end
                3: begin tmp = $signed(`B_3); get_b = tmp; end
                4: begin tmp = $signed(`B_4); get_b = tmp; end
                5: begin tmp = $signed(`B_5); get_b = tmp; end
                default: get_b = 64'sd0;
            endcase
        end
    endfunction

    // -----------------------------------------------------------------------
    // Pack flat ports into internal wire array
    // -----------------------------------------------------------------------
    wire signed [31:0] x [0:14];
    assign x[0]=x0;   assign x[1]=x1;   assign x[2]=x2;
    assign x[3]=x3;   assign x[4]=x4;   assign x[5]=x5;
    assign x[6]=x6;   assign x[7]=x7;   assign x[8]=x8;
    assign x[9]=x9;   assign x[10]=x10; assign x[11]=x11;
    assign x[12]=x12; assign x[13]=x13; assign x[14]=x14;

    // -----------------------------------------------------------------------
    // 15 parallel multipliers (combinational)
    // Q8.24 x Q8.24 → 64-bit, arithmetic right-shift 24 → Q8.24
    // -----------------------------------------------------------------------
    wire signed [63:0] prod [0:14];
    genvar j;
    generate
        for (j = 0; j < 15; j = j + 1) begin : g_mul
            assign prod[j] = ($signed(get_w(CLASSIFIER, j)) *
                              $signed(x[j])) >>> 24;
        end
    endgenerate

    // -----------------------------------------------------------------------
    // 3-level registered adder tree
    //   Stage 1 (l0): 8 outputs, valid_l0
    //   Stage 2 (l1): 4 outputs, valid_l1
    //   Stage 3 (l2): 2 outputs, valid_l2
    //   Stage 4 (out): final sum + bias → score, out_valid
    // Total pipeline latency: 4 stages
    // -----------------------------------------------------------------------
    reg signed [63:0] l0 [0:7];
    reg signed [63:0] l1 [0:3];
    reg signed [63:0] l2 [0:1];
    reg valid_l0, valid_l1, valid_l2;

    // Stage 1: pairwise sums (prod[14] unpaired → l0[7])
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_l0 <= 1'b0;
            l0[0]<=0; l0[1]<=0; l0[2]<=0; l0[3]<=0;
            l0[4]<=0; l0[5]<=0; l0[6]<=0; l0[7]<=0;
        end else begin
            valid_l0 <= in_valid;
            if (in_valid) begin
                l0[0] <= prod[0]  + prod[1];
                l0[1] <= prod[2]  + prod[3];
                l0[2] <= prod[4]  + prod[5];
                l0[3] <= prod[6]  + prod[7];
                l0[4] <= prod[8]  + prod[9];
                l0[5] <= prod[10] + prod[11];
                l0[6] <= prod[12] + prod[13];
                l0[7] <= prod[14];
            end
        end
    end

    // Stage 2
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_l1 <= 1'b0;
            l1[0]<=0; l1[1]<=0; l1[2]<=0; l1[3]<=0;
        end else begin
            valid_l1 <= valid_l0;
            if (valid_l0) begin
                l1[0] <= l0[0] + l0[1];
                l1[1] <= l0[2] + l0[3];
                l1[2] <= l0[4] + l0[5];
                l1[3] <= l0[6] + l0[7];
            end
        end
    end

    // Stage 3
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_l2 <= 1'b0;
            l2[0]<=0; l2[1]<=0;
        end else begin
            valid_l2 <= valid_l1;
            if (valid_l1) begin
                l2[0] <= l1[0] + l1[1];
                l2[1] <= l1[2] + l1[3];
            end
        end
    end

    // Stage 4: final sum + bias
    // FIXED: bias (B_k) is now added here
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out_valid <= 1'b0;
            score     <= 64'sd0;
        end else begin
            out_valid <= valid_l2;
            if (valid_l2)
                score <= l2[0] + l2[1] + get_b(CLASSIFIER);
        end
    end

endmodule
