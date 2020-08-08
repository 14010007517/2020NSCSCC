module id_ex (
    input wire clk, rst,
    input wire stallE,
    input wire flushE,
    input wire [31:0] pcD,
    input wire [31:0] rd1D, rd2D,
    input wire [4:0] rsD, rtD, rdD,
    input wire [31:0] immD,
    input wire [31:0] pc_plus4D,
    input wire [31:0] instrD,
    input wire [31:0] pc_branchD,
    input wire pred_takeD,
    input wire branchD,
    input wire jump_conflictD,
    input wire [4:0] saD,
    input wire is_in_delayslot_iD,
    input wire [4:0] alu_controlD,
    input wire jumpD,
    input wire [4:0] branch_judge_controlD,
    input wire [7:0] l_s_typeD,
    input wire [1:0] mfhi_loD,

    output reg [31:0] pcE,
    output reg [31:0] rd1E, rd2E,
    output reg [4:0] rsE, rtE, rdE,
    output reg [31:0] immE,
    output reg [31:0] pc_plus4E,
    output reg [31:0] instrE,
    output reg [31:0] pc_branchE,
    output reg pred_takeE,
    output reg branchE,
    output reg jump_conflictE,    
    output reg [4:0] saE,        
    output reg is_in_delayslot_iE,
    output reg [4:0] alu_controlE,
    output reg jumpE,
    output reg [4:0] branch_judge_controlE,
    output reg [7:0] l_s_typeE,
    output reg [1:0] mfhi_loE
);
    always @(posedge clk) begin
        if(rst | flushE) begin
            pcE                     <=      0 ;
            rd1E                    <=      0 ;
            rd2E                    <=      0 ;
            rsE                     <=      0 ;
            rtE                     <=      0 ;
            rdE                     <=      0 ;
            immE                    <=      0 ;
            pc_plus4E               <=      0 ;
            instrE                  <=      0 ;
            pc_branchE              <=      0 ;
            pred_takeE              <=      0 ;
            branchE                 <=      0 ;
            jump_conflictE          <=      0 ;
            saE                     <=      0 ;
            is_in_delayslot_iE      <=      0 ;
            alu_controlE            <=      0 ;
            jumpE                   <=      0 ;
            branch_judge_controlE   <=      0 ;
            l_s_typeE               <=      0 ;
            mfhi_loE                <=      0 ;
        end 
        else if(~stallE) begin
            pcE                     <= pcD                  ;
            rd1E                    <= rd1D                 ;
            rd2E                    <= rd2D                 ;
            rsE                     <= rsD                  ;
            rtE                     <= rtD                  ;
            rdE                     <= rdD                  ;
            immE                    <= immD                 ;
            pc_plus4E               <= pc_plus4D            ;
            instrE                  <= instrD               ;
            pc_branchE              <= pc_branchD           ;
            pred_takeE              <= pred_takeD           ;
            branchE                 <= branchD              ;
            jump_conflictE          <= jump_conflictD       ;
            saE                     <= saD                  ;
            is_in_delayslot_iE      <= is_in_delayslot_iD   ;
            alu_controlE            <= alu_controlD         ;
            jumpE                   <= jumpD                ;
            branch_judge_controlE   <= branch_judge_controlD;
            l_s_typeE               <= l_s_typeD            ;
            mfhi_loE                <= mfhi_loD             ;
        end
    end
endmodule