module soc_top
(
    input         resetn, 
    input         clk
);
//debug signals
wire [31:0] debug_wb_pc;
wire [3 :0] debug_wb_rf_wen;
wire [4 :0] debug_wb_rf_wnum;
wire [31:0] debug_wb_rf_wdata;

//cpu inst sram
wire        cpu_inst_en;
wire [3 :0] cpu_inst_wen;
wire [31:0] cpu_inst_addr;
wire [31:0] cpu_inst_wdata;
wire [31:0] cpu_inst_rdata;
//cpu data sram
wire        cpu_data_en;
wire [3 :0] cpu_data_wen;
wire [31:0] cpu_data_addr;
wire [31:0] cpu_data_wdata;
wire [31:0] cpu_data_rdata;

//cpu
mycpu_top cpu(
    .clk              (clk   ),
    .resetn           (resetn),  //low active
    .ext_int          (6'd0      ),  //interrupt,high active

    .inst_sram_en     (cpu_inst_en   ),
    .inst_sram_wen    (cpu_inst_wen  ),
    .inst_sram_addr   (cpu_inst_addr ),
    .inst_sram_wdata  (cpu_inst_wdata),
    .inst_sram_rdata  (cpu_inst_rdata),
    
    .data_sram_en     (cpu_data_en   ),
    .data_sram_wen    (cpu_data_wen  ),
    .data_sram_addr   (cpu_data_addr ),
    .data_sram_wdata  (cpu_data_wdata),
    .data_sram_rdata  (cpu_data_rdata),

    //debug
    .debug_wb_pc      (debug_wb_pc      ),
    .debug_wb_rf_wen  (debug_wb_rf_wen  ),
    .debug_wb_rf_wnum (debug_wb_rf_wnum ),
    .debug_wb_rf_wdata(debug_wb_rf_wdata)
);

//inst ram
inst_ram inst_ram
(
    .clka  (clk                 ),   
    // .rsta  (~resetn             ),
    .ena   (cpu_inst_en         ),
    .wea   (cpu_inst_wen        ),   //3:0
    .addra (cpu_inst_addr       ),   //17:0
    .dina  (cpu_inst_wdata      ),   //31:0
    .douta (cpu_inst_rdata      )    //31:0
);

//data ram
data_ram data_ram
(
    .clka  (clk                 ),   
    .ena   (cpu_data_en         ),
    .wea   (cpu_data_wen        ),   //3:0
    .addra (cpu_data_addr       ),   //15:0
    .dina  (cpu_data_wdata      ),   //31:0
    .douta (cpu_data_rdata      )    //31:0
);
endmodule

