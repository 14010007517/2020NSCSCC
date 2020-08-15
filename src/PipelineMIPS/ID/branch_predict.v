`include "defines.vh"
module branch_predict (
    input wire clk, rst,
    input wire [31:0] instrD,
    input wire [31:0] immD,

    input wire [31:0] pcD,
    input wire [31:0] pcM,
    input wire branchM,
    input wire actual_takeM,

    output wire branchD,
    output wire branchL_D,
    output wire pred_takeD
);

    assign branchD = ( !(instrD[31:26] ^ `EXE_REGIMM) & (!(instrD[19:17] ^ 3'b000) | !(instrD[19:17] ^ 3'b001)) ) 
                    | !(instrD[31:28] ^ 4'b0001); //4'b0001 -> beq, bgtz, blez, bne
                                                    // 3'b000 -> BLTZ BLTZAL BGEZAL BGEZ
                                                    // 3'b001 -> BGEZALL BGEZL BLTZALL BLTZL
    assign branchL_D = ( !(instrD[31:26] ^ `EXE_REGIMM) & !(instrD[19:17] ^ 3'b001) );


    parameter Strongly_not_taken = 2'b00, Weakly_not_taken = 2'b01, Weakly_taken = 2'b11, Strongly_taken = 2'b10;
    parameter PHT_DEPTH = 6;
    parameter BHT_DEPTH = 10;

    reg [5:0] BHT [(1<<BHT_DEPTH)-1 : 0];
    reg [1:0] PHT [(1<<PHT_DEPTH)-1:0];
    integer i,j;
    wire [(PHT_DEPTH-1):0] PHT_index;
    wire [(BHT_DEPTH-1):0] BHT_index;
    wire [(PHT_DEPTH-1):0] BHR_value;

    assign BHT_index = pcD[11:2];     
    assign BHR_value = BHT[BHT_index];  
    assign PHT_index = BHR_value;

    // 根据pc[19：2]索引pht对应位；
    assign pred_takeD = branchD & PHT[PHT_index][1];    // 跳转状态最高位都为1；
    // assign pred_takeD = branchD & (~immD[31]) ? 1'b1 : 1'b0; //向上跳转，向下不跳转
    // assign pred_takeD = branchD & (immD[31]) ? 1'b1 : 1'b0; //向上跳转，向下不跳转

    // BHT初始化以及更新
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

    // PHT初始化以及更新
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


endmodule