`include "defines.vh"
module branch_predict (
    input wire [31:0] instrD,
    input wire [31:0] immD,

    output wire branchD,
    output wire pred_takeD
);

    assign branchD = ( ~(|(instrD[31:26] ^`EXE_BRANCHS)) &  ~(|(instrD[19:17] ^ 3'b000)) ) 
                    | ~(|(instrD[31:28] ^4'b0001)); //4'b0001 -> beq, bgtz, blez, bne

    assign pred_takeD = branchD & (immD[31]) ? 1'b1 : 1'b0; //向上跳转，向下不跳转

endmodule