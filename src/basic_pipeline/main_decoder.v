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
	output reg hilo_wenE,
	//MEM
	output reg mem_read_enM, mem_write_enM,
	output reg reg_write_enM,		//写寄存器堆使能
    output reg mem_to_regM,         //result选择 0->alu_out, 1->read_data
	output reg hilo_to_regM,			// 00--alu_outM; 01--hilo_o; 10 11--rdataM;
	output reg riM,
	output reg breakM, syscallM, eretM, 
	output reg cp0_wenM,
	output reg cp0_to_regM
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
	wire hilo_wenD, cp0_wenD;
	reg cp0_wenE;
	wire hilo_to_regD, cp0_to_regD;
	reg hilo_to_regE, cp0_to_regE;

	reg riD, riE;
	wire 	breakD, syscallD;
	reg 	breakE, syscallE;
	wire 	eretD;
	reg 	eretE;
	
	// assign {} = main_control;
	assign {reg_write_enD, reg_dstD, alu_imm_selD} = regfile_ctrl;
	assign {mem_to_regD, mem_read_enD, mem_write_enD} = mem_ctrl;
	
	//一部分能够容易判断的信号
	// assign sign_extD = (op_code[5:2] == 4'b0011) ? 1'b0 : 1'b1;		//andi, xori, lui, ori为无符号拓展，其它为有符号拓展
	assign sign_extD = |(op_code[5:2] ^ 4'b0011);		//andi, xori, lui, ori为无符号拓展，其它为有符号拓展
	assign hilo_wenD = ~(|( op_code[31:26] ^ `EXE_R_TYPE )) & 
						(~(|(op_code[5:2] ^ 4'b0110)) | (~(|(op_code[5:2] ^ 4'b0100)) &  ~(op_code[0] ^ 1'b1)));
														// div divu mult multu mthi mtlo
	assign hilo_to_regD = ~(|(op_code[31:26] ^ `EXE_R_TYPE)) & ~(|(op_code[5:2] ^ 4'b0100)) &  ~(op_code[0] ^ 1'b0);
														// 00--alu_outM; 01--hilo_o; 10 11--rdataM;
	assign cp0_wenD = ~(|(op_code ^ `EXE_ERET_MFTC)) & ~(|(instrD[25:21] ^ `EXE_MTC0));
	assign cp0_to_regD = ~(|(op_code ^ `EXE_ERET_MFTC)) & ~(|(instrD[25:21] ^ `EXE_MFC0));
	
	assign breakD = ~(|(op_code ^ `EXE_R_TYPE)) & ~(|(funct ^ `EXE_BREAK));
	assign syscallD = ~(|(op_code ^ `EXE_R_TYPE)) & ~(|(funct ^ `EXE_SYSCALL));
	assign eretD = ~(|(instrD ^ {`EXE_ERET_MFTC, `EXE_ERET}));


	always @(*) begin
		riD<=1'b0;
		case(op_code)
			`EXE_R_TYPE:
				case(funct)
					// 算数运算指令
					`EXE_ADD,`EXE_ADDU,`EXE_SUB,`EXE_SUBU,`EXE_SLTU,`EXE_SLT ,
					`EXE_AND,`EXE_NOR, `EXE_OR, `EXE_XOR,
					`EXE_SLLV, `EXE_SLL, `EXE_SRAV, `EXE_SRA, `EXE_SRLV, `EXE_SRL,
					`EXE_MFHI, `EXE_MFLO : begin
						regfile_ctrl 	<= 4'b1_00_0;
						mem_ctrl 		<= 3'b0;
					end

					// 逻辑运算指令
					// default
					// `EXE_AND,`EXE_NOR, `EXE_OR, `EXE_XOR: begin
					// 	regfile_ctrl <= 4'b1_00_0;
					// 	mem_ctrl <= 3'b0_0_0;
					// end

					// 一同合并到default里面去？？，赋值都一样；		

					// 移位指令
					// ???default
					// `EXE_SLLV, `EXE_SLL, `EXE_SRAV, `EXE_SRA, `EXE_SRLV, `EXE_SRL: begin
					// 	regfile_ctrl <= 4'b1_00_0;
					// 	mem_ctrl <= 3'b0_0_0;
					// end


					// 数据移动指令
					// default
					// `EXE_MFHI, `EXE_MFLO: begin
					// 	regfile_ctrl <= 4'b1_00_0;
					// 	mem_ctrl <= 3'b0;
					// end
					
					// 跳转执行零
					`EXE_JR, `EXE_MULT, `EXE_MULTU, `EXE_DIV, `EXE_DIVU, `EXE_MTHI, `EXE_MTLO,
					`EXE_SYSCALL, `EXE_BREAK : begin
						regfile_ctrl <= 4'b0;
						mem_ctrl <= 3'b0;
					end
					`EXE_JALR: begin
						regfile_ctrl <= 4'b1_10_0;	//先不考虑jalr rs, rd的情况，即默认跳转31号寄存器；
						mem_ctrl <= 3'b0;
					end
					default: begin
						riD <= 1'b1;
						regfile_ctrl <= 4'b1_00_0;
						mem_ctrl <= 3'b0;
					end
				endcase

// I type

	// 算数运算指令
	// 逻辑运算
			`EXE_ADDI, `EXE_SLTI, `EXE_SLTIU, `EXE_ADDIU, `EXE_ANDI, `EXE_LUI, `EXE_XORI, `EXE_ORI: begin
				regfile_ctrl <= 4'b1_01_1;
				mem_ctrl <= 3'b0;
				// main_control <= 1'b1;
			end

	//  B族指令
			// 可以把B族指令归纳为default中
			`EXE_BEQ, `EXE_BNE, `EXE_BLEZ, `EXE_BGTZ: begin
				regfile_ctrl <= 4'b0_00_0;
				mem_ctrl <= 3'b0;
				// main_control <= 1'b1;
			end

			`EXE_BRANCHS: begin
				case(rt[4:1])
					4'b1000: begin
						regfile_ctrl <= 4'b1_10_0;
						mem_ctrl <= 3'b0;
					end
					4'b0000: begin
						regfile_ctrl <= 4'b0_00_0;
						mem_ctrl <= 3'b0;
					end
					default:begin
						riD <= 1'b1;
						regfile_ctrl <= 4'b0_00_0;
						mem_ctrl <= 3'b0;
					end
				endcase
			end
			
	// 访存指令
			`EXE_LW, `EXE_LB, `EXE_LBU, `EXE_LH, `EXE_LHU: begin
				regfile_ctrl <= 4'b1_01_1;
				mem_ctrl <= 3'b1_1_0;
				// main_control <= 1'b1;
			end
			`EXE_SW, `EXE_SB, `EXE_SH: begin
				regfile_ctrl <= 4'b0_00_1;
				mem_ctrl <= 3'b0_0_1;
				// main_control <= 1'b1;
			end
	
//  J type
			`EXE_J: begin
				regfile_ctrl <= 4'b0;
				mem_ctrl <= 3'b0;
			end

			`EXE_JAL: begin
				regfile_ctrl <= 4'b1_10_0;
				mem_ctrl <= 3'b0;
			end

			`EXE_ERET_MFTC:begin
				case(instrD[25:21])
					`EXE_MTC0: begin
						regfile_ctrl <= 4'b0_00_0;
						mem_ctrl <= 3'b0;
					end
					`EXE_MFC0: begin
						regfile_ctrl <= 4'b1_01_0;
						mem_ctrl <= 3'b0;
					end
					default: begin
						riD <= |(instrD[25:0] ^ `EXE_ERET);
						regfile_ctrl <= 4'b0_00_0;
						mem_ctrl <= 3'b0;
					end
				endcase
			end

			default: begin
				riD <= 1;
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
			hilo_wenE		<= 0;
			hilo_to_regE	<= 0;
			riE				<= 0;
			breakE			<= 0;
			syscallE		<= 0;
			eretE			<= 0;
			cp0_wenE		<= 0;
			cp0_to_regE		<= 0;
		end
		else if(~stallE)begin
			reg_dstE		<= reg_dstD 		; 
			alu_imm_selE	<= alu_imm_selD 	;
			mem_read_enE	<= mem_read_enD		;
			mem_write_enE	<= mem_write_enD	;
			reg_write_enE	<= reg_write_enD 	;
			mem_to_regE		<= mem_to_regD 		;
			hilo_wenE		<= hilo_wenD		;
			hilo_to_regE	<= hilo_to_regD		;
			riE				<= riD				;
			breakE			<= breakD			;
			syscallE		<= syscallD			;
			eretE			<= eretD			;
			cp0_wenE		<= cp0_wenD			;
			cp0_to_regE		<= cp0_to_regD		;
		end
    end

// EX-MEM flow
    always@(posedge clk) begin
		if(rst) begin
			mem_read_enM	<= 0;
			mem_write_enM	<= 0;
			reg_write_enM	<= 0;
			mem_to_regM		<= 0;
			hilo_to_regM	<= 0;
			riM				<= 0;
			breakM			<= 0;
			syscallM		<= 0;
			eretM			<= 0;
			cp0_wenM		<= 0;
			cp0_to_regM		<= 0;
		end
		else if(~stallM) begin
			mem_read_enM	<= mem_read_enE		;
			mem_write_enM	<= mem_write_enE	;
			reg_write_enM	<= reg_write_enE 	;
			mem_to_regM		<= mem_to_regE 		;
			hilo_to_regM	<= hilo_to_regE		;
			riM				<= riE				;
			breakM			<= breakE			;
			syscallM		<= syscallE			;
			eretM			<= eretE			;
			cp0_wenM		<= cp0_wenE			;
			cp0_to_regM		<= cp0_to_regE		;
		end
    end

// MEM-WB flop
   
endmodule