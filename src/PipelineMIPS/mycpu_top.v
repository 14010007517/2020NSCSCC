module mycpu_top (
    input wire aclk,
    input wire aresetn,

    input [5:0] ext_int,            //interrupt

    output wire[3:0] arid,
    output wire[31:0] araddr,
    output wire[3:0] arlen,
    output wire[2:0] arsize,
    output wire[1:0] arburst,
    output wire[1:0] arlock,
    output wire[3:0] arcache,
    output wire[2:0] arprot,
    output wire arvalid,
    input wire arready,
                
    input wire[3:0] rid,
    input wire[31:0] rdata,
    input wire[1:0] rresp,
    input wire rlast,
    input wire rvalid,
    output wire rready,
               
    output wire[3:0] awid,
    output wire[31:0] awaddr,
    output wire[3:0] awlen,
    output wire[2:0] awsize,
    output wire[1:0] awburst,
    output wire[1:0] awlock,
    output wire[3:0] awcache,
    output wire[2:0] awprot,
    output wire awvalid,
    input wire awready,
    
    output wire[3:0] wid,
    output wire[31:0] wdata,
    output wire[3:0] wstrb,
    output wire wlast,
    output wire wvalid,
    input wire wready,
    
    input wire[3:0] bid,
    input wire[1:0] bresp,
    input bvalid,
    output bready,

    //debug interface
    output wire[31:0] debug_wb_pc,
    output wire[3:0] debug_wb_rf_wen,
    output wire[4:0] debug_wb_rf_wnum,
    output wire[31:0] debug_wb_rf_wdata
);
    wire clk, rst;
    assign clk = aclk;
    assign rst = ~aresetn;

    //TLB
    wire [31:0] pcF_paddr;
    wire [31:0] data_paddr;
    wire no_cache_i;
    wire no_cache_d;
    wire flushM;
        //TLB指令
	wire TLBP;
	wire TLBR;
    wire TLBWI;
    wire TLBWR;
    wire [31:0] EntryHi_from_cp0;
	wire [31:0] PageMask_from_cp0;
	wire [31:0] EntryLo0_from_cp0;
	wire [31:0] EntryLo1_from_cp0;
	wire [31:0] Index_from_cp0;
	wire [31:0] Random_from_cp0;
	wire [31:0] EntryHi_to_cp0;
	wire [31:0] PageMask_to_cp0;
	wire [31:0] EntryLo0_to_cp0;
	wire [31:0] EntryLo1_to_cp0;
	wire [31:0] Index_to_cp0;
        //异常
    wire inst_tlb_refill, inst_tlb_invalid;
    wire data_tlb_refill, data_tlb_invalid, data_tlb_modify;
    wire mem_read_enM, mem_write_enM;

    //datapath - cache
    wire inst_en            ;
    wire [31:0] pcF         ;
    wire [31:0] pc_next     ;
    wire [31:0] inst_rdata  ; 
    wire i_cache_stall      ;
    wire stallF             ;
    wire stallM             ;

    wire data_en            ;
    wire [31:0] data_addr   ;
    wire [31:0] data_rdata  ;
    wire [3:0] data_wen     ;
    wire [31:0] data_wdata  ;
    wire [2:0] load_type    ;
    wire d_cache_stall      ;
    wire [31:0] mem_addrE   ;
    wire mem_read_enE       ;
    wire mem_write_enE      ;

    //i_cache - arbitrater
    wire [31:0] i_araddr    ;
    wire [3:0] i_arlen      ;
    wire i_arvalid          ;
    wire i_arready          ;

    wire [31:0] i_rdata     ;
    wire i_rlast            ;
    wire i_rvalid           ;
    wire i_rready           ;

    //d_cache - arbitrater
    wire [31:0] d_araddr    ;
    wire [3:0] d_arlen      ;
    wire [2:0] d_arsize     ;
    wire d_arvalid          ;
    wire d_arready          ;
    wire [6:0]  cacheM      ;
    wire [6:0]  cacheE      ;

    wire[31:0] d_rdata      ;
    wire d_rlast            ;
    wire d_rvalid           ;
    wire d_rready           ;

    wire [31:0] d_awaddr    ;
    wire [3:0] d_awlen      ;
    wire [2:0] d_awsize     ;
    wire d_awvalid          ;
    wire d_awready          ;

    wire [31:0] d_wdata     ;
    wire [3:0] d_wstrb      ;
    wire d_wlast            ;
    wire d_wvalid           ;
    wire d_wready           ;

    wire d_bvalid           ;
    wire d_bready           ;

    wire inst_en_tmp;
    wire [19:0] inst_pfn, data_pfn;


//--------------------debug---------------------
    wire [31:0] cp0_statusW, cp0_causeW;
    wire ila_ar_sel, ila_r_sel;
    wire ila_hit_i, ila_hit_d;
    wire flush_exceptionM;
    wire tlb_instr = TLBP|TLBR|TLBWI|TLBWR;
    ila_0 ila_00 (
        .clk(clk), // input wire clk

        .probe0(pcF), // input wire [31:0]  probe0  
        .probe1(
            {pcF_paddr[31:12],  //20
            cp0_causeW[6:2], //5
            cp0_statusW[22], cp0_statusW[1:0], //3
            ila_ar_sel, //4
            ila_r_sel,   
            ila_hit_i,
            ila_hit_d
            }
        ), // input wire [31:0]  probe1 
        .probe2(mem_addrM), // input wire [31:0]  probe2 
        .probe3(rdata), // input wire [31:0]  probe3 
        .probe4({flush_exceptionM, stallF, stallM, tlb_instr}) // input wire [3:0]  probe4
    );
//--------------------debug---------------------

    datapath datapath(
        .clk(clk), .rst(rst),
        .ext_int(ext_int),

        //debug
        .ila_cp0_causeW(cp0_causeW),
        .ila_cp0_statusW(cp0_statusW),
        .ila_flush_exceptionM(flush_exceptionM),


        //TLB
        .TLBP(TLBP),
        .TLBR(TLBR),
        .TLBWI(TLBWI),
        .TLBWR(TLBWR),

        .EntryHi_from_cp0(EntryHi_from_cp0),
        .PageMask_from_cp0(PageMask_from_cp0),
        .EntryLo0_from_cp0(EntryLo0_from_cp0),
        .EntryLo1_from_cp0(EntryLo1_from_cp0),
        .Index_from_cp0(Index_from_cp0),
        .Random_from_cp0(Random_from_cp0),

        .EntryHi_to_cp0(EntryHi_to_cp0),
        .PageMask_to_cp0(PageMask_to_cp0),
        .EntryLo0_to_cp0(EntryLo0_to_cp0),
        .EntryLo1_to_cp0(EntryLo1_to_cp0),
        .Index_to_cp0(Index_to_cp0),
            //异常
        .inst_tlb_refillF(inst_tlb_refill), .inst_tlb_invalidF(inst_tlb_invalid),
        .data_tlb_refillM(data_tlb_refill),
        .data_tlb_invalidM(data_tlb_invalid),
        .data_tlb_modifyM(data_tlb_modify),
        .mem_read_enM(mem_read_enM), .mem_write_enM(mem_write_enM),

        //inst
        .pcF(pcF),
        .pc_next(pc_next),
        .inst_enF(inst_en_tmp),
        .instrF(inst_rdata),
        .i_cache_stall(i_cache_stall),
        .stallF(stallF),

        //data
        .mem_enM(data_en),              
        .mem_addrM(data_addr),
        .mem_rdataM(data_rdata),
        .mem_wenM(data_wen),
        .mem_wdataM(data_wdata),
        .load_type(load_type),
        .mem_addrE(mem_addrE),
        .mem_read_enE(mem_read_enE),
        .mem_write_enE(mem_write_enE),
        .d_cache_stall(d_cache_stall),
        .stallM(stallM),
        .cacheM(cacheM),
        .cacheE(cacheE),

        .debug_wb_pc       (debug_wb_pc       ),  
        .debug_wb_rf_wen   (debug_wb_rf_wen   ),  
        .debug_wb_rf_wnum  (debug_wb_rf_wnum  ),  
        .debug_wb_rf_wdata (debug_wb_rf_wdata )  
    );

    assign inst_en = inst_en_tmp & ~inst_tlb_refill & ~inst_tlb_invalid; //优化：tlb异常时，放弃取指
    //非简易的MMU
    tlb tlb0(
        .clk(clk), .rst(rst),
        .stallM(stallM), .flushM(flushM),
        //datapath
        .inst_vaddr(pcF),
        .data_vaddr(mem_addrE),

        .inst_en(inst_en_tmp),
        .mem_read_enM(mem_read_enM), .mem_write_enM(mem_write_enM),
        //cache
        
        // .inst_paddr(pcF_paddr),
        // .data_paddr(data_paddr),
        .inst_pfn(inst_pfn),
        .data_pfn(data_pfn),
        .no_cache_i(no_cache_i),
        .no_cache_d(no_cache_d),
        //异常
        .inst_tlb_refill(inst_tlb_refill),
        .inst_tlb_invalid(inst_tlb_invalid),
        .data_tlb_refill(data_tlb_refill),
        .data_tlb_invalid(data_tlb_invalid),
        .data_tlb_modify(data_tlb_modify),

        //TLB指令
        .TLBP(TLBP),
        .TLBR(TLBR),
        .TLBWI(TLBWI),
        .TLBWR(TLBWR),
        
        .EntryHi_in(EntryHi_from_cp0),
        .PageMask_in(PageMask_from_cp0),
        .EntryLo0_in(EntryLo0_from_cp0),
        .EntryLo1_in(EntryLo1_from_cp0),
        .Index_in(Index_from_cp0),
        .Random_in(Random_from_cp0),

        .EntryHi_out(EntryHi_to_cp0),
        .PageMask_out(PageMask_to_cp0),
        .EntryLo0_out(EntryLo0_to_cp0),
        .EntryLo1_out(EntryLo1_to_cp0),
        .Index_out(Index_to_cp0)
    );

    i_cache i_cache(
        .clk(clk), .rst(rst),

        //ila_debug
        .ila_hit(ila_hit_i),

        //cache指令
        .cacheE(cacheE),
        .cacheM(cacheM),
        .data_pfn(data_pfn),    //cache指令都使用tlb的端口2做地址转换
        .data_vaddrM(data_addr),

        //TLB
        .no_cache(no_cache_i),
        
        //datapath
        .inst_en(inst_en),
        .inst_vaddr(pcF),           //
        // .inst_paddr(pcF_paddr),     //
        .inst_pfn(inst_pfn),
        .inst_rdata(inst_rdata),
        .pc_next(pc_next),          //
        .stall(i_cache_stall),
        .stallF(stallF),

        //arbitrater
        .araddr          (i_araddr ),
        .arlen           (i_arlen  ),
        .arvalid         (i_arvalid),
        .arready         (i_arready),
                    
        .rdata           (i_rdata ),
        .rlast           (i_rlast ),
        .rvalid          (i_rvalid),
        .rready          (i_rready)
    );

    d_cache d_cache(
        .clk(clk), .rst(rst),

        //ila_debug
        .ila_hit(ila_hit_d),

        //cache指令
        .cacheM(cacheM),
        .cacheE(cacheE),

        //TLB
        .no_cache(no_cache_d),

        //datapath
        .data_en(data_en),
        .data_vaddr(data_addr),     //datapath M阶段，未经tlb转换
        .data_pfn(data_pfn),        //datapath M阶段，经过tlb转换
        // .data_paddr(data_paddr),    //datapath M阶段，经过tlb转换
        .data_rdata(data_rdata),
        .data_wen(data_wen),
        .data_wdata(data_wdata),
        .load_type(load_type),
        .stall(d_cache_stall),
        .mem_addrE(mem_addrE),      //datapath E阶段，未经tlb转换
        .mem_read_enE(mem_read_enE),
        .mem_write_enE(mem_write_enE),
        .stallM(stallM),
        
        //arbitrater
        .araddr          (d_araddr ),
        .arlen           (d_arlen  ),
        .arsize          (d_arsize ),
        .arvalid         (d_arvalid),
        .arready         (d_arready),

        .rdata           (d_rdata ),
        .rlast           (d_rlast ),
        .rvalid          (d_rvalid),
        .rready          (d_rready),

        .awaddr          (d_awaddr ),
        .awlen           (d_awlen  ),
        .awsize          (d_awsize ),
        .awvalid         (d_awvalid),
        .awready         (d_awready),

        .wdata           (d_wdata ),
        .wstrb           (d_wstrb ),
        .wlast           (d_wlast ),
        .wvalid          (d_wvalid),
        .wready          (d_wready),

        .bvalid          (d_bvalid),
        .bready          (d_bready)
    );

    arbitrater arbitrater0(
        .clk(clk), 
        .rst(rst),

        //ila debug
        .ila_ar_sel(ila_ar_sel),
        .ila_r_sel(ila_r_sel),
    //I CACHE
        .i_araddr          (i_araddr ),
        .i_arlen           (i_arlen  ),
        .i_arvalid         (i_arvalid),
        .i_arready         (i_arready),
                  
        .i_rdata           (i_rdata ),
        .i_rlast           (i_rlast ),
        .i_rvalid          (i_rvalid),
        .i_rready          (i_rready),
        
    //D CACHE
        .d_araddr          (d_araddr ),
        .d_arlen           (d_arlen  ),
        .d_arsize          (d_arsize ),
        .d_arvalid         (d_arvalid),
        .d_arready         (d_arready),

        .d_rdata           (d_rdata ),
        .d_rlast           (d_rlast ),
        .d_rvalid          (d_rvalid),
        .d_rready          (d_rready),

        .d_awaddr          (d_awaddr ),
        .d_awlen           (d_awlen  ),
        .d_awsize          (d_awsize ),
        .d_awvalid         (d_awvalid),
        .d_awready         (d_awready),

        .d_wdata           (d_wdata ),
        .d_wstrb           (d_wstrb ),
        .d_wlast           (d_wlast ),
        .d_wvalid          (d_wvalid),
        .d_wready          (d_wready),

        .d_bvalid          (d_bvalid),
        .d_bready          (d_bready),
    //Outer
        .arid            (arid   ),
        .araddr          (araddr ),
        .arlen           (arlen  ),
        .arsize          (arsize ),
        .arburst         (arburst),
        .arlock          (arlock ),
        .arcache         (arcache),
        .arprot          (arprot ),
        .arvalid         (arvalid),
        .arready         (arready),
                   
        .rid             (rid   ),
        .rdata           (rdata ),
        .rresp           (rresp ),
        .rlast           (rlast ),
        .rvalid          (rvalid),
        .rready          (rready),
               
        .awid            (awid   ),
        .awaddr          (awaddr ),
        .awlen           (awlen  ),
        .awsize          (awsize ),
        .awburst         (awburst),
        .awlock          (awlock ),
        .awcache         (awcache),
        .awprot          (awprot ),
        .awvalid         (awvalid),
        .awready         (awready),
        
        .wid             (wid   ),
        .wdata           (wdata ),
        .wstrb           (wstrb ),
        .wlast           (wlast ),
        .wvalid          (wvalid),
        .wready          (wready),
        .bid             (bid   ),
        .bresp           (bresp ),
        .bvalid          (bvalid),
        .bready          (bready)
    );
endmodule