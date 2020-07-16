`include "defines.vh"

module main_decoder(
    input clk,
    input wire [31:0] instrD,

    //ID
    output wire sign_extD,          //立即数是否为符号扩展
    //EX
    output reg [1:0] reg_dstE,     //写寄存器选择  00-> rd, 01-> rt, 10-> 写$ra
    output reg alu_srcE,           //alu srcb选择 0->rd2E, 1->immE
    //MEM
	output reg mem_read_enM, mem_write_enM,
    //WB
    output reg reg_write_enW,      //写寄存器堆使能
    output reg mem_to_regW         //result选择 0->alu_out, 1->read_data
);

// declare
    wire [5:0] op_code;
	wire [4:0] rs,rt;
	wire [5:0] funct;

	assign op_code = instrD[31:26];
	assign rs = instrD[25:21];
	assign rt = instrD[20:16];
	assign funct = instrD[5:0];

    wire [1:0] reg_dstD;
    wire alu_srcD, reg_write_enD, mem_to_regD, mem_read_enD, mem_write_enD;
    reg reg_write_enE, mem_to_regE, mem_read_enE, mem_write_enE;
    reg reg_write_enM, mem_to_regM;

	reg [0:0] main_control;
	reg [2:0] regfile_ctrl;
	reg [2:0] mem_ctrl;
	
	// assign {} = main_control;
	assign {reg_write_enD, reg_dstD, alu_srcD} = regfile_ctrl;
	assign {mem_to_regD, mem_read_enD, mem_write_enD} = mem_ctrl;
	
	//一部分能够容易判断的信号
	assign sign_extD = (op_code[5:2] == 4'b0011) ? 1'b0 : 1'b1;		//andi, xori, lui, ori为无符号拓展，其它为有符号拓展
	
	always @(*) begin
		case(op_code)
			`EXE_R_TYPE:
				case(funct)
					`EXE_ADD: begin
						regfile_ctrl <= 3'b1_00_0;
						mem_ctrl <= 3'b0_0_0;
						// main_control <= 1'b0;
					end
					default: begin
						regfile_ctrl <= 3'b0;
						mem_ctrl <= 3'b0;
					end
				endcase
			`EXE_ADDI: begin
				regfile_ctrl <= 3'b1_01_1;
				mem_ctrl <= 3'b0_0_0;
				// main_control <= 1'b1;
			end
			`EXE_BEQ: begin
				regfile_ctrl <= 3'b0_00_1;
				mem_ctrl <= 3'b0_0_0;
				// main_control <= 1'b1;
			end
			`EXE_LW: begin
				regfile_ctrl <= 3'b1_01_1;
				mem_ctrl <= 3'b1_1_0;
				// main_control <= 1'b1;
			end
			`EXE_SW: begin
				regfile_ctrl <= 3'b0_00_1;
				mem_ctrl <= 3'b0_0_1;
				// main_control <= 1'b1;
			end
			default: begin
				regfile_ctrl <= 3'b0;
				mem_ctrl <= 3'b0;
			end
		endcase
	end

// ID-EX flow 
    always@(posedge clk) begin
		reg_dstE		<= reg_dstD 		; 
        alu_srcE		<= alu_srcD 		;
		mem_read_enE	<= mem_read_enD		;
		mem_write_enE	<= mem_write_enD	;
        reg_write_enE	<= reg_write_enD 	;
        mem_to_regE		<= mem_to_regD 		;
    end

// EX-MEM flow
    always@(posedge clk) begin
		mem_read_enM	<= mem_read_enE		;
		mem_write_enM	<= mem_write_enE	;
        reg_write_enM	<= reg_write_enE 	;
        mem_to_regM		<= mem_to_regE 		;
    end

// MEM-WB flop
    always@(posedge clk) begin
        reg_write_enW	<= reg_write_enM 	;
        mem_to_regW		<= mem_to_regM 		;
    end

endmodule