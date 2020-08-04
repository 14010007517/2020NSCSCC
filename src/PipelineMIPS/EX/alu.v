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
    input wire is_multD,

    output reg div_stallE,
    output wire mult_stallE,
    output wire [63:0] alu_outE,
    output wire overflowE
);
    wire [63:0] alu_out_div, alu_out_mult;
    wire mult_sign;
    wire mult_valid;
    wire div_sign;
	wire div_vaild;
	wire ready;
    reg [31:0] alu_out_not_mul_div; //拓展成33位，便于判断溢出
    reg carry_bit;

    wire [63:0] alu_out_signed_mult, alu_out_unsigned_mult;
    wire signed_mult_ce, unsigned_mult_ce;
    reg [2:0] cnt;

    assign alu_outE = ({64{div_vaild}} & alu_out_div)
                    | ({64{mult_valid}} & alu_out_mult)
                    | ({64{~mult_valid & ~div_vaild}} & {32'b0, alu_out_not_mul_div})
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
	assign mult_sign = (alu_controlE == `ALU_SIGNED_MULT);
    assign mult_valid = (alu_controlE == `ALU_SIGNED_MULT) | (alu_controlE == `ALU_UNSIGNED_MULT)  | (alu_controlE == `ALU_MUL);

    assign alu_out_mult = mult_sign ? alu_out_signed_mult : alu_out_unsigned_mult;
	// 	.a(src_aE),
	// 	.b(src_bE),
	// 	.sign(mult_sign),   //1:signed

	// 	.result(alu_out_mult)
	// );

    

    always@(posedge clk) begin
        cnt <= rst | (is_multD & ~stallD & ~flushE)  ? 0 :
                (cnt[2] & cnt[1] & cnt[0]) ? cnt :
                cnt + 1;
    end

    assign unsigned_mult_ce = mult_valid & ~(cnt[2] & cnt[1] & cnt[0]) ;
    assign signed_mult_ce =  mult_valid & ~(cnt[2] & cnt[1] & cnt[0]) ;
    assign mult_stallE = mult_valid & (unsigned_mult_ce | signed_mult_ce);

    signed_mult signed_mult0 (
        .CLK(clk),  // input wire CLK
        .A(src_aE),      // input wire [31 : 0] A
        .B(src_bE),      // input wire [31 : 0] B
        .CE(signed_mult_ce),    // input wire CE
        .P(alu_out_signed_mult)      // output wire [63 : 0] P
    );

    unsigned_mult unsigned_mult0 (
        .CLK(clk),  // input wire CLK
        .A(src_aE),      // input wire [31 : 0] A
        .B(src_bE),      // input wire [31 : 0] B
        .CE(unsigned_mult_ce),    // input wire CE
        .P(alu_out_unsigned_mult)      // output wire [63 : 0] P
    );

endmodule