`timescale 1ns / 1ps

// Create Date: 2019/06/21 16:14:50

`include "aludefines.vh"
`include "defines.vh"

module alu_decoder(
	input wire clk, rst,
	input wire [31:0] instrD,
	
    output reg [4:0] alu_controlE
    );
	
    wire [5:0] op_code;
	wire [4:0] rs, rt;
	wire [5:0] funct;
    reg  [4:0] alu_control;

    assign op_code = instrD[31:26];
    assign rs = instrD[25:21];
    assign rt = instrD[20:16];
    assign funct = instrD[5:0];
    
	always @* begin
		case(op_code)
			`EXE_R_TYPE: 
				case(funct)
					//算数和逻辑运算
					`EXE_AND:   	alu_control <= `ALU_AND; //1
					`EXE_OR:    	alu_control <= `ALU_OR;
					`EXE_XOR:   	alu_control <= `ALU_XOR;
					`EXE_NOR:   	alu_control <= `ALU_NOR;

					`EXE_ADD:   	alu_control <= `ALU_ADD;	//4
					`EXE_SUB:   	alu_control <= `ALU_SUB;
					`EXE_ADDU:  	alu_control <= `ALU_ADDU;
					`EXE_SUBU:  	alu_control <= `ALU_SUBU;
					`EXE_SLT:   	alu_control <= `ALU_SLT;
					`EXE_SLTU:  	alu_control <= `ALU_SLTU;
						//div and mul
					`EXE_DIV:   	alu_control <= `ALU_SIGNED_DIV;
					`EXE_DIVU:  	alu_control <= `ALU_UNSIGNED_DIV;
					`EXE_MULT:  	alu_control <= `ALU_SIGNED_MULT;
					`EXE_MULTU: 	alu_control <= `ALU_UNSIGNED_MULT;

					//移位指令
					`EXE_SLL:   	alu_control <= `ALU_SLL_SA;	//2
					`EXE_SRL:   	alu_control <= `ALU_SRL_SA;
					`EXE_SRA:   	alu_control <= `ALU_SRA_SA;
					`EXE_SLLV:  	alu_control <= `ALU_SLL;
					`EXE_SRLV:  	alu_control <= `ALU_SRL;
					`EXE_SRAV:  	alu_control <= `ALU_SRA;

					//hilo
					`EXE_MFHI:  	alu_control <= `ALU_MFHI;	//3
					`EXE_MFLO:  	alu_control <= `ALU_MFLO;
					`EXE_MTHI:  	alu_control <= `ALU_MTHI;
					`EXE_MTLO:  	alu_control <= `ALU_MTLO;
					//jump
					`EXE_JR:		alu_control <= `ALU_DONOTHING; //5
					// `EXE_JALR:		alu_control <= `ALU_PC_PLUS8;
					default:    	alu_control <= `ALU_ADDU;
				endcase
			//I type
			`EXE_ADDI: 	alu_control <= `ALU_ADD;
			`EXE_ADDIU: alu_control <= `ALU_ADDU;
			`EXE_SLTI: 	alu_control <= `ALU_SLT;
			`EXE_SLTIU: alu_control <= `ALU_SLTU;
			`EXE_ANDI: 	alu_control <= `ALU_AND;
			`EXE_XORI: alu_control <= `ALU_XOR;
			`EXE_LUI: 	alu_control <= `ALU_LUI;
			`EXE_ORI: alu_control <= `ALU_OR;
				//memory
			`EXE_LW, `EXE_LB, `EXE_LBU, `EXE_LH, `EXE_LHU, `EXE_SW, `EXE_SB, `EXE_SH:
						alu_control <= `ALU_ADD;
			`EXE_BEQ:
                alu_control <= `ALU_XNOR;
            `EXE_BGTZ:
                alu_control <= `ALU_GTZ;
            `EXE_BLEZ:   
                alu_control <= `ALU_LEZ;
            `EXE_BNE:
                alu_control <= `ALU_XOR;
            `EXE_BRANCHS:   //bltz, bltzal, bgez, bgezal
                case(rt)
                    `EXE_BLTZ, `EXE_BLTZAL:      
                        alu_control <= `ALU_LTZ;
                    `EXE_BGEZ, `EXE_BGEZAL: 
                        alu_control <= `ALU_GEZ;
                    default:
                        alu_control <= `ALU_DONOTHING; 
                endcase	
			//J type
			`EXE_J:		alu_control <= `ALU_DONOTHING;
			// `EXE_JAL:	alu_control <= `ALU_PC_PLUS8;
			default:
						alu_control <= `ALU_DONOTHING;
		endcase
	end

// ID-EX flow 
    always@(posedge clk) begin
        alu_controlE <= alu_control;
    end

endmodule
