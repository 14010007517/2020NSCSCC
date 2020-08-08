module ex_mem (
    input wire clk, rst,flushM,
    input wire stallM,
    input wire [31:0] pcE,
    input wire [63:0] alu_outE,
    input wire [31:0] rt_valueE,
    input wire [4:0] reg_writeE,
    input wire [31:0] instrE,
    input wire branchE,
    input wire pred_takeE,
    input wire [31:0] pc_branchE,
    input wire overflowE,
    input wire is_in_delayslot_iE,
    input wire [4:0] rdE,
    input wire actual_takeE,
    input wire [7:0] l_s_typeE,
    input wire [1:0] mfhi_loE,

    output reg [31:0] pcM,
    output reg [31:0] alu_outM,
    output reg [31:0] rt_valueM,
    output reg [4:0] reg_writeM,
    output reg [31:0] instrM,
    output reg branchM,
    output reg pred_takeM,
    output reg [31:0] pc_branchM,
    output reg overflowM,        
    output reg is_in_delayslot_iM,
    output reg [4:0] rdM,
    output reg actual_takeM,
    output reg [7:0] l_s_typeM,
    output reg [1:0] mfhi_loM
);
    always @(posedge clk) begin
        if(rst | flushM) begin
            pcM                     <=              0;
            alu_outM                <=              0;
            rt_valueM               <=              0;
            reg_writeM              <=              0;
            instrM                  <=              0;
            branchM                 <=              0;
            pred_takeM              <=              0;
            pc_branchM              <=              0;
            overflowM               <=              0;
            is_in_delayslot_iM      <=              0;
            rdM                     <=              0;
            actual_takeM            <=              0;
            l_s_typeM               <=              0;
            mfhi_loM                <=              0;
        end
        else if(~stallM) begin
            pcM                     <=           pcE                ;
            alu_outM                <=           alu_outE[31:0]     ;
            rt_valueM               <=           rt_valueE          ;
            reg_writeM              <=           reg_writeE         ;
            instrM                  <=           instrE             ;
            branchM                 <=           branchE            ;
            pred_takeM              <=           pred_takeE         ;
            pc_branchM              <=           pc_branchE         ;
            overflowM               <=           overflowE          ;
            is_in_delayslot_iM      <=           is_in_delayslot_iE ;
            rdM                     <=           rdE                ;
            actual_takeM            <=           actual_takeE       ;
            l_s_typeM               <=           l_s_typeE          ;
            mfhi_loM                <=           mfhi_loE           ;
        end
    end
endmodule