module ex_mem (
    input wire clk, rst,flushM,
    input wire stallM,
    input wire [31:0] pcE,
    input wire [63:0] alu_outE,
    input wire [31:0] mem_wdataE,
    input wire [4:0] reg_writeE,
    input wire [31:0] instrE,
    input wire branchE,
    input wire pred_takeE,
    input wire [31:0] pc_branchE,
    input wire overflowE,


    output reg [31:0] pcM,
    output reg [31:0] alu_outM,
    output reg [31:0] mem_wdataM,
    output reg [4:0] reg_writeM,
    output reg [31:0] instrM,
    output reg branchM,
    output reg pred_takeM,
    output reg [31:0] pc_branchM,
    output reg overflowM
);
    always @(posedge clk) begin
        if(rst | flushM) begin
            pcM             <=           0;
            alu_outM        <=           0;
            mem_wdataM      <=           0;
            reg_writeM      <=           0;
            instrM          <=           0;
            branchM         <=           0;
            pred_takeM      <=           0;
            pc_branchM      <=           0;
            overflowM       <=           0;
        end
        else if(~stallM) begin
            pcM             <=           pcE            ;
            alu_outM        <=           alu_outE[31:0] ;
            mem_wdataM      <=           mem_wdataE     ;
            reg_writeM      <=           reg_writeE     ;
            instrM          <=           instrE         ;
            branchM         <=           branchE        ;
            pred_takeM      <=           pred_takeE     ;
            pc_branchM      <=           pc_branchE     ;
            overflowM       <=           overflowE      ;
        end
    end
endmodule