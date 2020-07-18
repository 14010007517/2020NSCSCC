`include "aludefines.vh"

module alu (
    input wire [31:0] src_aE, src_bE,
    input wire [4:0] alu_controlE,

    output reg [31:0] alu_outE
);

    always @(*) begin
        case(alu_controlE)
            `ALU_AND:       alu_outE <= src_aE & src_bE;
            `ALU_OR:        alu_outE <= src_aE | src_bE;
            `ALU_NOR:       alu_outE <=~(src_aE | src_bE);
            `ALU_XOR:       alu_outE <= src_aE ^ src_bE;
            `ALU_XNOR:      alu_outE <= ~(src_aE ^ src_bE);

            `ALU_ADD:       alu_outE <= src_aE + src_bE;
            `ALU_ADDU:      alu_outE <= src_aE + src_bE;
            `ALU_SUB:       alu_outE <= src_aE - src_bE;
            `ALU_SUBU:      alu_outE <= src_aE - src_bE;

            `ALU_GTZ:       alu_outE <= ~src_aE[31] & (|src_aE);
            `ALU_GEZ:       alu_outE <= ~src_aE[31];
            `ALU_LTZ:       alu_outE <= src_aE[31];
            `ALU_LEZ:       alu_outE <= src_aE[31] | ~(|src_aE);

            `ALU_SLT:       alu_outE <= $signed(src_aE) < $signed(src_bE);
            `ALU_SLTU:      alu_outE <= src_aE < src_bE;

            `ALU_SLL:       alu_outE <= src_bE << src_aE[4:0];
            `ALU_SRL:       alu_outE <= src_bE >> src_aE[4:0];
            `ALU_SRA:       alu_outE <= $signed(src_bE) >>> src_aE[4:0];
            // `ALU_SLL_SA:    alu_outE <= src_bE << sa;
            // `ALU_SRL_SA:    alu_outE <= src_bE >> sa;
            // `ALU_SRA_SA:    alu_outE <= $signed(src_bE) >>> sa;

            `ALU_UNSIGNED_MULT: alu_outE <= {32'b0, src_aE }* {32'b0, src_bE};
            `ALU_SIGNED_MULT:   alu_outE <= $signed(src_aE) * $signed(src_bE);

            `ALU_LUI:       alu_outE <= {src_bE[15:0], 16'b0};

            // `ALU_PC_PLUS8:     alu_outE <= {32'b0, src_aE }+ 64'd4;
            default:    alu_outE <= 32'b0;
        endcase
    end

endmodule