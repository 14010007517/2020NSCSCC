`include "defines.vh"
module branch_predict (
    input wire [31:0] instrD,
    input wire [31:0] immD,

    output wire branchD,
    output wire pred_takeD
);
    // // assign branch_takeD = ;
    // wire [31:0] a, b;
    // assign a = rd1D;
    // assign b = rd2D;
    // always @(*) begin
    //     case(instrD[31:26])
    //         `EXE_BEQ:
    //             branch_takeD <= ( a == b );
    //         `EXE_BGTZ: 
    //             branch_takeD <= (  $signed(a) >  0 );
    //         `EXE_BLEZ:      
    //             branch_takeD <= (  $signed(a) <= 0 );
    //         `EXE_BNE:
    //             branch_takeD <= (  a != b );
            
    //         `EXE_BRANCHS:   //bltz, bltzal, bgez, bgezal
    //             case(instrD[20:16])
    //                 `EXE_BLTZ, `EXE_BLTZAL:      
    //                     branch_takeD <= (  $signed(a) <  0 );
    //                 `EXE_BGEZ, `EXE_BGEZAL: 
    //                     branch_takeD <= (  $signed(a) >= 0 );
    //                 default:
    //                     branch_takeD <= 1'b0; 
    //             endcase
    //         default:
    //             branch_takeD <= 1'b0;
    //     endcase
    // end
    assign branchD = ( ~(|(instrD[31:26] ^`EXE_BRANCHS)) &  ~(|(instrD[19:17] ^ 3'b000)) ) 
                    | ~(|(instrD[31:28] ^4'b0001)); //4'b0001 -> beq, bgtz, blez, bne

    assign pred_takeD = branchD & (immD[31]) ? 1'b1 : 1'b0; //向上跳转，向下不跳转

endmodule