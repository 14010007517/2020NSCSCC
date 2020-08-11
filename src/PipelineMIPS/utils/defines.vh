
`define EXE_R_TYPE      6'b000000
//logic inst
`define EXE_NOP			6'b000000
`define EXE_AND 		6'b100100
`define EXE_OR 			6'b100101
`define EXE_XOR 		6'b100110
`define EXE_NOR			6'b100111
`define EXE_ANDI		6'b001100
`define EXE_ORI			6'b001101
`define EXE_XORI		6'b001110
`define EXE_LUI			6'b001111
//shift inst
`define EXE_SLL			6'b000000
`define EXE_SLLV		6'b000100
`define EXE_SRL 		6'b000010
`define EXE_SRLV 		6'b000110
`define EXE_SRA 		6'b000011
`define EXE_SRAV 		6'b000111
//move inst
`define EXE_MFHI  		6'b010000
`define EXE_MTHI  		6'b010001
`define EXE_MFLO  		6'b010010
`define EXE_MTLO  		6'b010011
//算术运算
`define EXE_SLT     6'b101010
`define EXE_SLTU    6'b101011
`define EXE_SLTI    6'b001010
`define EXE_SLTIU   6'b001011   
`define EXE_ADD     6'b100000
`define EXE_ADDU    6'b100001
`define EXE_SUB     6'b100010
`define EXE_SUBU    6'b100011
`define EXE_ADDI    6'b001000
`define EXE_ADDIU   6'b001001

`define EXE_MULT    6'b011000
`define EXE_MULTU   6'b011001
`define EXE_MUL     6'b011100

`define EXE_DIV  6'b011010
`define EXE_DIVU  6'b011011
//jump
`define EXE_J  6'b000010
`define EXE_JAL  6'b000011
`define EXE_JALR  6'b001001
`define EXE_JR  6'b001000
//branch
`define EXE_BEQ  6'b000100
`define EXE_BGTZ  6'b000111
`define EXE_BNE  6'b000101
`define EXE_BLEZ  6'b000110
`define EXE_BRANCHS 6'b000001   //
`define EXE_BLTZ  5'b00000
`define EXE_BLTZAL  5'b10000
`define EXE_BGEZAL  5'b10001
`define EXE_BGEZ  5'b00001
//load/store
`define EXE_LB  6'b100000
`define EXE_LBU  6'b100100
`define EXE_LH  6'b100001
`define EXE_LHU  6'b100101
`define EXE_LL  6'b110000
`define EXE_LW  6'b100011
`define EXE_LWL  6'b100010
`define EXE_LWR  6'b100110
`define EXE_SB  6'b101000
`define EXE_SC  6'b111000
`define EXE_SH  6'b101001
`define EXE_SW  6'b101011
`define EXE_SWL  6'b101010
`define EXE_SWR  6'b101110
//trap
`define EXE_SYSCALL 6'b001100
`define EXE_BREAK 6'b001101

`define EXE_TEQ 6'b110100
`define EXE_TEQI 5'b01100
`define EXE_TGE 6'b110000
`define EXE_TGEI 5'b01000
`define EXE_TGEIU 5'b01001
`define EXE_TGEU 6'b110001
`define EXE_TLT 6'b110010
`define EXE_TLTI 5'b01010
`define EXE_TLTIU 5'b01011
`define EXE_TLTU 6'b110011
`define EXE_TNE 6'b110110
`define EXE_TNEI 5'b01110

   
`define EXE_COP0    6'b010000
`define EXE_MTC0 5'b00100
`define EXE_MFC0 5'b00000

`define EXE_ERET    6'b011000
`define EXE_TLBP    6'b001000
`define EXE_TLBR    6'b000001
`define EXE_TLBWI   6'b000010

`define EXE_SYNC 6'b001111
`define EXE_PREF 6'b110011



//Exception code
`define EXC_CODE_INT        5'h00
`define EXC_CODE_MOD        5'h01
`define EXC_CODE_TLBL       5'h02
`define EXC_CODE_TLBS       5'h03
`define EXC_CODE_ADEL       5'h04
`define EXC_CODE_ADES       5'h05
`define EXC_CODE_SYS        5'h08
`define EXC_CODE_BP         5'h09
`define EXC_CODE_RI         5'h0a
`define EXC_CODE_CPU        5'h0b
`define EXC_CODE_OV         5'h0c
`define EXC_CODE_TR         5'h0d

`define EXC_CODE_ERET       5'hff   //自定义
`define EXC_CODE_NOEXC      4'hee   //自定义

//CP0
`define CP0_INDEX       5'd0
`define CP0_RANDOM      5'd1
`define CP0_ENTRY_LO0   5'd2
`define CP0_ENTRY_LO1   5'd3
`define CP0_CONTEX      5'd4
`define CP0_PAGE_MASK   5'd5
`define CP0_WIRED       5'd6

`define CP0_BADVADDR    5'd8    //read-only
`define CP0_COUNT       5'd9    //
`define CP0_ENTRY_HI    5'd10
`define CP0_COMPARE     5'd11   //no use
`define CP0_STATUS      5'd12   //
`define CP0_CAUSE       5'd13   //
`define CP0_EPC         5'd14   //
`define CP0_PRID        5'd15   //sel=0

`define CP0_EBASE       5'd15   //sel=1
`define CP0_CONFIG      5'd16   //sel=0
`define CP0_CONFIG1     5'd16   //sel=1

//cp0 status
`define IE_BIT 0              //
`define EXL_BIT 1
`define BEV_BIT 22
`define IM7_IM0_BITS  15:8
`define IM1_IM0_BITS  9:8
`define IM7_IM2_BITS  15:10
//cp0 cause
`define BD_BIT 31             //延迟槽
`define TI_BIT 30             //计时器中断指示 //don't use
`define IP1_IP0_BITS 9:8      //软件中断位
`define IP7_IP2_BITS 15:10    //软件中断位
`define EXC_CODE_BITS 6:2     //异常编码


//TLB
//TLB Config
`define TLB_LINE_NUM 32
`define TAG_WIDTH 20
`define OFFSET_WIDTH 12
`define LOG2_TLB_LINE_NUM 5

`define INDEX_BITS `LOG2_TLB_LINE_NUM-1:0

//EntryHi
`define VPN2_BITS 31:13
`define ASID_BITS 7:0
//G bit in TLB entry
`define G_BIT 12
//PageMask
`define MASK_BITS 24:13
//EntryLo
`define PFN_BITS 25:6
`define FLAG_BITS 5:0
`define V_BIT 1
`define D_BIT 2
`define C_BITS 5:3