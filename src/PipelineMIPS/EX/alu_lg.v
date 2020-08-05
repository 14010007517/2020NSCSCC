`include "aludefines.vh"

module alulg (
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
    wire [31:0] alu_out_not_mul_div; //拓展成33位，便于判断溢出

    wire [63:0] alu_out_signed_mult, alu_out_unsigned_mult;
    wire signed_mult_ce, unsigned_mult_ce;

    assign alu_outE = ({64{div_vaild}} & alu_out_div)
                    | ({64{mult_valid}} & alu_out_mult)
                    | ({64{~mult_valid & ~div_vaild}} & {32'b0, alu_out_not_mul_div})
                    | ({64{ !(alu_controlE ^ `ALU_MTHI) }} & {src_aE, hilo[31:0]})
                    | ({64{ !(alu_controlE ^ `ALU_MTLO) }} & {hilo[31:0], src_aE});

    assign overflowE = ( !(alu_controlE ^ `ALU_ADD) || !(alu_controlE ^ `ALU_SUB)) & (adder_cout ^ alu_out_not_mul_div[31]);

    wire alu_and        ;      
    wire alu_or         ;      
    wire alu_nor        ;      
    wire alu_xor        ;      
    wire alu_add        ;      
    wire alu_addu       ;      
    wire alu_sub        ;      
    wire alu_subu       ;     
    wire alu_slt        ;      
    wire alu_sltu       ;      
    wire alu_sll        ;      
    wire alu_srl        ;      
    wire alu_sra        ;      
    wire alu_sll_sa     ;      
    wire alu_srl_sa     ;      
    wire alu_sra_sa     ;      
    wire alu_lui        ;      
    wire alu_donothing  ;     

    wire [31:0] and_result       ;
    wire [31:0] or_result        ;
    wire [31:0] nor_result       ;
    wire [31:0] xor_result       ;
    wire [31:0] add_sub_result       ;
    wire [31:0] addu_result      ;
    wire [31:0] sub_result       ;
    wire [31:0] subu_result      ;
    wire [31:0] slt_result       ;
    wire [31:0] sltu_result      ;
    wire [31:0] sll_sult         ;
    wire [31:0] srl_result       ;
    wire [31:0] sra_result       ;
    wire [31:0] sll_sa_result    ;
    wire [31:0] srl_sa_result    ;
    wire [31:0] sra_sa_result    ;
    wire [31:0] lui_result       ;
    wire [31:0] donothing_result ;

    assign alu_and       = !(alu_controlE ^ `ALU_AND      );
    assign alu_or        = !(alu_controlE ^ `ALU_OR       );
    assign alu_nor       = !(alu_controlE ^ `ALU_NOR      );
    assign alu_xor       = !(alu_controlE ^ `ALU_XOR      );
    assign alu_add       = !(alu_controlE ^ `ALU_ADD      );
    assign alu_addu      = !(alu_controlE ^ `ALU_ADDU     );
    assign alu_sub       = !(alu_controlE ^ `ALU_SUB      );
    assign alu_subu      = !(alu_controlE ^ `ALU_SUBU     );
    assign alu_slt       = !(alu_controlE ^ `ALU_SLT      );
    assign alu_sltu      = !(alu_controlE ^ `ALU_SLTU     );
    assign alu_sll       = !(alu_controlE ^ `ALU_SLL      );
    assign alu_srl       = !(alu_controlE ^ `ALU_SRL      );
    assign alu_sra       = !(alu_controlE ^ `ALU_SRA      );
    assign alu_sll_sa    = !(alu_controlE ^ `ALU_SLL_SA   );
    assign alu_srl_sa    = !(alu_controlE ^ `ALU_SRL_SA   );
    assign alu_sra_sa    = !(alu_controlE ^ `ALU_SRA_SA   );
    assign alu_lui       = !(alu_controlE ^ `ALU_LUI      );
    assign alu_donothing = !(alu_controlE ^ `ALU_DONOTHING);

    assign and_result   = src_aE & sra_bE;
    assign or_result    = sra_aE | src_bE;
    assign nor_result   = ~or_result;
    assign xor_result   = src_aE ^ src_bE;
    assign lui_result   = {src_bE[15:0],  16'd0};


    wire [31:0] adder_a;
    wire [31:0] adder_b;
    wire        adder_cin;
    wire [31:0] adder_result;
    wire        adder_cout;
    wire [63:0] sra64_sa_result, sra64_result, srl64_result, srl64_sa_result;


    assign adder_a = src_aE;
    assign adder_b = src_bE ^ {32{alu_sub | alu_subu | alu_slt | alu_sltu}};
    assign adder_cin = alu_sub | alu_subu | alu_slt | alu_sltu;
    assign {adder_cout,adder_result} = adder_a + adder_b + adder_cin;
    assign add_sub_result = adder_result;

    assign slt_result[31:1] = 31'd0;
    assign slt_result[0] = (src_aE[31] & ~src_bE[31]) |
                        (~(src_aE[31]^src_bE[31]) & adder_result[31]);
    //assign slt_result[0] = src_aE < src_bE ;

    assign sltu_result[31:1] = 31'd0;
    assign sltu_result[0] = adder_cout;
    //assign sltu_result = {1'b0,src_aE} < {1'b0,src_bE};

    assign sll_result  = src_bE << src_aE[4:0];                                     // sll
    assign sll_sa_result = src_bE << sa;                                            // sll_sa
    assign sra64_result = {{32{alu_sra & src_bE[31]}},src_bE[31:0]} >> src_aE[4:0]; // sra
    assign sra_result   = sra64_result[31:0];                                      
    assign sra64_sa_result = {{32{alu_sra & src_bE[31]}},src_bE[31:0]} >> sa;       // sra_sa
    assign sra_sa_result = sra64_sa_result[31:0];
    assign srl64_result = {{32{1'b0}},src_bE[31:0]} >> src_aE[4:0];                 // srl
    assign srl_result   = srl64_result[31:0];
    assign srl64_sa_result = {{32{1'b0}},src_bE[31:0]} >> sa;
    assign srl_sa_result = srl64_sa_result[31:0];                                   // srl_sa

    assign donothing_result = src_aE;

    assign alu_out_not_mul_div = 
                    ({32{alu_and        }} & and_result)    |
                    ({32{alu_nor        }} & nor_result)    |
                    ({32{alu_or         }} & or_result)     |
                    ({32{alu_xor        }} & xor_result)    |
                    ({32{alu_add | alu_addu | alu_sub | alu_subu}} & add_sub_result) |
                    ({32{alu_slt        }} & slt_result)    |
                    ({32{alu_sltu       }} & sltu_result)   |
                    ({32{alu_sll        }} & sll_result)    |
                    ({32{alu_srl        }} & srl_result)    |
                    ({32{alu_sra        }} & sra_result)    |
                    ({32{alu_sll_sa     }} & sra_result)    |
                    ({32{alu_srl_sa     }} & sra_result)    |
                    ({32{alu_sra_sa     }} & sra_result)    |
                    ({32{alu_lui        }} & lui_result)    |
                    ({32{alu_donothing  }} & donothing_result);

    //divide
	assign div_sign = !(alu_controlE ^ `ALU_SIGNED_DIV);
	assign div_vaild = ( !(alu_controlE ^ `ALU_SIGNED_DIV) || !(alu_controlE ^ `ALU_UNSIGNED_DIV) );

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
    assign alu_out_mult = mult_sign ? alu_out_signed_mult : alu_out_unsigned_mult;

	assign mult_sign = (alu_controlE == `ALU_SIGNED_MULT);
    assign mult_valid = (alu_controlE == `ALU_SIGNED_MULT) | (alu_controlE == `ALU_UNSIGNED_MULT);

    wire mult_ready;
    reg [3:0] cnt;
    assign mult_ready = !(cnt ^ 4'b1000);
    always@(posedge clk) begin
        cnt <= rst | (is_multD & ~stallD & ~flushE) | flushE ? 0 :
                mult_ready ? cnt :
                cnt + 1;
    end

    assign unsigned_mult_ce = mult_valid & ~mult_ready;
    assign signed_mult_ce =  mult_valid & ~mult_ready;
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