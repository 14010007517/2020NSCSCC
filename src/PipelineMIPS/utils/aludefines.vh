//alu defines
`define ALU_AND             6'b00_0000
`define ALU_OR              6'b00_0001
`define ALU_ADD             6'b00_0010
`define ALU_SUB             6'b00_0011
`define ALU_SLT             6'b00_0100
`define ALU_SLL             6'b00_0101
`define ALU_SRL             6'b00_0110
`define ALU_SRA             6'b00_0111
`define ALU_SLTU            6'b00_1000
`define ALU_UNSIGNED_MULT   6'b00_1001
`define ALU_XOR             6'b00_1010
`define ALU_NOR             6'b00_1011
`define ALU_UNSIGNED_DIV    6'b00_1100
`define ALU_SIGNED_MULT     6'b00_1101
`define ALU_SIGNED_DIV      6'b00_1110
`define ALU_LUI             6'b00_1111
`define ALU_ADDU            6'b01_0000
`define ALU_SUBU            6'b01_0001
`define ALU_LEZ             6'b01_0010
`define ALU_GTZ             6'b01_0011
`define ALU_GEZ             6'b01_0100
`define ALU_LTZ             6'b01_0101
`define ALU_SLL_SA          6'b01_0110
`define ALU_SRL_SA          6'b01_0111
`define ALU_SRA_SA          6'b01_1000
`define ALU_EQ              6'b01_1001
`define ALU_NEQ             6'b01_1010
`define ALU_MTHI            6'b01_1011
`define ALU_MTLO            6'b01_1100
`define ALU_MUL             6'b01_1101
                            // 6'b1_1110
`define ALU_DONOTHING       6'b01_1111

//跑PMON时添加
`define ALU_CLO             6'b10_0000
`define ALU_CLZ             6'b10_0001
`define ALU_MADD_MULT       6'b10_0010
`define ALU_MADDU_MULT      6'b10_0011
`define ALU_MSUB_MULT       6'b10_0100
`define ALU_MSUBU_MULT      6'b10_0101
`define ALU_SC              6'b10_0110
`define ALU_TEQ             6'b10_0111
`define ALU_TGE             6'b10_1000
`define ALU_TGEU            6'b10_1001
`define ALU_TLT             6'b10_1010
`define ALU_TLTU            6'b10_1011
`define ALU_TNE             6'b10_1100