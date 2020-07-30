`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2018/08/06 15:21:16
// Design Name: 
// Module Name: instdec
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

`timescale 1ns / 1ps

`include "defines.vh"


module inst_ascii_decoder(
    input wire [31:0] instr,
    output reg [44:0] ascii
    );

    always @(*)
    begin
        ascii<="N-R";
        case(instr[31:26])
            `EXE_NOP:   // R-type
                begin
                    case(instr[5:0])
                        /* logic instraction */
                        `EXE_AND: ascii<= "AND";
                        `EXE_OR: ascii<= "OR";
                        `EXE_XOR: ascii<= "XOR";
                        `EXE_NOR: ascii<= "NOR";
                        /* shift instraction */
                        `EXE_SLL: ascii<= "SLL";
                        `EXE_SRL: ascii<= "SRL";
                        `EXE_SRA: ascii<= "SRA";
                        `EXE_SLLV: ascii<= "SLLV";
                        `EXE_SRLV: ascii<= "SRLV";
                        `EXE_SRAV: ascii<= "SRAV";
                        /* move instraction */
                        `EXE_MFHI: ascii<= "MFHI";
                        `EXE_MTHI: ascii<= "MTHI";
                        `EXE_MFLO: ascii<= "MFLO";
                        `EXE_MTLO: ascii<= "MTLO";
                        /* arithemtic instraction */
                        `EXE_ADD: ascii<= "ADD";
                        `EXE_ADDU: ascii<= "ADDU";
                        `EXE_SUB: ascii<= "SUB";
                        `EXE_SUBU: ascii<= "SUBU";
                        `EXE_SLT: ascii<= "SLT";
                        `EXE_SLTU: ascii<= "SLTU";

                        `EXE_MULT: ascii<= "MULT";
                        `EXE_MULTU: ascii<= "MULTU";
                        `EXE_DIV: ascii<= "DIV";
                        `EXE_DIVU: ascii<= "DIVU";
                        /* jump instraction */
                        `EXE_JR: ascii<= "JR";
                        `EXE_JALR: ascii<= "JALR";
                        
                        `EXE_SYSCALL: ascii<= "SYSC";
                        `EXE_BREAK: ascii<= "BREAK";
                        default: ascii<="N-R";
                    endcase
                end
            `EXE_ANDI: ascii<= "ANDI";
            `EXE_XORI: ascii<= "XORI";
            `EXE_LUI: ascii<= "LUI";
            `EXE_ORI: ascii<= "ORI";

            `EXE_ADDI: ascii<= "ADDI";
            `EXE_ADDIU: ascii<= "ADDIU";
            `EXE_SLTI: ascii<= "SLTI";
            `EXE_SLTIU: ascii<= "SLTIU";

            `EXE_J: ascii<= "J";
            `EXE_JAL: ascii<= "JAL";
            
            `EXE_BEQ: ascii<= "BEQ";
            `EXE_BGTZ: ascii<= "BGTZ";
            `EXE_BLEZ: ascii<= "BLEZ";
            `EXE_BNE: ascii<= "BNE";
            
            `EXE_LB: ascii<= "LB";
            `EXE_LBU: ascii<= "LBU";
            `EXE_LH: ascii<= "LH";
            `EXE_LHU: ascii<= "LHU";
            `EXE_LW: ascii<= "LW";
            `EXE_SB: ascii<= "SB";
            `EXE_SH: ascii<= "SH";
            `EXE_SW: ascii<= "SW";
            6'b000001: begin 
                case (instr[20:16])
                    `EXE_BGEZ: ascii<= "BGEZ";
                    `EXE_BGEZAL: ascii<= "BGEZAL";
                    `EXE_BLTZ: ascii<= "BLTZ";
                    `EXE_BLTZAL: ascii<= "BLTZAL";
                    default : ascii<= " ";
                endcase
            end
            6'b010000: begin 
                if(instr==`EXE_ERET) begin
                    ascii<="ERET";
                end else begin 
                    case (instr[25:21])
                        5'b00100: ascii<="MTOC0";
                        5'b00000: ascii<="MFC0";
                    endcase
                end
            end
            default: ascii<= "N-R";
       endcase
    if(instr==`EXE_ERET)
        ascii<= "ERET";
    if(!instr)
        ascii<= "NOP";
    end

endmodule

