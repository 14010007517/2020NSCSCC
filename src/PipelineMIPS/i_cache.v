module i_cache (
    input wire clk, rst,
    
    //tlb
    input wire no_cache,
    //datapath
    input wire inst_en,
    input wire [31:0] inst_vaddr,
    // input wire [31:0] inst_paddr,
    input wire [19:0] inst_pfn,
    output wire [31:0] inst_rdata,
    input wire [31:0] pc_next,
    output wire stall,
    input wire stallF,

    //arbitrater
    output wire [31:0] araddr,
    output wire [3:0] arlen,
    output wire arvalid,
    input wire arready,

    input wire [31:0] rdata,
    input wire rlast,
    input wire rvalid,
    output wire rready
);

//变量声明
    //cache configure
    parameter TAG_WIDTH = 20, INDEX_WIDTH = 7, OFFSET_WIDTH = 5;    //[WARNING]: OFFSET_WIDTH不能为2
    parameter WAY_NUM = 4, LOG2_WAY_NUM = 2;
    localparam BLOCK_NUM= 1<<(OFFSET_WIDTH-2);
    localparam CACHE_LINE_NUM = 1<<INDEX_WIDTH;

    // parameter TAG_WIDTH = 20, INDEX_WIDTH = 10, OFFSET_WIDTH = 2;
    
    wire [TAG_WIDTH-1    : 0] tag;
    wire [INDEX_WIDTH-1  : 0] index, index_next;
    wire [OFFSET_WIDTH-3 : 0] offset;   //字偏移

    wire [31:0] inst_paddr;
    assign inst_paddr = {inst_pfn, index, offset};
    
    assign tag        = inst_pfn;
    assign index      = inst_vaddr[INDEX_WIDTH+OFFSET_WIDTH-1 : OFFSET_WIDTH             ];
    assign index_next = pc_next   [INDEX_WIDTH+OFFSET_WIDTH-1 : OFFSET_WIDTH             ];
    assign offset     = inst_vaddr[OFFSET_WIDTH-1             : 2                        ];

    //cache ram
    //read
    wire enb;       //读使能，作用在tag_ram和data_bank，way0和way1上
    wire [INDEX_WIDTH-1:0] addrb;     //读地址，除了rst后的开始阶段特殊，其余都采用index_next

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
    wire [BLOCK_NUM-1:0] wena_data_bank_way[WAY_NUM-1:0];     //每路每个data_bank的写使能
    wire [31:0] data_bank_dina;             //data_bank的写数据（共用一个数据，通过改变使能以达到不同bank写不同数据的效果）

    //LRU 
    reg [WAY_NUM-2:0] LRU_bit[CACHE_LINE_NUM-1:0];  //4路采用3bit作为伪LRU算法

    //valid reg
    reg [CACHE_LINE_NUM-1:0] valid_bits_way[WAY_NUM-1:0];
    
    //valid
    wire [WAY_NUM-1:0]valid_way;
    assign valid_way[0] =valid_bits_way[0][index];
    assign valid_way[1] =valid_bits_way[1][index];
    assign valid_way[2] =valid_bits_way[2][index];
    assign valid_way[3] =valid_bits_way[3][index];

    //sel & hit & miss
    wire hit, miss;
    wire [LOG2_WAY_NUM-1:0] sel; //改变WAY_NUM需同时改变
    wire [WAY_NUM-1:0] sel_mask;

    assign sel_mask[0] = valid_way[0] & (tag_way[0][TAG_WIDTH:1] == tag); 
    assign sel_mask[1] = valid_way[1] & (tag_way[1][TAG_WIDTH:1] == tag); 
    assign sel_mask[2] = valid_way[2] & (tag_way[2][TAG_WIDTH:1] == tag); 
    assign sel_mask[3] = valid_way[3] & (tag_way[3][TAG_WIDTH:1] == tag); 

    encoder4x2 encoder0(sel_mask, sel);

    assign hit = inst_en & (|sel_mask);
    assign miss = inst_en & ~hit;

    //evict
    wire [LOG2_WAY_NUM-1:0] evict_way;   //改变WAY_NUM需同时改变
    wire [WAY_NUM-1:0] evict_mask;

    assign evict_way = {LRU_bit[index][0], ~LRU_bit[index][0] ? LRU_bit[index][1] : LRU_bit[index][2]};
    decoder2x4 decoder1(evict_way, evict_mask);

    //AXI req
    reg read_req;       //一次读事务
    reg addr_rcv;       //地址握手成功
    wire data_back;     //一次数据握手成功
    wire read_finish;   //读事务结束


    //-------------debug-------------
    //-------------debug-------------

//FSM
    reg [1:0] state;
    parameter IDLE = 2'b00, HitJudge = 2'b01, LoadMemory = 2'b11, NoCache=2'b10;;
    always @(posedge clk) begin
        if(rst) begin
            state <= IDLE;
        end
        else begin
            case(state)
                IDLE        : state <= ~stallF ? HitJudge : IDLE;
                HitJudge    : state <= inst_en & no_cache ? NoCache:
                                       inst_en & miss     ? LoadMemory :
                                       ~stallF            ? HitJudge : IDLE;    //命中->HitJudge, 因div等其它因素而暂停->IDLE
                LoadMemory  : state <= read_finish ? IDLE : state;
                NoCache     : state <= read_finish ? IDLE : NoCache;
            endcase
        end
    end

//DATAPATH
    reg [31:0] saved_rdata;
    assign stall = ~(state==IDLE || (state==HitJudge) && hit && ~no_cache || ~inst_en);
    assign inst_rdata = ~inst_en ? 32'b0:
                        hit & ~no_cache ? block_sel_way[sel] : saved_rdata;

//AXI
    always @(posedge clk) begin
        read_req <= (rst)               ? 1'b0 :
                    inst_en & (state == HitJudge) & miss ? 1'b1 :
                    inst_en & no_cache & (state == HitJudge) ? 1'b1 :
                    read_finish         ? 1'b0 : read_req;
    end
    
    always @(posedge clk) begin
        addr_rcv <= rst              ? 1'b0 :
                    arvalid&&arready ? 1'b1 :
                    read_finish      ? 1'b0 : addr_rcv;
    end

    reg [OFFSET_WIDTH-3:0] cnt;  //burst传输，计数当前传递的bank的编号
    always @(posedge clk) begin
        cnt <= rst |read_finish|no_cache ? 1'b0 :
               data_back        ? cnt + 1 : cnt;
    end

    always @(posedge clk) begin
        saved_rdata <= rst                     ? 32'b0 :
                       (data_back & (cnt==offset) & ~no_cache) | (no_cache & read_finish) ? rdata : saved_rdata;
    end

    assign data_back = addr_rcv & (rvalid & rready);
    assign read_finish = addr_rcv & (rvalid & rready & rlast);

    //AXI signal
    assign araddr = ~no_cache ? {tag, index}<<OFFSET_WIDTH : inst_paddr; //将offset清0
    assign arlen = ~no_cache ? BLOCK_NUM-1 : 4'd0;
    assign arvalid = read_req & ~addr_rcv;
    assign rready = addr_rcv;

//LRU
    wire write_LRU_en;
    wire [LOG2_WAY_NUM-1:0] LRU_visit;  //记录最近访问了哪路，用于更新LRU 

    assign write_LRU_en = ~no_cache & hit | ~no_cache & read_finish;
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

//valid bit
    always @(posedge clk) begin
        if(rst) begin
            for(tt=0; tt<CACHE_LINE_NUM; tt=tt+1) begin
                valid_bits_way[0][tt] <= 0;
                valid_bits_way[1][tt] <= 0;
                valid_bits_way[2][tt] <= 0;
                valid_bits_way[3][tt] <= 0;
            end
        end
        else begin
            valid_bits_way[0][index] <= wena_tag_ram_way[0] ? 1'b1 : valid_bits_way[0][index];
            valid_bits_way[1][index] <= wena_tag_ram_way[1] ? 1'b1 : valid_bits_way[1][index];
            valid_bits_way[2][index] <= wena_tag_ram_way[2] ? 1'b1 : valid_bits_way[2][index];
            valid_bits_way[3][index] <= wena_tag_ram_way[3] ? 1'b1 : valid_bits_way[3][index];
        end
    end

//cache ram
    //read
    assign enb = ~stallF;

    reg before_start_clk;  //标识rst结束后的第一个上升沿之前
    always @(posedge clk) begin
        before_start_clk <= rst ? 1'b1 : 1'b0;
    end
    assign addrb = before_start_clk ? index : index_next;

    //write
    assign addra = index;
        //tag ram
    assign wena_tag_ram_way = {WAY_NUM{read_finish & ~no_cache}} & evict_mask;

    assign tag_ram_dina = {tag, 1'b1};

        //data bank
    wire [BLOCK_NUM-1:0] wena_data_bank_mask;
        //解码器
    decoder3x8 decoder0(cnt, wena_data_bank_mask);
    
    assign wena_data_bank_way[0] = wena_data_bank_mask & {BLOCK_NUM{data_back & evict_mask[0] & ~no_cache}};
    assign wena_data_bank_way[1] = wena_data_bank_mask & {BLOCK_NUM{data_back & evict_mask[1] & ~no_cache}};
    assign wena_data_bank_way[2] = wena_data_bank_mask & {BLOCK_NUM{data_back & evict_mask[2] & ~no_cache}};
    assign wena_data_bank_way[3] = wena_data_bank_mask & {BLOCK_NUM{data_back & evict_mask[3] & ~no_cache}};

    assign data_bank_dina = rdata;

    genvar i, j;
    generate
        for(i = 0; i < WAY_NUM; i=i+1) begin: way
            i_tag_ram tag_ram (
                .clka(clk),    // input wire clka
                .ena(wena_tag_ram_way[i] & ~no_cache),      // input wire ena
                .wea(wena_tag_ram_way[i]),      // input wire [0 : 0] wea
                .addra(addra),  // input wire [9 : 0] addra
                .dina(tag_ram_dina),    // input wire [20 : 0] dina
                .clkb(clk),    // input wire clkb
                .enb(enb),      // input wire enb
                .addrb(addrb),  // input wire [9 : 0] addrb
                .doutb(tag_way[i])  // output wire [20 : 0] doutb
            );
            for(j = 0; j < BLOCK_NUM; j=j+1) begin: bank
                i_data_bank data_bank (
                    .clka(clk),    // input wire clka
                    .ena(wena_data_bank_way[i][j] & ~no_cache),      // input wire ena
                    .wea({4{wena_data_bank_way[i][j]}}),      // input wire [3 : 0] wea
                    .addra(addra),  // input wire [9 : 0] addra
                    .dina(data_bank_dina),    // input wire [31 : 0] dina
                    .clkb(clk),    // input wire clkb
                    .enb(enb),      // input wire enb
                    .addrb(addrb),  // input wire [9 : 0] addrb
                    .doutb(block_way[i][j])  // output wire [31 : 0] doutb
                );
            end
        end
    endgenerate
endmodule