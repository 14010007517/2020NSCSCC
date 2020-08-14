`include "defines.vh"

module main_decoder(
    input clk, rst,
    input wire [31:0] instrD,

    //ID
    output wire sign_extD,          //立即数是否为符号扩展
	output wire is_divD, is_multD,			//是否为除法指令
	output wire [7:0] l_s_typeD,
	output wire [1:0] mfhi_loD,
    //EX
    output wire [1:0] reg_dstD,     	//写寄存器选择  00-> rd, 01-> rt, 10-> 写$ra
    output wire alu_imm_selD,        //alu srcb选择 0->rd2E, 1->immE
	output wire hilo_wenD,
	//MEM
	output wire mem_read_enD, mem_write_enD,
	output wire reg_write_enD,		//写寄存器堆使能
    output wire mem_to_regD,         //result选择 0->alu_out, 1->read_data
	output wire hilo_to_regD,			// 00--alu_outM; 01--hilo_o; 10 11--rdataM;
	output reg  riD,
	output wire breakD, syscallD, eretD, 
	output wire cp0_wenD,
	output wire cp0_to_regD,
	output wire [3:0] tlb_typeD
    //WB
);
// declare
    wire [5:0] op_code;
	wire [4:0] rs,rt;
	wire [5:0] funct;
	wire TLBWR, TLBWI, TLBP, TLBR;
	wire mtc0;
	wire mfhi;
	wire mflo;
	wire mul;
	wire madd, maddu, msub, msubu;
	wire div, divu, mult, multu;
	wire mthi, mtlo;

	assign op_code = instrD[31:26];
	assign rs = instrD[25:21];
	assign rt = instrD[20:16];
	assign funct = instrD[5:0];

	reg [3:0] regfile_ctrl;
	reg [2:0] mem_ctrl;
	
	assign {reg_write_enD, reg_dstD, alu_imm_selD} = regfile_ctrl;
	assign {mem_to_regD, mem_read_enD, mem_write_enD} = mem_ctrl;
	
	//一部分能够容易判断的信号
	assign sign_extD = |(op_code[5:2] ^ 4'b0011);		//andi, xori, lui, ori为无符号拓展，其它为有符号拓展

	assign hilo_wenD = 	!(op_code ^ `EXE_R_TYPE) & 
						( 	!(funct[5:2] ^ 4'b0110) |			// div divu mult multu 	
						  	(!(funct[5:2] ^ 4'b0100) & funct[0])  //mthi mtlo
						) | madd | maddu | msub | msubu ;

	assign hilo_to_regD = ~(|(op_code ^ `EXE_R_TYPE)) & (~(|(funct[5:2] ^ 4'b0100)) & ~funct[0]);
														// 00--alu_outM; 01--hilo_o; 10 11--rdataM;
	assign is_divD = ~(|op_code) & ~(|(funct[5:1] ^ 5'b01101));	//opcode==0, funct==01101x
	assign is_multD = (~(|op_code) & ~(|(funct[5:1] ^ 5'b01100))) | mul | madd | maddu | msub | msubu;

	assign mfhi = !(op_code ^ `EXE_R_TYPE) & !(funct ^ `EXE_MFHI);
	assign mflo = !(op_code ^ `EXE_R_TYPE) & !(funct ^ `EXE_MFLO);
	assign mfhi_loD = {mfhi, mflo};
	
	assign mtc0 = ~(|(op_code ^ `EXE_COP0)) & ~|(rs ^ `EXE_MTC0);
	assign cp0_wenD = mtc0;
	assign cp0_to_regD = ~(|(op_code ^ `EXE_COP0)) & ~(|(rs ^ `EXE_MFC0));
	
	assign breakD = ~(|(op_code ^ `EXE_R_TYPE)) & ~(|(funct ^ `EXE_BREAK));
	assign syscallD = ~(|(op_code ^ `EXE_R_TYPE)) & ~(|(funct ^ `EXE_SYSCALL));
	assign eretD = ~|(op_code^`EXE_COP0) & ~|(funct^`EXE_ERET);

	assign TLBWI 	= !(op_code ^ `EXE_COP0) & !(funct ^ `EXE_TLBWI	);
	assign TLBP 	= !(op_code ^ `EXE_COP0) & !(funct ^ `EXE_TLBP	);
	assign TLBR 	= !(op_code ^ `EXE_COP0) & !(funct ^ `EXE_TLBR	);
	assign TLBWR 	= !(op_code ^ `EXE_COP0) & !(funct ^ `EXE_TLBWR	);
	assign tlb_typeD = {TLBWR, TLBWI, TLBR, TLBP};

	// special2
	assign mul 		= !(op_code ^ `EXE_SEPECIAL2) & !(funct ^ `EXE_MUL	);
	assign madd		= !(op_code ^ `EXE_SEPECIAL2) & !(funct ^ `EXE_MADD	);
	assign maddu	= !(op_code ^ `EXE_SEPECIAL2) & !(funct ^ `EXE_MADDU);
	assign msub		= !(op_code ^ `EXE_SEPECIAL2) & !(funct ^ `EXE_MSUB	);
	assign msubu	= !(op_code ^ `EXE_SEPECIAL2) & !(funct ^ `EXE_MSUBU);

	always @(*) begin
		riD = 1'b0;
		case(op_code)
			`EXE_R_TYPE:
				case(funct)
					// 算数运算指令
					`EXE_ADD,`EXE_ADDU,`EXE_SUB,`EXE_SUBU,`EXE_SLTU,`EXE_SLT ,
					`EXE_AND,`EXE_NOR, `EXE_OR, `EXE_XOR,
					`EXE_SLLV, `EXE_SLL, `EXE_SRAV, `EXE_SRA, `EXE_SRLV, `EXE_SRL,
					`EXE_MFHI, `EXE_MFLO: begin
						regfile_ctrl 	 =  4'b1_00_0;
						mem_ctrl 		 =  3'b0;
					end
					
					// 跳转执行零
					`EXE_JR, `EXE_MULT, `EXE_MULTU, `EXE_DIV, `EXE_DIVU, `EXE_MTHI, `EXE_MTLO,
					`EXE_SYSCALL, `EXE_BREAK,
					`EXE_SYNC: begin
						regfile_ctrl  =  4'b0;
						mem_ctrl  =  3'b0;
					end
					`EXE_JALR: begin
						regfile_ctrl  =  4'b1_10_0;	//先不考虑jalr rs, rd的情况，即默认跳转31号寄存器；
						mem_ctrl  =  3'b0;
					end
					default: begin
						riD  =  1'b1;
						regfile_ctrl  =  4'b1_00_0;
						mem_ctrl  =  3'b0;
					end
				endcase

// I type

	// 算数运算指令
	// 逻辑运算
			`EXE_ADDI, `EXE_SLTI, `EXE_SLTIU, `EXE_ADDIU, `EXE_ANDI, `EXE_LUI, `EXE_XORI, `EXE_ORI: begin
				regfile_ctrl  =  4'b1_01_1;
				mem_ctrl  =  3'b0;
			end

	//  B族指令
			// 可以把B族指令归纳为default中
			`EXE_BEQ, `EXE_BNE, `EXE_BLEZ, `EXE_BGTZ: begin
				regfile_ctrl  =  4'b0_00_0;
				mem_ctrl  =  3'b0;
			end

			`EXE_BRANCHS: begin
				case(rt[4:1])
					4'b1000: begin
						regfile_ctrl  =  4'b1_10_0;
						mem_ctrl  =  3'b0;
					end
					4'b0000: begin
						regfile_ctrl  =  4'b0_00_0;
						mem_ctrl  =  3'b0;
					end
					default:begin
						riD  =  1'b1;
						regfile_ctrl  =  4'b0_00_0;
						mem_ctrl  =  3'b0;
					end
				endcase
			end
			
	// 访存指令
			`EXE_LW, `EXE_LB, `EXE_LBU, `EXE_LH, `EXE_LHU: begin
				regfile_ctrl  =  4'b1_01_1;
				mem_ctrl  =  3'b1_1_0;
			end
			`EXE_SW, `EXE_SB, `EXE_SH: begin
				regfile_ctrl  =  4'b0_00_1;
				mem_ctrl  =  3'b0_0_1;
			end
	
//  J type
			`EXE_J: begin
				regfile_ctrl  =  4'b0;
				mem_ctrl  =  3'b0;
			end

			`EXE_JAL: begin
				regfile_ctrl  =  4'b1_10_0;
				mem_ctrl  =  3'b0;
			end

			`EXE_COP0:begin
				case(rs)
					`EXE_MTC0: begin
						regfile_ctrl  =  4'b0_00_0;
						mem_ctrl  =  3'b0;
					end
					`EXE_MFC0: begin
						regfile_ctrl  =  4'b1_01_0;
						mem_ctrl  =  3'b0;
					end

					default: begin
						riD  =  |(funct ^ `EXE_ERET) & |(funct ^ `EXE_TLBR) & |(funct ^ `EXE_TLBP) & |(funct ^ `EXE_TLBWI) & |(funct ^ `EXE_TLBWR) & |(funct ^ `EXE_WAIT);
						regfile_ctrl  =  4'b0_00_0;
						mem_ctrl  =  3'b0;
					end
				endcase
			end

			`EXE_SEPECIAL2: begin
				case(funct)
					`EXE_MUL, `EXE_CLZ, `EXE_CLO: begin
						regfile_ctrl	= 4'b1_00_0;
						mem_ctrl  		= 3'b0;
					end
					`EXE_MADD, `EXE_MADDU, `EXE_MSUB, `EXE_MSUBU: begin
						regfile_ctrl	= 4'b0_00_0;
						mem_ctrl  		= 3'b0;
					end
					default: begin
						riD 			= 1'b1;
						regfile_ctrl	= 4'b0_00_0;
						mem_ctrl  		= 3'b0;
					end 
				endcase
			end

			`EXE_CACHE, `EXE_PREF: begin
				regfile_ctrl  =  4'b0;
				mem_ctrl  =  3'b0;
			end
			default: begin
				riD  =  1;
				regfile_ctrl  =  4'b0;
				mem_ctrl  =  3'b0;
			end
		endcase
	end

//  lw, sw
	wire instr_lw, instr_lh, instr_lhu, instr_lb, instr_lbu, instr_sw, instr_sh, instr_sb;
	assign l_s_typeD = {instr_lw, instr_lh, instr_lhu, instr_lb, instr_lbu, instr_sw, instr_sh, instr_sb};

	assign instr_lw 	= ~(|(op_code ^ `EXE_LW));
    assign instr_lb 	= ~(|(op_code ^ `EXE_LB));
    assign instr_lh 	= ~(|(op_code ^ `EXE_LH));
    assign instr_lbu 	= ~(|(op_code ^ `EXE_LBU));
    assign instr_lhu 	= ~(|(op_code ^ `EXE_LHU));
    assign instr_sw 	= ~(|(op_code ^ `EXE_SW)); 
    assign instr_sh 	= ~(|(op_code ^ `EXE_SH));
    assign instr_sb 	= ~(|(op_code ^ `EXE_SB));
endmodule