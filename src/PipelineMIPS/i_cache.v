module i_cache (
    input wire clk, rst,

    input   wire        inst_en    ,
    input   wire [31:0] inst_addr  ,
    output  wire [31:0] inst_rdata ,

    output wire inst_sram_en,
    output wire [31:0] inst_sram_addr  ,
    input wire [31:0] inst_sram_rdata
);

    assign inst_rdata = inst_sram_rdata;

    assign inst_sram_en = inst_en;
    assign inst_sram_addr = inst_addr;
endmodule