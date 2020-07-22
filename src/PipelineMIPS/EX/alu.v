`include "aludefines.vh"

module alu (
    input clk, rst,
    input wire [31:0] src_aE, src_bE,
    input wire [4:0] alu_controlE,
    input wire [4:0] sa,

    output wire div_stall,
    output wire [63:0] alu_outE,
    output wire overflowE
);
    wire [63:0] alu_out_div, alu_out_mul;
    reg [31:0] alu_out_not_mul_div;

    assign alu_outE = ({64{div_vaild}} & alu_out_div)
                    ||({64{mul_valid}} & alu_out_mul)
                    ||({64{~mul_valid & ~div_vaild}} & {32'b0, {alu_out_not_mul_div}});
    assign overflowE = (alu_out_not_mul_div[32] & (~src_aE[31] & ~src_bE[31])) 
                    || (~alu_out_not_mul_div[32] & (src_aE[31] & src_bE[31])); 

    // simple
    always @(*) begin
        case(alu_controlE)
            `ALU_AND:       alu_out_not_mul_div <= src_aE & src_bE;
            `ALU_OR:        alu_out_not_mul_div <= src_aE | src_bE;
            `ALU_NOR:       alu_out_not_mul_div <=~(src_aE | src_bE);
            `ALU_XOR:       alu_out_not_mul_div <= src_aE ^ src_bE;
            `ALU_XNOR:      alu_out_not_mul_div <= (src_aE ^ src_bE);

            `ALU_ADD:       alu_out_not_mul_div <= src_aE + src_bE;
            `ALU_ADDU:      alu_out_not_mul_div <= src_aE + src_bE;
            `ALU_SUB:       alu_out_not_mul_div <= src_aE - src_bE;
            `ALU_SUBU:      alu_out_not_mul_div <= src_aE - src_bE;

            `ALU_GTZ:       alu_out_not_mul_div <= ~src_aE[31] & (|src_aE);
            `ALU_GEZ:       alu_out_not_mul_div <= ~src_aE[31];
            `ALU_LTZ:       alu_out_not_mul_div <= src_aE[31];
            `ALU_LEZ:       alu_out_not_mul_div <= src_aE[31] | ~(|src_aE);

            `ALU_SLT:       alu_out_not_mul_div <= $signed(src_aE) < $signed(src_bE);
            `ALU_SLTU:      alu_out_not_mul_div <= src_aE < src_bE;

            `ALU_SLL:       alu_out_not_mul_div <= src_bE << src_aE[4:0];
            `ALU_SRL:       alu_out_not_mul_div <= src_bE >> src_aE[4:0];
            `ALU_SRA:       alu_out_not_mul_div <= $signed(src_bE) >>> src_aE[4:0];

            `ALU_SLL_SA:    alu_out_not_mul_div <= src_bE << sa;
            `ALU_SRL_SA:    alu_out_not_mul_div <= src_bE >> sa;
            `ALU_SRA_SA:    alu_out_not_mul_div <= $signed(src_bE) >>> sa;

            // `ALU_UNSIGNED_MULT: alu_out_not_mul_div <= {32'b0, src_aE }* {32'b0, src_bE};
            // `ALU_SIGNED_MULT:   alu_out_not_mul_div <= $signed(src_aE) * $signed(src_bE);

            `ALU_LUI:       alu_out_not_mul_div <= {src_bE[15:0], 16'b0};

            // `ALU_PC_PLUS8:     alu_out_not_mul_div <= {32'b0, src_aE }+ 64'd4;
            default:    alu_out_not_mul_div <= 32'b0;
        endcase
    end

    //divide
	wire div_sign;
	wire div_vaild;
	wire ready;

	assign div_sign = (alu_controlE == `ALU_SIGNED_DIV);
	assign div_vaild = (alu_controlE == `ALU_SIGNED_DIV || alu_controlE == `ALU_UNSIGNED_DIV);

	div_radix2 DIV(
		.clk(~clk),
		.rst(rst),
		.a(src_aE),  //divident
		.b(src_bE),  //divisor
		.valid(div_vaild),
		.sign(div_sign),   //1 signed

		// .ready(ready),
		.div_stall(div_stall),
		.result(alu_out_div)
	);

    //multiply
	wire mul_sign;
    wire mul_valid;
	assign mul_sign = (alu_controlE == `ALU_SIGNED_MULT);
    assign mul_valid = (alu_controlE == `ALU_SIGNED_MULT) | (alu_controlE == `ALU_UNSIGNED_MULT);
	mul_booth2 MUL(
		.a(src_aE),
		.b(src_bE),
		.sign(mul_sign),   //1:signed

		.result(alu_out_mul)
	);


endmodule