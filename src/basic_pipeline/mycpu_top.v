module mycpu_top (
    input clk,resetn,
    input [5:0] ext_int,

    //instr
    output inst_sram_en,
    output [4:0] inst_sram_wen    ,
    output [31:0] inst_sram_addr  ,
    output [31:0] inst_sram_wdata ,
    input [31:0] inst_sram_rdata  , 

    //data
    output data_sram_en,
    output [4:0] data_sram_wen    ,
    output [31:0] data_sram_addr  ,
    output [31:0] data_sram_wdata ,
    input [31:0] data_sram_rdata  ,

    //debug
    output [31:0] debug_wb_pc     ,
    output [3:0] debug_wb_rf_wen  ,
    output [4:0] debug_wb_rf_wnum ,
    output [31:0] debug_wb_rf_wdata
);

wire inst_en           ;
wire [31:0] inst_addr  ;
wire [31:0] inst_rdata ; 

wire data_en           ;
wire [31:0] data_addr  ;
wire [31:0] data_rdata ;
wire [4:0] data_wen    ;
wire [31:0] data_wdata ;

assign inst_sram_wen = 4'b0;
assign inst_sram_wdata = 32'b0;

datapath datapath(
    .clk(clk), .rst(~resetn),

    //inst
    .inst_addrF(inst_addr),
    .inst_enF(inst_en),
    .instrD(inst_rdata),

    //data
    .mem_enM(data_en),              
    .mem_addrM(data_addr),
    .mem_rdataW(data_rdata),
    .mem_wenM(data_wen),
    .mem_wdataM(data_wdata)
);

assign debug_wb_pc          = datapath.pcW;
assign debug_wb_rf_wen      = datapath.reg_write_enW;
assign debug_wb_rf_wnum     = datapath.reg_writeW;
assign debug_wb_rf_wdata    = datapath.resultW;

i_cache i_cache(
    .clk(clk), .rst(~resetn),

    .inst_en(inst_en),
    .inst_addr(inst_addr),
    .inst_rdata(inst_rdata),

    .inst_sram_en(inst_en),
    .inst_sram_addr(inst_addr),
    .inst_sram_rdata(inst_rdata)
);

d_cache d_cache(
    .clk(clk), .rst(~resetn),

    .data_en(data_en),
    .data_addr(data_addr),
    .data_rdata(data_rdata),
    .data_wen(data_wen),
    .data_wdata(data_wdata),

    .data_sram_en(data_sram_en),
    .data_sram_wen(data_sram_wen),
    .data_sram_addr(data_sram_addr),
    .data_sram_wdata(data_sram_wdata),
    .data_sram_rdata(data_sram_rdata)
);

endmodule