`include "defines.vh"

module main_decoder(
    input clk, rst,
    input wire [31:0] instrD,

	input wire stallE, stallM, stallW,
    //ID
    output wire sign_extD,          //立即数是否为符号扩展
    //EX
    output reg [1:0] reg_dstE,     	//写寄存器选择  00-> rd, 01-> rt, 10-> 写$ra
    output reg alu_imm_selE,        //alu srcb选择 0->rd2E, 1->immE
    output reg reg_write_enE,
	//MEM
	output reg mem_read_enM, mem_write_enM,
	output reg reg_write_enM,		//写寄存器堆使能
    output reg mem_to_regM         	//result选择 0->alu_out, 1->read_data
    //WB
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
    wire alu_imm_selD, reg_write_enD, mem_to_regD, mem_read_enD, mem_write_enD;
    reg mem_to_regE, mem_read_enE, mem_write_enE;

	reg [0:0] main_control;
	reg [3:0] regfile_ctrl;
	reg [2:0] mem_ctrl;
	
	// assign {} = main_control;
	assign {reg_write_enD, reg_dstD, alu_imm_selD} = regfile_ctrl;
	assign {mem_to_regD, mem_read_enD, mem_write_enD} = mem_ctrl;
	
	//一部分能够容易判断的信号
	assign sign_extD = (op_code[5:2] == 4'b0011) ? 1'b0 : 1'b1;		//andi, xori, lui, ori为无符号拓展，其它为有符号拓展
	
	always @(*) begin
		case(op_code)
			`EXE_R_TYPE:
				case(funct)
					`EXE_JR: begin
						regfile_ctrl <= 4'b0;
						mem_ctrl <= 3'b0;
					end
					`EXE_JALR: begin
						regfile_ctrl <= 4'b1_10_0;	//先不考虑jalr rs, rd的情况
						mem_ctrl <= 3'b0;
					end
					default: begin
						regfile_ctrl <= 4'b1_00_0;
						mem_ctrl <= 3'b0;
					end
				endcase
			`EXE_ADDI: begin
				regfile_ctrl <= 4'b1_01_1;
				mem_ctrl <= 3'b0;
				// main_control <= 1'b1;
			end
			`EXE_BEQ: begin
				regfile_ctrl <= 4'b0_00_1;
				mem_ctrl <= 3'b0;
				// main_control <= 1'b1;
			end
			`EXE_LW: begin
				regfile_ctrl <= 4'b1_01_1;
				mem_ctrl <= 3'b1_1_0;
				// main_control <= 1'b1;
			end
			`EXE_SW: begin
				regfile_ctrl <= 4'b0_00_1;
				mem_ctrl <= 3'b0_0_1;
				// main_control <= 1'b1;
			end
			//`EXE_J: default
			`EXE_JAL: begin
				regfile_ctrl <= 4'b1_10_0;
				mem_ctrl <= 3'b0;
			end
			default: begin
				regfile_ctrl <= 4'b0;
				mem_ctrl <= 3'b0;
			end
		endcase
	end

// ID-EX flow
    always@(posedge clk) begin
		if(rst) begin
			reg_dstE		<= 0; 
			alu_imm_selE	<= 0;
			mem_read_enE	<= 0;
			mem_write_enE	<= 0;
			reg_write_enE	<= 0;
			mem_to_regE		<= 0;
		end
		else if(~stallE)begin
			reg_dstE		<= reg_dstD 		; 
			alu_imm_selE	<= alu_imm_selD 	;
			mem_read_enE	<= mem_read_enD		;
			mem_write_enE	<= mem_write_enD	;
			reg_write_enE	<= reg_write_enD 	;
			mem_to_regE		<= mem_to_regD 		;
		end
    end

// EX-MEM flow
    always@(posedge clk) begin
		if(rst) begin
			mem_read_enM	<= 0;
			mem_write_enM	<= 0;
			reg_write_enM	<= 0;
			mem_to_regM		<= 0;
		end
		else if(~stallM) begin
			mem_read_enM	<= mem_read_enE		;
			mem_write_enM	<= mem_write_enE	;
			reg_write_enM	<= reg_write_enE 	;
			mem_to_regM		<= mem_to_regE 		;
		end
    end

// MEM-WB flop
   
endmodule