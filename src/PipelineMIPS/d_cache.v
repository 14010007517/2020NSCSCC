module d_cache (
    input wire clk, rst,

    //tlb
    input wire no_cache,
    //datapath
    input wire data_en,
    input wire [31:0] data_addr,
    output wire [31:0] data_rdata,
    input wire [3:0] data_wen,
    input wire [31:0] data_wdata,
    output wire stall,
    input wire [31:0] mem_addrE,
    input wire mem_read_enE,
    input wire mem_write_enE,
    input wire stallM,

    //arbitrater
    output wire [31:0] araddr,
    output wire [7:0] arlen,
    output wire arvalid,
    input wire arready,

    input wire [31:0] rdata,
    input wire rlast,
    input wire rvalid,
    output wire rready,

    //write
    output wire [31:0] awaddr,
    output wire [7:0] awlen,
    output wire [2:0] awsize,
    output wire awvalid,
    input wire awready,
    
    output wire [31:0] wdata,
    output wire [3:0] wstrb,
    output wire wlast,
    output wire wvalid,
    input wire wready,

    input wire bvalid,
    output wire bready    
); 

//变量声明
    //cache configure
    parameter TAG_WIDTH = 20, INDEX_WIDTH = 7, OFFSET_WIDTH = 5;
    parameter WAY_NUM = 4, LOG2_WAY_NUM = 2;
    localparam BLOCK_NUM= 1<<(OFFSET_WIDTH-2);
    localparam CACHE_LINE_NUM = 1<<INDEX_WIDTH;
    
    wire [TAG_WIDTH-1    : 0] tag;
    wire [INDEX_WIDTH-1  : 0] index, indexE;
    wire [OFFSET_WIDTH-3 : 0] offset; //字偏移

    assign tag      = data_addr[31                         : INDEX_WIDTH+OFFSET_WIDTH ];
    assign index    = data_addr[INDEX_WIDTH+OFFSET_WIDTH-1 : OFFSET_WIDTH             ];    
    assign indexE   = mem_addrE[INDEX_WIDTH+OFFSET_WIDTH-1 : OFFSET_WIDTH             ];
    assign offset   = data_addr[OFFSET_WIDTH-1             : 2                        ];

    //read
    wire read, write;
    assign read = data_en & ~(|data_wen);   //load
    assign write = data_en & |data_wen;     //store

    //cache ram
    //read
    wire enb_tag_ram;
    wire enb_data_bank;
    wire [INDEX_WIDTH-1:0] addrb;

    wire [TAG_WIDTH:0] tag_way[WAY_NUM-1:0];                //读出的tag值
    wire [31:0] block_way[WAY_NUM-1:0][BLOCK_NUM-1:0];      //读出的cache line的block
    wire [31:0] block_sel_way[WAY_NUM-1:0];                 //根据offset选中的字

    assign block_sel_way[0] = block_way[0][offset];
    assign block_sel_way[1] = block_way[1][offset];
    assign block_sel_way[2] = block_way[2][offset];
    assign block_sel_way[3] = block_way[3][offset];
    //write
        //ena只有当wena为真时才为真，故省略
    wire [INDEX_WIDTH-1:0] addra;       //写地址，为index
        //tag ram
    wire [WAY_NUM-1:0] wena_tag_ram_way;
    wire [TAG_WIDTH:0] tag_ram_dina;        //tag_ram写数据
        //data bank
    wire [3:0] wena_data_bank_way[WAY_NUM-1:0][BLOCK_NUM-1:0];     //每路每个data_bank的写使能
    wire [31:0] data_bank_dina;

    //LRU & dirty bit
    reg [WAY_NUM-2:0] LRU_bit[CACHE_LINE_NUM-1:0];  //4路采用3bit作为伪LRU算法
    reg [CACHE_LINE_NUM-1:0] dirty_bits_way[WAY_NUM-1:0];


    //valid
    wire valid_way[WAY_NUM-1:0];
    assign valid_way[0] = tag_way[0][0];
    assign valid_way[1] = tag_way[1][0];
    assign valid_way[2] = tag_way[2][0];
    assign valid_way[3] = tag_way[3][0];

    //hit & miss
    wire hit, miss;
    wire [LOG2_WAY_NUM-1:0] sel;
    wire [WAY_NUM-1:0] sel_mask;

    assign sel_mask[0] = valid_way[0] & (tag_way[0][TAG_WIDTH:1] == tag); 
    assign sel_mask[1] = valid_way[1] & (tag_way[1][TAG_WIDTH:1] == tag); 
    assign sel_mask[2] = valid_way[2] & (tag_way[2][TAG_WIDTH:1] == tag); 
    assign sel_mask[3] = valid_way[3] & (tag_way[3][TAG_WIDTH:1] == tag); 

    encoder4x2 encoder0(sel_mask, sel);

    assign hit = data_en & (|sel_mask);
    assign miss = data_en & ~hit;
    
    //evict_way
    wire [LOG2_WAY_NUM-1:0] evict_way;
    wire [WAY_NUM-1:0] evict_mask;

    assign evict_way = {LRU_bit[index][0], ~LRU_bit[index][0] ? LRU_bit[index][1] : LRU_bit[index][2]};
    decoder2x4 decoder1(evict_way, evict_mask);

    //dirty
    wire dirty;
    assign dirty = evict_mask[0] & valid_way[0] & dirty_bits_way[0][index] |
                   evict_mask[1] & valid_way[1] & dirty_bits_way[1][index] |
                   evict_mask[2] & valid_way[2] & dirty_bits_way[2][index] |
                   evict_mask[3] & valid_way[3] & dirty_bits_way[3][index];
    
    //axi req
    reg read_req;       //一次读事务
    reg write_req;      //一次写事务
    reg raddr_rcv;      //读事务地址握手成功
    reg waddr_rcv;      //写事务地址握手成功
    reg wdata_rcv;      //写数据握手成功
    wire data_back;     //读事务一次数据握手成功
    wire data_go;       //写事务一次数据握手成功
    wire read_finish;   //读事务结束
    wire write_finish;  //写事务结束

    //-------------------debug-----------------
    wire cache_lw, cache_sw;
    assign cache_lw = ~no_cache & read;
    assign cache_sw = ~no_cache & write;

    wire miss_dirty;
    assign miss_dirty = data_en & miss & dirty & ~no_cache;

    wire lw_miss;
    wire sw_miss, sw_hit;
    wire lw_miss_dirty;
    wire sw_miss_dirty;

    assign sw_hit  = write & hit;
    assign lw_miss = read & miss;
    assign sw_miss = write & miss;
    assign lw_miss_dirty = read & miss & dirty;
    assign sw_miss_dirty = write & miss & dirty;

    wire not_data_en = (state==HitJudge) && ~data_en;

    wire w54;
    assign w54 = |wena_tag_ram_way && (addra==7'h54);

    //-------------------debug-----------------
//FSM
    reg [2:0] state;
    parameter IDLE = 3'b000, HitJudge = 3'b001, MissHandle=3'b011, NoCache=3'b010;

    always @(posedge clk) begin
        if(rst) begin
            state <= IDLE;
        end
        else begin
            case(state)
                IDLE        : state <= (mem_read_enE | mem_write_enE) & ~stallM ? HitJudge : IDLE;
                HitJudge    : state <= data_en & no_cache           ? NoCache :
                                       data_en & miss               ? MissHandle :
                                       mem_read_enE | mem_write_enE ? HitJudge :
                                       IDLE;
                MissHandle  : state <= ~read_req & ~write_req ? IDLE : state;
                NoCache     : state <= read & read_finish | write & write_finish ? IDLE : NoCache;
            endcase
        end
    end

//DATAPATH
    reg [31:0] saved_rdata;
    wire collisionE;
    reg collisionM;
    reg [31:0] data_wdata_r;

    assign collisionE = mem_read_enE & write & hit & (mem_addrE == data_addr);
    always@(posedge clk) begin
        data_wdata_r <= rst ? 0 : data_wdata;
        collisionM <= rst ? 0 : collisionE;
    end

    assign stall = ~(state==IDLE || state==HitJudge && hit);
    assign data_rdata = hit & ~no_cache & ~collisionM ? block_sel_way[sel]:
                        collisionM     ? data_wdata_r: saved_rdata;
//AXI
    always @(posedge clk) begin
        read_req <= (rst)            ? 1'b0 : 
                    ~no_cache && data_en && (state == HitJudge) && miss && !read_req ? 1'b1 : 
                    read & no_cache & (state == HitJudge) & ~read_req ? 1'b1 :
                    read_finish      ? 1'b0 : read_req;
        
        write_req <= (rst)              ? 1'b0 :
                     ~no_cache & data_en && (state == HitJudge) && miss && dirty && !write_req ? 1'b1 :
                     write & no_cache & (state == HitJudge) & ~read_req ? 1'b1 :
                     write_finish       ? 1'b0 : write_req;
    end
    
    always @(posedge clk) begin
        raddr_rcv <= rst             ? 1'b0 :
                    arvalid&&arready ? 1'b1 :
                    read_finish      ? 1'b0 : raddr_rcv;
        waddr_rcv <= rst             ? 1'b0 :
                    awvalid&&awready ? 1'b1 :
                    write_finish     ? 1'b0 : waddr_rcv;
        wdata_rcv <= rst                  ? 1'b0 :
                    wvalid&&wready&&wlast ? 1'b1 :
                    write_finish          ? 1'b0 : wdata_rcv;
    end

    //读事务burst传输，计数当前传递的bank的编号
    reg [OFFSET_WIDTH-3:0] cnt;  
    always @(posedge clk) begin
        cnt <= rst | no_cache | read_finish ? 1'b0 :
                data_back                   ? cnt + 1 : cnt;
    end

    //写事务burst传输，计数当前传递的bank的编号
    reg [OFFSET_WIDTH-3:0] wcnt; 
    always @(posedge clk) begin
        wcnt <= rst | no_cache | write_finish ? 1'b0 :
                data_go                       ? wcnt + 1 : wcnt;
    end

    always @(posedge clk) begin
        saved_rdata <= rst ? 32'b0 :
                      ( data_back & (cnt==offset)) | (no_cache & read_finish) ? rdata : saved_rdata;
    end

    assign data_back = raddr_rcv & (rvalid & rready);
    assign data_go   = waddr_rcv & (wvalid & wready); 
    assign read_finish = raddr_rcv & (rvalid & rready & rlast);
    assign write_finish = waddr_rcv & wdata_rcv & (bvalid & bready);

    //AXI signal
    //read
    assign araddr = ~no_cache ? {tag, index}<<OFFSET_WIDTH: data_addr; //将offset清0
    assign arlen = ~no_cache ? BLOCK_NUM-1 : 8'd0;
    assign arvalid = read_req & ~raddr_rcv;
    assign rready = raddr_rcv;
    //write
    wire [31:0] dirty_write_addr;
    assign dirty_write_addr =  //{tag, index} << OFFSET
        {(
            {TAG_WIDTH{evict_mask[0]}} & tag_way[0][TAG_WIDTH : 1]|
            {TAG_WIDTH{evict_mask[1]}} & tag_way[1][TAG_WIDTH : 1]|
            {TAG_WIDTH{evict_mask[2]}} & tag_way[2][TAG_WIDTH : 1]|
            {TAG_WIDTH{evict_mask[3]}} & tag_way[3][TAG_WIDTH : 1]
        ), index} <<OFFSET_WIDTH;


    assign awaddr = ~no_cache ? dirty_write_addr : data_addr;
    assign awlen = ~no_cache ? BLOCK_NUM-1 : 8'd0;
    assign awsize = ~no_cache ? 4'b10 :
                                data_wen==4'b1111 ? 4'b10:
                                data_wen==4'b1100 || data_wen==4'b0011 ? 4'b01: 4'b00;
    assign awvalid = write_req & ~waddr_rcv;

    assign wdata = ~no_cache ? block_way[evict_way][wcnt] : data_wdata;

    assign wstrb = ~no_cache ? 4'b1111 : data_wen;
    assign wlast = wcnt==awlen;
    assign wvalid = waddr_rcv & ~wdata_rcv;
    assign bready = waddr_rcv;

//LRU
    wire write_LRU_en;
    wire [LOG2_WAY_NUM-1:0] LRU_visit;  //记录最近访问了哪路，用于更新LRU 

    assign write_LRU_en = ~no_cache & hit & ~stallM | ~no_cache & read_finish;
    assign LRU_visit = hit ? sel : evict_way;
    integer tt;
    always @(posedge clk) begin
        if(rst) begin
            for(tt=0; tt<CACHE_LINE_NUM; tt=tt+1) begin
                LRU_bit[tt] <= 0;
            end
        end
        //更新LRU
        else begin
            if(write_LRU_en) begin
                LRU_bit[index][0] <= ~LRU_visit[1];
                LRU_bit[index][1] <= ~LRU_visit[1] ? ~LRU_visit[0] : LRU_bit[index][1];
                LRU_bit[index][2] <=  LRU_visit[1] ? ~LRU_visit[0] : LRU_bit[index][2];
            end
        end
    end

//dirty bit
    wire write_dirty_bit_en;
    wire [LOG2_WAY_NUM-1:0] write_way_sel;
    wire write_dirty_bit;   //dirty被修改成什么

    assign write_dirty_bit_en =  ~no_cache & (
                                    read & read_finish | write & hit & ~stallM |
                                    (state==MissHandle) & read_finish
                                );
    assign write_way_sel = write & hit ? sel : evict_way;
    assign write_dirty_bit = read ? 1'b0 : 1'b1;

    always @(posedge clk) begin
        if(rst) begin
            for(tt=0; tt<CACHE_LINE_NUM; tt=tt+1) begin
                dirty_bits_way[0][tt] <= 0;
                dirty_bits_way[1][tt] <= 0;
                dirty_bits_way[2][tt] <= 0;
                dirty_bits_way[3][tt] <= 0;
            end
        end
        else begin
            if(write_dirty_bit_en) begin
                case(write_way_sel)
                    2'b00: dirty_bits_way[0][index] <= write_dirty_bit;
                    2'b01: dirty_bits_way[1][index] <= write_dirty_bit;
                    2'b10: dirty_bits_way[2][index] <= write_dirty_bit;
                    2'b11: dirty_bits_way[3][index] <= write_dirty_bit;
                endcase
            end
        end
    end
//cache ram
    //read
    assign enb_tag_ram = (mem_read_enE || mem_write_enE) && ~stallM; 
    assign enb_data_bank = (mem_read_enE || mem_write_enE) && ~stallM; //#sw时，不用读取data# 改：sw遇到miss和dirty, 仍然需要读 #除非延迟一个周期写。

    assign addrb = indexE;  //read: 读tag ram和data ram; write: 读tag ram
    //write
    assign addra = index;
        //1 tag ram
    assign wena_tag_ram_way = {WAY_NUM{read_finish & ~no_cache}} & evict_mask;

    assign tag_ram_dina = {tag, 1'b1}; 

        //2 data bank
    wire [BLOCK_NUM-1:0] wena_data_bank_mask;
            //解码器
    decoder3x8 decoder0(cnt, wena_data_bank_mask);
            //写使能
    genvar i;
    generate
        for(i = 0; i< BLOCK_NUM; i=i+1) begin: wena_data_bank
            mux2 mux2_way0({4{data_back & wena_data_bank_mask[i] & evict_mask[0] & ~no_cache}}, data_wen, write & hit & (i==offset) & sel_mask[0], wena_data_bank_way[0][i]);
            mux2 mux2_way1({4{data_back & wena_data_bank_mask[i] & evict_mask[1] & ~no_cache}}, data_wen, write & hit & (i==offset) & sel_mask[1], wena_data_bank_way[1][i]);
            mux2 mux2_way2({4{data_back & wena_data_bank_mask[i] & evict_mask[2] & ~no_cache}}, data_wen, write & hit & (i==offset) & sel_mask[2], wena_data_bank_way[2][i]);
            mux2 mux2_way3({4{data_back & wena_data_bank_mask[i] & evict_mask[3] & ~no_cache}}, data_wen, write & hit & (i==offset) & sel_mask[3], wena_data_bank_way[3][i]);
        end
    endgenerate
            //写数据
    assign data_bank_dina = (write & hit) | (write & (cnt == offset)) ? data_wdata : rdata; 

    genvar j;
    generate
        for(i = 0; i < WAY_NUM; i=i+1) begin: way
            d_tag_ram tag_ram (
                .clka(clk),    // input wire clka
                .ena(wena_tag_ram_way[i]),      // input wire ena
                .wea(wena_tag_ram_way[i]),      // input wire [0 : 0] wea
                .addra(addra),  // input wire [9 : 0] addra
                .dina(tag_ram_dina),    // input wire [20 : 0] dina

                .clkb(clk),    // input wire clkb
                .enb(enb_tag_ram & ~collisionE),      // input wire enb
                .addrb(addrb),  // input wire [9 : 0] addrb
                .doutb(tag_way[i])  // output wire [20 : 0] doutb
            );
            for(j = 0; j < BLOCK_NUM; j=j+1) begin: bank
                d_data_bank data_bank (
                    .clka(clk),    // input wire clka
                    .ena(|wena_data_bank_way[i][j]),      // input wire ena
                    .wea(wena_data_bank_way[i][j]),      // input wire [3 : 0] wea
                    .addra(addra),  // input wire [9 : 0] addra
                    .dina(data_bank_dina),    // input wire [31 : 0] dina

                    .clkb(clk),    // input wire clkb
                    .enb(enb_data_bank & ~collisionE),      // input wire enb
                    .addrb(addrb),  // input wire [9 : 0] addrb
                    .doutb(block_way[i][j])  // output wire [31 : 0] doutb
                );
            end
        end
    endgenerate
endmodule