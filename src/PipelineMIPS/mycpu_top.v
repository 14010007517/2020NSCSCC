module mycpu_top (
    input wire aclk,
    input wire aresetn,

    input [5:0] ext_int,            //interrupt

    output wire[3:0] arid,
    output wire[31:0] araddr,
    output wire[7:0] arlen,
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
    output wire[7:0] awlen,
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

    //d_tlb - d_cache
    wire no_cache_d         ;   //数据
    wire no_cache_i         ;   //指令

    //datapath - cache
    wire inst_en            ;
    wire [31:0] pcF         ;
    wire [31:0] pcF_tmp     ;
    wire [31:0] pc_next     ;
    wire [31:0] pc_next_tmp ;
    wire [31:0] inst_rdata  ; 
    wire i_cache_stall      ;
    wire stallF             ;
    wire stallM             ;

    wire data_en            ;
    wire [31:0] data_addr   ;
    wire [31:0] data_addr_tmp;
    wire [31:0] data_rdata  ;
    wire [3:0] data_wen     ;
    wire [31:0] data_wdata  ;
    wire d_cache_stall      ;
    wire [31:0] mem_addrE   ;
    wire [31:0] mem_addrE_tmp;
    wire mem_read_enE       ;
    wire mem_write_enE      ;

    //i_cache - arbitrater
    wire [31:0] i_araddr    ;
    wire [7:0] i_arlen      ;
    wire i_arvalid          ;
    wire i_arready          ;

    wire [31:0] i_rdata     ;
    wire i_rlast            ;
    wire i_rvalid           ;
    wire i_rready           ;

    //d_cache - arbitrater
    wire [31:0] d_araddr    ;
    wire [7:0] d_arlen      ;
    wire d_arvalid          ;
    wire d_arready          ;

    wire[31:0] d_rdata      ;
    wire d_rlast            ;
    wire d_rvalid           ;
    wire d_rready           ;

    wire [31:0] d_awaddr    ;
    wire [7:0] d_awlen      ;
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

  //------------------------------debug------------------------------
    //I cache
    wire i_hit_exception, i_hit_pc_error, i_hit_branch, i_hit_jump;
    wire i_miss_exception, i_miss_pc_error, i_miss_branch, i_miss_jump;

    wire i_miss, i_hit;
    assign i_hit = (|i_cache.sel_mask);
    assign i_miss = ~i_hit;

    assign i_hit_exception = i_hit & datapath.flush_exceptionM;
    assign i_hit_pc_error = i_hit & datapath.pc_errorF;
    assign i_hit_branch = i_hit & datapath.flush_pred_failedM;
    assign i_hit_jump = i_hit & datapath.flush_jump_confilctE;

    assign i_miss_exception = i_miss & datapath.flush_exceptionM;
    assign i_miss_pc_error = i_miss & datapath.pc_errorF;
    assign i_miss_branch = i_miss & datapath.flush_pred_failedM;
    assign i_miss_jump = i_miss & datapath.flush_jump_confilctE;

    //D cache
    wire d_lw_hit, d_lw_miss, d_lw_miss_dirty, d_lw_no_cache;
    wire d_sw_hit, d_sw_miss, d_sw_miss_dirty, d_sw_no_cache;
    wire d_sbh_hit, d_sbh_miss;

    wire d_miss_exception;
    
    wire d_hit, d_miss;
    wire d_read, d_write;
    assign d_hit =  (|d_cache.sel_mask);
    assign d_miss = ~d_hit;
    assign d_read = datapath.mem_read_enM;
    assign d_write = datapath.mem_write_enM;

    assign d_lw_hit = d_read & d_hit;
    assign d_lw_miss = d_read & d_miss & ~d_cache.dirty;
    assign d_lw_miss_dirty = d_read & d_miss & d_cache.dirty;
    assign d_lw_no_cache = d_read & no_cache_d;

    assign d_sw_hit = d_write & d_hit;
    assign d_sw_miss = d_write & d_miss & ~d_cache.dirty;
    assign d_sw_miss_dirty = d_write & d_miss & d_cache.dirty;
    assign d_sw_no_cache = d_write & no_cache_d;

    assign d_sbh_hit = d_write & d_hit & (data_wen!=4'b1111);
    assign d_sbh_miss = d_write & d_miss & (data_wen!=4'b1111);

    assign d_miss_exception = (d_read | d_write) & d_miss & datapath.flush_exceptionM;
    
    //DIV, MULT
    wire is_div, is_mult;
    wire div_branch, div_exception;
    wire mult_branch, mult_exception;

	assign is_div = datapath.alu0.div_valid;
    assign is_mult = datapath.alu0.mult_valid;

    assign div_branch = is_div & datapath.branchM;
    assign div_exception = is_div & datapath.flush_exceptionM;

    assign mult_branch = is_mult & datapath.branchM;
    assign mult_exception = is_mult & datapath.flush_exceptionM;

     //debug rate
    wire i_hit, d_hit, i_miss, d_miss;
    hit_rate hit_rate0(
        .clk(clk), .rst(rst),
        .i_hit(i_hit),
        .d_hit(d_hit),
        .i_miss(i_miss),
        .d_miss(d_miss),
        .stallF(stallF)
    );
    //------------------------------debug------------------------------
    
   

    datapath datapath(
        .clk(clk), .rst(rst),
        .ext_int(ext_int),

        //inst
        .pcF(pcF_tmp),
        .pc_next(pc_next_tmp),
        .inst_enF(inst_en),
        .instrF(inst_rdata),
        .i_cache_stall(i_cache_stall),
        .stallF(stallF),
        .stallM(stallM),

        //data
        .mem_enM(data_en),              
        .mem_addrM(data_addr_tmp),
        .mem_rdataM(data_rdata),
        .mem_wenM(data_wen),
        .mem_wdataM(data_wdata),
        .d_cache_stall(d_cache_stall),
        .mem_addrE(mem_addrE_tmp),
        .mem_read_enE(mem_read_enE),
        .mem_write_enE(mem_write_enE),

        .debug_wb_pc       (debug_wb_pc       ),  
        .debug_wb_rf_wen   (debug_wb_rf_wen   ),  
        .debug_wb_rf_wnum  (debug_wb_rf_wnum  ),  
        .debug_wb_rf_wdata (debug_wb_rf_wdata )  
    );

    //简易的MMU
    d_tlb d_tlb0(
        .inst_vaddr(pcF_tmp),
        .inst_vaddr2(pc_next_tmp),
        .data_vaddr(data_addr_tmp),
        .data_vaddr2(mem_addrE_tmp),

        .inst_paddr(pcF),
        .inst_paddr2(pc_next),
        .data_paddr(data_addr),
        .data_paddr2(mem_addrE),
        .no_cache_d(no_cache_d),
        .no_cache_i(no_cache_i)
    );

    i_cache i_cache(
        .clk(clk), .rst(rst),

        //TLB
        .no_cache(no_cache_i),
        
        //debug rate
        .i_cache_hit(i_hit), .i_cache_miss(i_miss),

        //datapath
        .inst_en(inst_en),
        .pc_next(pc_next),
        .pcF(pcF),
        .inst_rdata(inst_rdata),
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

        //debug rate
        .d_cache_hit(d_hit), .d_cache_miss(d_miss),

        //TLB
        .no_cache(no_cache_d),

        //datapath
        .data_en(data_en),
        .data_addr(data_addr),
        .data_rdata(data_rdata),
        .data_wen(data_wen),
        .data_wdata(data_wdata),
        .stall(d_cache_stall),
        .mem_addrE(mem_addrE),
        .mem_read_enE(mem_read_enE),
        .mem_write_enE(mem_write_enE),
        .stallM(stallM),
        
        //arbitrater
        .araddr          (d_araddr ),
        .arlen           (d_arlen  ),
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