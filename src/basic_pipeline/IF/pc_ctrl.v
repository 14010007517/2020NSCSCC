module pc_ctrl(
    input wire branchD,
    input wire branchE,
    input wire pred_takeD,
    input wire succE,
    input wire actual_takeE,

    output reg [1:0] pc_sel
);
    always @(*) begin
        casex({branchD, branchE, pred_takeD, succE, actual_takeE})
            5'b00xxx: pc_sel <= 2'b00;
            5'b100xx: pc_sel <= 2'b00;
            5'b101xx: pc_sel <= 2'b01;
            5'b01x1x: pc_sel <= 2'b00;
            5'b01x01: pc_sel <= 2'b10;
            5'b01x00: pc_sel <= 2'b11;
            5'b11x00: pc_sel <= 2'b10;
            5'b11x01: pc_sel <= 2'b11;
            5'b1101x: pc_sel <= 2'b00;
            5'b1111x: pc_sel <= 2'b01;
            default:
                pc_sel <= 2'b00;
        endcase
    end 
endmodule