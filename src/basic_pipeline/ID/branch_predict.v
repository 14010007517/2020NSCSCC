`include "defines.vh"
module branch_predict (
    input wire [31:0] instrD,
    input wire [31:0] rd1D, rd2D,

    output reg branch_takeD
);
    // assign branch_takeD = ;
    wire [31:0] a, b;
    assign a = rd1D;
    assign b = rd2D;
    always @(*) begin
        case(instrD[31:26])
            `EXE_BEQ:
                branch_takeD <= ( a == b );
            `EXE_BGTZ: 
                branch_takeD <= (  $signed(a) >  0 );
            `EXE_BLEZ:      
                branch_takeD <= (  $signed(a) <= 0 );
            `EXE_BNE:
                branch_takeD <= (  a != b );
            
            `EXE_BRANCHS:   //bltz, bltzal, bgez, bgezal
                case(instrD[20:16])
                    `EXE_BLTZ, `EXE_BLTZAL:      
                        branch_takeD <= (  $signed(a) <  0 );
                    `EXE_BGEZ, `EXE_BGEZAL: 
                        branch_takeD <= (  $signed(a) >= 0 );
                    default:
                        branch_takeD <= 1'b0; 
                endcase
            default:
                branch_takeD <= 1'b0;
        endcase
    end

endmodule