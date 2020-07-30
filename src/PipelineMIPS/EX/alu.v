`include "aludefines.vh"

module alu (
    input wire clk, rst,
    input wire flushE,
    input wire [31:0] src_aE, src_bE,
    input wire [4:0] alu_controlE,
    input wire [4:0] sa,
    input wire [63:0] hilo,
    input wire stallD,
    input wire is_divD,

    output reg div_stallE,
    output wire [63:0] alu_outE,
    output wire overflowE
);
    wire [63:0] alu_out_div, alu_out_mul;
    wire mul_sign;
    wire mul_valid;
    wire div_sign;
	wire div_vaild;
	wire ready;
    reg [31:0] alu_out_not_mul_div; //拓展成33位，便于判断溢出
    reg carry_bit;

    assign alu_outE = ({64{div_vaild}} & alu_out_div)
                    | ({64{mul_valid}} & alu_out_mul)
                    | ({64{~mul_valid & ~div_vaild}} & {32'b0, alu_out_not_mul_div})
                    | ({64{(alu_controlE == `ALU_MTHI)}} & {src_aE, hilo[31:0]})
                    | ({64{(alu_controlE == `ALU_MTLO)}} & {hilo[31:0], src_aE});

    assign overflowE = (alu_controlE==`ALU_ADD || alu_controlE==`ALU_SUB) & (carry_bit ^ alu_out_not_mul_div[31]);

    // simple
    always @(*) begin
        carry_bit = 0;
        case(alu_controlE)
            `ALU_AND:       alu_out_not_mul_div = src_aE & src_bE;
            `ALU_OR:        alu_out_not_mul_div = src_aE | src_bE;
            `ALU_NOR:       alu_out_not_mul_div =~(src_aE | src_bE);
            `ALU_XOR:       alu_out_not_mul_div = src_aE ^ src_bE;

            `ALU_ADD:       {carry_bit, alu_out_not_mul_div} = {src_aE[31], src_aE} + {src_bE[31], src_bE};
            `ALU_ADDU:      alu_out_not_mul_div = src_aE + src_bE;
            `ALU_SUB:       {carry_bit, alu_out_not_mul_div} = {src_aE[31], src_aE} - {src_bE[31], src_bE};
            `ALU_SUBU:      alu_out_not_mul_div = src_aE - src_bE;

            `ALU_SLT:       alu_out_not_mul_div = $signed(src_aE) < $signed(src_bE);
            `ALU_SLTU:      alu_out_not_mul_div = src_aE < src_bE;

            `ALU_SLL:       alu_out_not_mul_div = src_bE << src_aE[4:0];
            `ALU_SRL:       alu_out_not_mul_div = src_bE >> src_aE[4:0];
            `ALU_SRA:       alu_out_not_mul_div = $signed(src_bE) >>> src_aE[4:0];

            `ALU_SLL_SA:    alu_out_not_mul_div = src_bE << sa;
            `ALU_SRL_SA:    alu_out_not_mul_div = src_bE >> sa;
            `ALU_SRA_SA:    alu_out_not_mul_div = $signed(src_bE) >>> sa;

            `ALU_LUI:       alu_out_not_mul_div = {src_bE[15:0], 16'b0};
            `ALU_DONOTHING: alu_out_not_mul_div = src_aE;

            default:    alu_out_not_mul_div = 32'b0;
        endcase
    end

    //divide
	assign div_sign = (alu_controlE == `ALU_SIGNED_DIV);
	assign div_vaild = (alu_controlE == `ALU_SIGNED_DIV || alu_controlE == `ALU_UNSIGNED_DIV);

    reg vaild;
    wire ready;
    always @(posedge clk) begin
        div_stallE <= rst  ? 1'b0 :
                      is_divD & ~stallD & ~flushE ? 1'b1 :
                      ready | flushE ? 1'b0 : div_stallE;
        vaild <= rst ? 1'b0 :
                     is_divD & ~stallD & ~flushE ? 1'b1 : 1'b0;
    end

	div_radix2 DIV(
		.clk(clk),
		.rst(rst),
        .flush(flushE),
		.a(src_aE),  //divident
		.b(src_bE),  //divisor
		.valid(vaild ),
		.sign(div_sign),   //1 signed

		.ready(ready),
		.result(alu_out_div)
	);

    //multiply
	assign mul_sign = (alu_controlE == `ALU_SIGNED_MULT);
    assign mul_valid = (alu_controlE == `ALU_SIGNED_MULT) | (alu_controlE == `ALU_UNSIGNED_MULT);
	mul_booth2 MUL(
		.a(src_aE),
		.b(src_bE),
		.sign(mul_sign),   //1:signed

		.result(alu_out_mul)
	);


endmodule