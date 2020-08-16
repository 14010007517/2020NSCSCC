`include "defines.vh"
module branch_predict (
    input wire clk, rst,
    
    input wire flushD,
    input wire stallD,

    input wire [31:0] instrD,
    input wire [31:0] immD,

    input wire [31:0] pcF,
    input wire [31:0] pcM,
    input wire branchM,
    input wire actual_takeM,

    output wire branchD,
    output wire branchL_D,
    output wire pred_takeD
);
    wire pred_takeF;
    reg pred_takeF_r;
    wire [5:0] op_code, funct;
    wire [4:0] rt;
    assign op_code = instrD[31:26];
	assign rs = instrD[25:21];
	assign rt = instrD[20:16];
	assign funct = instrD[5:0];
    assign branchD = ( !(op_code ^ `EXE_REGIMM) & (!(instrD[19:17] ^ 3'b000) | !(instrD[19:17] ^ 3'b001)) ) 
                    | !(op_code[5:2] ^ 4'b0001); //4'b0001 -> beq, bgtz, blez, bne
                                                    // 3'b000 -> BLTZ BLTZAL BGEZAL BGEZ
                                                    // 3'b001 -> BGEZALL BGEZL BLTZALL BLTZL
    assign branchL_D = ( !(op_code ^ `EXE_REGIMM) & !(instrD[19:17] ^ 3'b001) ) |
                         !(op_code[5:2] ^ 4'b0101); //beql, bgtzl, blezl, bnel

    parameter Strongly_not_taken = 2'b00, Weakly_not_taken = 2'b01, Weakly_taken = 2'b11, Strongly_taken = 2'b10;
    parameter PHT_DEPTH = 6;
    parameter BHT_DEPTH = 10;

    reg [5:0] BHT [(1<<BHT_DEPTH)-1 : 0];
    reg [1:0] PHT [(1<<PHT_DEPTH)-1:0];
    integer i,j;
    wire [(PHT_DEPTH-1):0] PHT_index;
    wire [(BHT_DEPTH-1):0] BHT_index;
    wire [(PHT_DEPTH-1):0] BHR_value;

    assign BHT_index = pcF[11:2];     
    assign BHR_value = BHT[BHT_index];  
    assign PHT_index = BHR_value;

    assign pred_takeF = PHT[PHT_index][1];

// ---------------------------------------BHT初始化以及更新---------------------------------------
    wire [(PHT_DEPTH-1):0] update_PHT_index;
    wire [(BHT_DEPTH-1):0] update_BHT_index;
    wire [(PHT_DEPTH-1):0] update_BHR_value;

    assign update_BHT_index = pcM[11:2];     
    assign update_BHR_value = BHT[update_BHT_index];  
    assign update_PHT_index = update_BHR_value;

    always@(posedge clk) begin
        if(rst) begin
            for(j = 0; j < (1<<BHT_DEPTH); j=j+1) begin
                BHT[j] <= 0;
            end
        end
        else if(branchM) begin
            BHT[update_BHT_index] <= {BHT[update_BHT_index] << 1, actual_takeM};
        end
    end
// ---------------------------------------BHT初始化以及更新---------------------------------------

// ---------------------------------------PHT初始化以及更新---------------------------------------
    always @(posedge clk) begin
        if(rst) begin
            for(i = 0; i < (1<<PHT_DEPTH); i=i+1) begin
                PHT[i] <= Weakly_taken;
            end
        end
        else begin
            case(PHT[update_PHT_index])
                Strongly_not_taken  :   PHT[update_PHT_index] <= actual_takeM & branchM ? Weakly_not_taken : Strongly_not_taken;
                Weakly_not_taken    :   PHT[update_PHT_index] <= actual_takeM & branchM ? Weakly_taken : Strongly_not_taken;
                Weakly_taken        :   PHT[update_PHT_index] <= actual_takeM & branchM ? Strongly_taken : Weakly_not_taken;
                Strongly_taken      :   PHT[update_PHT_index] <= actual_takeM & branchM ? Strongly_taken : Weakly_taken;
            endcase 
        end
    end
// ---------------------------------------PHT初始化以及更新---------------------------------------

// --------------------------pipeline------------------------------
    always @(posedge clk) begin
        if(rst | flushD) begin
            pred_takeF_r <= 0;
        end
        else if(~stallD) begin
            pred_takeF_r <= pred_takeF;
        end
    end
// --------------------------pipeline------------------------------

    // 根据pc[19：2]索引pht对应位；
    assign pred_takeD = branchD & pred_takeF_r;    // 跳转状态最高位都为1；
    // assign pred_takeD = branchD & (~immD[31]) ? 1'b1 : 1'b0; //向上跳转，向下不跳转
    // assign pred_takeD = branchD & (immD[31]) ? 1'b1 : 1'b0; //向上跳转，向下不跳转
endmodule