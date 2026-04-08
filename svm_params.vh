// ================================================================
// svm_params.vh  - PMDC Motor Fault Detection
// Fixed-point format : Q8.24  (signed 32-bit)
// Scale factor       : 2^24 = 16,777,216
//
// FIX: Changed localparam signed to `define so this file
//      compiles in Verilog-95/2001/2005 AND SystemVerilog mode.
//      localparam signed requires SystemVerilog; `define works everywhere.
// ================================================================

`ifndef SVM_PARAMS_VH
`define SVM_PARAMS_VH

// ── Feature selection indices (0-based, out of 34 raw features) ──────────────
`define SEL_0   0
`define SEL_1   3
`define SEL_2   4
`define SEL_3   5
`define SEL_4   7
`define SEL_5   8
`define SEL_6   9
`define SEL_7   11
`define SEL_8   25
`define SEL_9   26
`define SEL_10  28
`define SEL_11  30
`define SEL_12  31
`define SEL_13  32
`define SEL_14  33

// ── SVM Weights  W_<classifier>_<feature>  Q8.24 signed 32-bit ──────────────
// Classifier 0 : class 0 vs class 1
`define W_0_0   32'sh00003A70
`define W_0_1   32'sh00000000
`define W_0_2   32'sh00000000
`define W_0_3   32'sh0BB3A64A
`define W_0_4   32'sh00000000
`define W_0_5   32'shFFD36807
`define W_0_6   32'shFF58A62D
`define W_0_7   32'sh0047370A
`define W_0_8   32'sh0123782A
`define W_0_9   32'sh0262A0AF
`define W_0_10  32'sh0201E315
`define W_0_11  32'shFD978697
`define W_0_12  32'shFE00B1F5
`define W_0_13  32'shFE745F1A
`define W_0_14  32'shFED1B5D7

// Classifier 1 : class 0 vs class 2
`define W_1_0   32'shFFFFB78A
`define W_1_1   32'sh00000000
`define W_1_2   32'sh00000000
`define W_1_3   32'shFF915BA1
`define W_1_4   32'sh00000002
`define W_1_5   32'sh006A7984
`define W_1_6   32'sh00302866
`define W_1_7   32'sh01B9A05A
`define W_1_8   32'sh047CACF5
`define W_1_9   32'sh0329F819
`define W_1_10  32'sh035A4CEC
`define W_1_11  32'shFE9D1B68
`define W_1_12  32'shFF10FDA5
`define W_1_13  32'shFFB425AF
`define W_1_14  32'sh005EA8CC

// Classifier 2 : class 0 vs class 3
`define W_2_0   32'shFFFFFEEA
`define W_2_1   32'sh00000000
`define W_2_2   32'sh00000000
`define W_2_3   32'shFFBA0190
`define W_2_4   32'sh00000000
`define W_2_5   32'sh00769A08
`define W_2_6   32'sh0070C676
`define W_2_7   32'shFFFB3EED
`define W_2_8   32'shFEDB80E7
`define W_2_9   32'sh00772EA6
`define W_2_10  32'shFE93F999
`define W_2_11  32'sh010577E5
`define W_2_12  32'sh01445A8A
`define W_2_13  32'sh011195A7
`define W_2_14  32'sh00D7B728

// Classifier 3 : class 1 vs class 2
`define W_3_0   32'shFFFFC6FC
`define W_3_1   32'sh00000000
`define W_3_2   32'sh00000000
`define W_3_3   32'shF3E2E50D
`define W_3_4   32'sh00000000
`define W_3_5   32'sh00223CCA
`define W_3_6   32'sh006A2F28
`define W_3_7   32'shFFD4D503
`define W_3_8   32'sh00DFC695
`define W_3_9   32'shFFB7F1C6
`define W_3_10  32'sh0043C60D
`define W_3_11  32'sh007EB934
`define W_3_12  32'sh007C9351
`define W_3_13  32'sh0075E409
`define W_3_14  32'sh006DDCA7

// Classifier 4 : class 1 vs class 3
`define W_4_0   32'shFFFFF5D8
`define W_4_1   32'sh00000000
`define W_4_2   32'sh00000000
`define W_4_3   32'shFD801AF9
`define W_4_4   32'sh00000000
`define W_4_5   32'sh0066B726
`define W_4_6   32'sh00AE0718
`define W_4_7   32'shFFA57EDC
`define W_4_8   32'shFDE82BA4
`define W_4_9   32'sh001F7601
`define W_4_10  32'shFEEA409C
`define W_4_11  32'sh008CDB3B
`define W_4_12  32'sh01AB0298
`define W_4_13  32'sh0157158B
`define W_4_14  32'sh0113F2D8

// Classifier 5 : class 2 vs class 3
`define W_5_0   32'shFFFFFFD8
`define W_5_1   32'sh00000000
`define W_5_2   32'sh00000000
`define W_5_3   32'sh0008CD8E
`define W_5_4   32'sh00000000
`define W_5_5   32'sh0079E973
`define W_5_6   32'sh0034941E
`define W_5_7   32'sh0008552B
`define W_5_8   32'shFF1A0BBC
`define W_5_9   32'sh003DE811
`define W_5_10  32'shFE6411DF
`define W_5_11  32'shFFEA5A8B
`define W_5_12  32'sh003331FC
`define W_5_13  32'sh003D1BEA
`define W_5_14  32'sh00371771

// ── Intercepts  B_<classifier>  Q8.24 signed 32-bit ─────────────────────────
`define B_0     32'sh081EBE37
`define B_1     32'sh030B8AC8
`define B_2     32'sh017239ED
`define B_3     32'shF8F34A62
`define B_4     32'sh01211031
`define B_5     32'sh00E5D636

`endif // SVM_PARAMS_VH
