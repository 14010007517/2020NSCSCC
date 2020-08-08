module if_id(
    input wire clk, rst,
    input wire flushD,
    input wire stallD,
    input wire [31:0] pcF,
    input wire [31:0] pc_plus4F,

    input wire [31:0] instrF,
    input wire is_in_delayslot_iF,


    output reg [31:0] pcD,
    output reg [31:0] pc_plus4D,
    output reg [31:0] instrD,
    output reg is_in_delayslot_iD
);

    always @(posedge clk) begin
        if(rst | flushD) begin
            pcD                 <= 0    ;
            pc_plus4D           <= 0    ;
            instrD              <= 0    ;
            is_in_delayslot_iD  <= 0    ;
        end
        else if(~stallD) begin
            pcD                 <= pcF                  ;
            pc_plus4D           <= pc_plus4F            ;
            instrD              <= instrF               ;
            is_in_delayslot_iD  <= is_in_delayslot_iF   ;
        end
    end
endmodule