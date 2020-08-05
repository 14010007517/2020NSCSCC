`include "aludefines.vh"

module aluyz (
    input wire clk, rst,
    input wire [31:0] src_aE, src_bE,
    input wire [4:0] alu_controlE,
    input wire [4:0] sa,
    input wire [63:0] hilo,

    input wire stallD,
    input wire is_divD,
    input wire is_multD,

    input wire flushE,
    output reg div_stallE,
    output wire mult_stallE,
    output wire [63:0] alu_outE,
    output wire overflowE
);

wire alu_add;
wire alu_sub;
wire alu_sub_true;
wire alu_slt;
wire alu_sltu;

wire alu_and;
wire alu_lui;
wire alu_nor;
wire alu_or;
wire alu_xor;
wire alu_sll;
wire alu_sra;
wire alu_srl;

wire [31:0] add_sub_result;
wire [31:0] slt_result;
wire [31:0] sltu_result;
wire [31:0] and_result;
wire [31:0] lui_result;
wire [31:0] nor_result;
wire [31:0] or_result;
wire [31:0] xor_result;
wire [31:0] sll_result;
wire [31:0] sra_result;
wire [31:0] srl_result;
wire [63:0] sra64_result;
wire [63:0] srl64_result;

assign overflowE = ((alu_controlE == 6'b100000 || alu_controlE == 6'b001000) && src_aE[31] == src_bE[31] && src_aE[31] != add_sub_result[31] ||
                   alu_controlE == 6'b100010 && src_aE[31] != src_bE[31] && src_aE[31] != add_sub_result[31]) ? 1'b1 : 1'b0;
assign alu_add  = (alu_controlE == 6'b100000 || alu_controlE == 6'b001000 ||
                   alu_controlE == 6'b100001 || alu_controlE == 6'b001001);
assign alu_sub_true  = (alu_controlE == 6'b100010 || alu_controlE == 6'b100011);
assign alu_sub  = (alu_controlE == 6'b100010 || alu_controlE == 6'b100011 || alu_controlE == 6'b101010 || alu_controlE == 6'b001010 || alu_controlE == 6'b101011 || alu_controlE == 6'b001011);
assign alu_slt  = (alu_controlE == 6'b101010 || alu_controlE == 6'b001010);
assign alu_sltu = (alu_controlE == 6'b101011 || alu_controlE == 6'b001011);



assign alu_and  =(alu_controlE == 6'b100100 || alu_controlE == 6'b001100);
assign alu_lui  = alu_controlE == 6'b001111;
assign alu_nor  = alu_controlE == 6'b100111;
assign alu_or   =(alu_controlE == 6'b100101 || alu_controlE == 6'b001101);
assign alu_xor  =(alu_controlE == 6'b100110 || alu_controlE == 6'b001110);
assign alu_sll  =(alu_controlE == 6'b000100 || alu_controlE == 6'b000000);
assign alu_sra  =(alu_controlE == 6'b000111 || alu_controlE == 6'b000011);
assign alu_srl  =(alu_controlE == 6'b000110 || alu_controlE == 6'b000010);




assign and_result = src_aE & src_bE;
assign or_result  = src_aE | src_bE;
assign nor_result = ~or_result;
assign xor_result = src_aE ^ src_bE;
assign lui_result = {src_bE[15:0],16'd0};


wire [31:0] adder_a;
wire [31:0] adder_b;
wire        adder_cin;
wire [31:0] adder_result;
wire        adder_cout;

assign adder_a = src_aE;
assign adder_b = src_bE ^ {32{alu_sub}};
assign adder_cin = alu_sub;
assign {adder_cout,adder_result} = adder_a + adder_b + adder_cin;
assign add_sub_result = adder_result;

assign slt_result[31:1] = 31'd0;
assign slt_result[0] = (src_aE[31] & ~src_bE[31]) |
                       (~(src_aE[31]^src_bE[31]) & adder_result[31]);
//assign slt_result[0] = src_aE < src_bE ;

assign sltu_result[31:1] = 31'd0;
assign sltu_result[0] = ~adder_cout;
//assign sltu_result = {1'b0,src_aE} < {1'b0,src_bE};

assign sll_result  = src_bE << src_aE[4:0];
assign sra64_result = {{32{alu_sra & src_bE[31]}},src_bE[31:0]} >> src_aE[4:0];
assign sra_result   = sra64_result[31:0];
assign srl64_result = {{32{1'b0}},src_bE[31:0]} >> src_aE[4:0];
assign srl_result   = srl64_result[31:0];

wire [31:0] alu_out_not_mul_div; //拓展成33位，便于判断溢出
assign alu_out_not_mul_div =  ({32{alu_add|alu_sub_true}} & add_sub_result) |
                              ({32{alu_slt        }} & slt_result) |
                              ({32{alu_sltu       }} & sltu_result) |
                              ({32{alu_and        }} & and_result) |
                              ({32{alu_nor        }} & nor_result) |
                              ({32{alu_or         }} & or_result) |
                              ({32{alu_xor        }} & xor_result) |
                              ({32{alu_sll        }} & sll_result) |
                              ({32{alu_srl        }} & srl_result) |
                              ({32{alu_sra        }} & sra_result) |
                              ({32{alu_lui        }} & lui_result);


    wire [63:0] alu_out_div, alu_out_mult;
    wire mult_sign;
    wire mult_valid;
    wire div_sign;
    wire div_vaild;
    wire ready;
    // reg carry_bit;

    wire [63:0] alu_out_signed_mult, alu_out_unsigned_mult;
    wire signed_mult_ce, unsigned_mult_ce;

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
    assign alu_out_mult = mult_sign ? alu_out_signed_mult : alu_out_unsigned_mult;

	  assign mult_sign = (alu_controlE == `ALU_SIGNED_MULT);
    assign mult_valid = (alu_controlE == `ALU_SIGNED_MULT) | (alu_controlE == `ALU_UNSIGNED_MULT);

    wire mult_ready;
    reg [3:0] cnt;
    assign mult_ready = !(cnt ^ 4'b1001);
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

    assign alu_outE = ({64{div_vaild}} & alu_out_div)
                    | ({64{mult_valid}} & alu_out_mult)
                    | ({64{~mult_valid & ~div_vaild}} & {32'b0, alu_out_not_mul_div})
                    | ({64{(alu_controlE == `ALU_MTHI)}} & {src_aE, hilo[31:0]})
                    | ({64{(alu_controlE == `ALU_MTLO)}} & {hilo[31:0], src_aE});

    // assign overflowE = (alu_controlE==`ALU_ADD || alu_controlE==`ALU_SUB) & (carry_bit ^ alu_out_not_mul_div[31]);
endmodule 