module branch_judge (
    input wire [4:0] branch_judge_controlE,
    input wire [31:0] src_aE, src_bE,

    output reg actual_takeE
);
    always @(*) begin
        case(branch_judge_controlE)
            `ALU_EQ:        actual_takeE = ~(|(src_aE ^ src_bE));
            `ALU_NEQ:       actual_takeE = |(src_aE ^ src_bE);
            `ALU_GTZ:       actual_takeE = ~src_aE[31] & (|src_aE);
            `ALU_GEZ:       actual_takeE = ~src_aE[31];
            `ALU_LTZ:       actual_takeE = src_aE[31];
            `ALU_LEZ:       actual_takeE = src_aE[31] | ~(|src_aE);
            default:
                actual_takeE = 1'b0;
        endcase
    end
endmodule