//module:       mul
//description:  booth-2 code multiplier
//version:      1.0

module mul_booth2(
    // input               clk,
    // input               rst,
    input [31:0]        a,
    input [31:0]        b,
    // input               valid,
    input               sign,   //1:signed

    // output reg          ready,
    output [63:0]       result
    );

//booth code
    wire [32:0] a_ex, b_ex;
    assign a_ex = sign ? {a[31],a} : {1'b0,a};
    assign b_ex = sign ? {b[31],b} : {1'b0,b};

    wire [64:0] x, neg_x, xx, neg_xx;
    assign x = {{32{a_ex[32]}},a_ex};
    assign xx = {x[63:0],1'b0};
    assign neg_x = ~x + 1'b1;
    assign neg_xx = ~xx + 1'b1;

//generate partitial production
    wire [64:0] part_prod [0:16];

    assign part_prod[0] = b_ex[0] ? neg_x : 65'b0;

    assign part_prod[1] = b_ex[2] ? ( b_ex[1] ^ b_ex[0] ? {neg_x[63:0],1'b0} : (b_ex[0] ? 65'b0 : {neg_xx[63:0],1'b0})):
                                ( b_ex[1] ^ b_ex[0] ? {x[63:0],1'b0} : (b_ex[0] ? {xx[63:0],1'b0} : 65'b0));
    assign part_prod[2] = b_ex[4] ? ( b_ex[3] ^ b_ex[2] ? {neg_x[61:0],3'b0} : (b_ex[2] ? 65'b0 : {neg_xx[61:0],3'b0})):
                                    ( b_ex[3] ^ b_ex[2] ? {x[61:0],3'b0} : (b_ex[2] ? {xx[61:0],3'b0} : 65'b0));
    assign part_prod[3] = b_ex[6] ? ( b_ex[5] ^ b_ex[4] ? {neg_x[59:0],5'b0} : (b_ex[4] ? 65'b0 : {neg_xx[59:0],5'b0})):
                                    ( b_ex[5] ^ b_ex[4] ? {x[59:0],5'b0} : (b_ex[4] ? {xx[59:0],5'b0} : 65'b0));
    assign part_prod[4] = b_ex[8] ? ( b_ex[7] ^ b_ex[6] ? {neg_x[57:0],7'b0} : (b_ex[6] ? 65'b0 : {neg_xx[57:0],7'b0})):
                                    ( b_ex[7] ^ b_ex[6] ? {x[57:0],7'b0} : (b_ex[6] ? {xx[57:0],7'b0} : 65'b0));
    assign part_prod[5] = b_ex[10] ? ( b_ex[9] ^ b_ex[8] ? {neg_x[55:0],9'b0} : (b_ex[8] ? 65'b0 : {neg_xx[55:0],9'b0})):
                                    ( b_ex[9] ^ b_ex[8] ? {x[55:0],9'b0} : (b_ex[8] ? {xx[55:0],9'b0} : 65'b0));
    assign part_prod[6] = b_ex[12] ? ( b_ex[11] ^ b_ex[10] ? {neg_x[53:0],11'b0} : (b_ex[10] ? 65'b0 : {neg_xx[53:0],11'b0})):
                                    ( b_ex[11] ^ b_ex[10] ? {x[53:0],11'b0} : (b_ex[10] ? {xx[53:0],11'b0} : 65'b0));
    assign part_prod[7] = b_ex[14] ? ( b_ex[13] ^ b_ex[12] ? {neg_x[51:0],13'b0} : (b_ex[12] ? 65'b0 : {neg_xx[51:0],13'b0})):
                                    ( b_ex[13] ^ b_ex[12] ? {x[51:0],13'b0} : (b_ex[12] ? {xx[51:0],13'b0} : 65'b0));
    assign part_prod[8] = b_ex[16] ? ( b_ex[15] ^ b_ex[14] ? {neg_x[49:0],15'b0} : (b_ex[14] ? 65'b0 : {neg_xx[49:0],15'b0})):
                                    ( b_ex[15] ^ b_ex[14] ? {x[49:0],15'b0} : (b_ex[14] ? {xx[49:0],15'b0} : 65'b0));
    assign part_prod[9] = b_ex[18] ? ( b_ex[17] ^ b_ex[16] ? {neg_x[47:0],17'b0} : (b_ex[16] ? 65'b0 : {neg_xx[47:0],17'b0})):
                                    ( b_ex[17] ^ b_ex[16] ? {x[47:0],17'b0} : (b_ex[16] ? {xx[47:0],17'b0} : 65'b0));
    assign part_prod[10] = b_ex[20] ? ( b_ex[19] ^ b_ex[18] ? {neg_x[45:0],19'b0} : (b_ex[18] ? 65'b0 : {neg_xx[45:0],19'b0})):
                                    ( b_ex[19] ^ b_ex[18] ? {x[45:0],19'b0} : (b_ex[18] ? {xx[45:0],19'b0} : 65'b0));
    assign part_prod[11] = b_ex[22] ? ( b_ex[21] ^ b_ex[20] ? {neg_x[43:0],21'b0} : (b_ex[20] ? 65'b0 : {neg_xx[43:0],21'b0})):
                                    ( b_ex[21] ^ b_ex[20] ? {x[43:0],21'b0} : (b_ex[20] ? {xx[43:0],21'b0} : 65'b0));
    assign part_prod[12] = b_ex[24] ? ( b_ex[23] ^ b_ex[22] ? {neg_x[41:0],23'b0} : (b_ex[22] ? 65'b0 : {neg_xx[41:0],23'b0})):
                                    ( b_ex[23] ^ b_ex[22] ? {x[41:0],23'b0} : (b_ex[22] ? {xx[41:0],23'b0} : 65'b0));
    assign part_prod[13] = b_ex[26] ? ( b_ex[25] ^ b_ex[24] ? {neg_x[39:0],25'b0} : (b_ex[24] ? 65'b0 : {neg_xx[39:0],25'b0})):
                                    ( b_ex[25] ^ b_ex[24] ? {x[39:0],25'b0} : (b_ex[24] ? {xx[39:0],25'b0} : 65'b0));
    assign part_prod[14] = b_ex[28] ? ( b_ex[27] ^ b_ex[26] ? {neg_x[37:0],27'b0} : (b_ex[26] ? 65'b0 : {neg_xx[37:0],27'b0})):
                                    ( b_ex[27] ^ b_ex[26] ? {x[37:0],27'b0} : (b_ex[26] ? {xx[37:0],27'b0} : 65'b0));
    assign part_prod[15] = b_ex[30] ? ( b_ex[29] ^ b_ex[28] ? {neg_x[35:0],29'b0} : (b_ex[28] ? 65'b0 : {neg_xx[35:0],29'b0})):
                                    ( b_ex[29] ^ b_ex[28] ? {x[35:0],29'b0} : (b_ex[28] ? {xx[35:0],29'b0} : 65'b0));
    assign part_prod[16] = b_ex[32] ? ( b_ex[31] ^ b_ex[30] ? {neg_x[33:0],31'b0} : (b_ex[30] ? 65'b0 : {neg_xx[33:0],31'b0})):
                                    ( b_ex[31] ^ b_ex[30] ? {x[33:0],31'b0} : (b_ex[30] ? {xx[33:0],31'b0} : 65'b0));

//tree
    // wire [66:0] C1[0:4],S1[0:4];
    // wire [66:0] C2[0:3],S2[0:3];
    // wire [65:0] C3[0:1],S3[0:1];
    // wire [65:0] C4[0:1],S4[0:1];
    // wire [65:0] C5,S5;
    // wire [65:0] C6,S6;
    wire [64:0] C[0:14],C_temp[0:14],S[0:14];
    wire [64:0] result_tmp;
    //layer1
    assign S[0] = part_prod[16] ^ part_prod[15] ^ part_prod[14];
    assign S[1] = part_prod[13] ^ part_prod[12] ^ part_prod[11];
    assign S[2] = part_prod[10] ^ part_prod[9] ^ part_prod[8];
    assign S[3] = part_prod[7] ^ part_prod[6] ^ part_prod[5];
    assign S[4] = part_prod[4] ^ part_prod[3] ^ part_prod[2];
    assign C_temp[0] = (part_prod[16]&part_prod[15]) | (part_prod[15]&part_prod[14]) | (part_prod[16]&part_prod[14]);
    assign C_temp[1] = (part_prod[13]&part_prod[12]) | (part_prod[12]&part_prod[11]) | (part_prod[13]&part_prod[11]);
    assign C_temp[2] = (part_prod[10]&part_prod[9]) | (part_prod[9]&part_prod[8]) | (part_prod[10]&part_prod[8]);
    assign C_temp[3] = (part_prod[7]&part_prod[6]) | (part_prod[6]&part_prod[5]) | (part_prod[7]&part_prod[5]);
    assign C_temp[4] = (part_prod[4]&part_prod[3]) | (part_prod[3]&part_prod[2]) | (part_prod[4]&part_prod[2]);
    assign C[0] = {C_temp[0][63:0],1'b0};
    assign C[1] = {C_temp[1][63:0],1'b0};
    assign C[2] = {C_temp[2][63:0],1'b0};
    assign C[3] = {C_temp[3][63:0],1'b0};
    assign C[4] = {C_temp[4][63:0],1'b0};
    //2
    assign S[5] = S[0] ^ S[1] ^ S[2];
    assign S[6] = S[3] ^ S[4] ^ part_prod[1];
    assign S[7] = part_prod[0] ^ C[0] ^ C[1];
    assign S[8] = C[2] ^ C[3] ^ C[4];
    assign C_temp[5] = (S[0]&S[1]) | (S[1]&S[2]) | (S[0]&S[2]);
    assign C_temp[6] = (S[3]&S[4]) | (S[4]&part_prod[1]) | (S[3]&part_prod[1]);
    assign C_temp[7] = (part_prod[0]&C[0]) | (C[0]&C[1]) | (part_prod[0]&C[1]);
    assign C_temp[8] = (C[2]&C[3]) | (C[3]&C[4]) | (C[2]&C[4]);
    assign C[5] = {C_temp[5][63:0],1'b0};
    assign C[6] = {C_temp[6][63:0],1'b0};
    assign C[7] = {C_temp[7][63:0],1'b0};
    assign C[8] = {C_temp[8][63:0],1'b0};
    //3
    assign S[9] = S[5] ^ S[6] ^ S[7];
    assign S[10] = S[8] ^ C[5] ^ C[6];
    assign C_temp[9] = (S[5]&S[6]) | (S[6]&S[7]) | (S[5]&S[7]);
    assign C_temp[10] = (S[8]&C[5]) | (C[5]&C[6]) | (S[8]&C[6]);
    assign C[9] = {C_temp[9][63:0],1'b0};
    assign C[10] = {C_temp[10][63:0],1'b0};
    //4
    assign S[11] = S[9] ^ S[10] ^ C[7];
    assign S[12] = C[8] ^ C[9] ^ C[10];
    assign C_temp[11] = (S[9]&S[10]) | (S[10]&C[7]) | (S[9]&C[7]);
    assign C_temp[12] = (C[8]&C[9]) | (C[9]&C[10]) | (C[8]&C[10]);
    assign C[11] = {C_temp[11][63:0],1'b0};
    assign C[12] = {C_temp[12][63:0],1'b0};
    //5
    assign S[13] = S[11] ^ S[12] ^ C[11];
    assign C_temp[13] = (S[11]&S[12]) | (S[12]&C[11]) | (S[11]&C[11]);
    assign C[13] = {C_temp[13][63:0],1'b0};
    //6
    assign S[14] = S[13] ^ C[12] ^ C[13];
    assign C_temp[14] = (S[13]&C[12]) | (C[12]&C[13]) | (S[13]&C[13]);
    assign C[14] = {C_temp[14][63:0],1'b0};
    //top
    assign result_tmp = S[14] + C[14];
    assign result = result_tmp[63:0];
endmodule