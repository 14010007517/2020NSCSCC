module d_cache (
    input wire clk, rst,

    input wire        data_en    ,
    input wire [31:0] data_addr  ,
    output wire [31:0] data_rdata ,
    input wire [3:0] data_wen       ,
    input wire [31:0] data_wdata    ,
    output stall               ,

    output wire data_sram_en,
    output wire [4:0] data_sram_wen    ,
    output wire [31:0] data_sram_addr  ,
    output wire [31:0] data_sram_wdata ,
    input wire [31:0] data_sram_rdata  ,
    input data_sram_data_ok
);
    //stall
    assign stall = data_en & ~data_sram_data_ok;

    assign data_rdata = data_sram_rdata;

    assign data_sram_en = data_en;
    assign data_sram_wen = data_wen;
    assign data_sram_addr = data_addr;
    assign data_sram_wdata = data_wdata;
endmodule