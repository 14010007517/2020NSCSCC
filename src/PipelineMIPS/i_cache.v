module i_cache (
    input wire clk, rst,
    //datapath
    input wire inst_en,
    input wire [31:0] pc_next,
    input wire [31:0] pcF,
    output wire [31:0] inst_rdata,
    output wire stall,
    output wire hit,
    input wire stallF,

    //arbitrater
    output wire [31:0] araddr,
    output wire [7:0] arlen,
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
    localparam BLOCK_NUM= 1<<(OFFSET_WIDTH-2);
    // parameter TAG_WIDTH = 20, INDEX_WIDTH = 10, OFFSET_WIDTH = 2;
    
    wire [TAG_WIDTH-1    : 0] tag;
    wire [INDEX_WIDTH-1  : 0] index, index_next;
    wire [OFFSET_WIDTH-3 : 0] offset;   //字偏移

    assign tag        = pcF     [31                         : INDEX_WIDTH+OFFSET_WIDTH ];
    assign index      = pcF     [INDEX_WIDTH+OFFSET_WIDTH-1 : OFFSET_WIDTH             ];
    assign index_next = pc_next [INDEX_WIDTH+OFFSET_WIDTH-1 : OFFSET_WIDTH             ];
    assign offset     = pcF     [OFFSET_WIDTH-1             : 2                        ];

    //cache ram
    //read
    wire enb;       //读使能，作用在tag_ram和data_bank，way0和way1上
    wire [INDEX_WIDTH-1:0] addrb;     //读地址，除了rst后的开始阶段特殊，其余都采用index_next

    wire [TAG_WIDTH:0] tag_way0, tag_way1;      //读出的tag值
    wire [31:0] block_way0[BLOCK_NUM-1:0], block_way1[BLOCK_NUM-1:0];   //读出的cache line的block
    wire [31:0] block_sel_way0, block_sel_way1; //根据offset选中的字
    assign block_sel_way0 = block_way0[offset];
    assign block_sel_way1 = block_way1[offset];
    //write
        //ena只有当wena为真时才为真，故省略
    wire [INDEX_WIDTH-1:0] addra;       //写地址，为index
        //tag ram
    wire wena_tag_ram_way0, wena_tag_ram_way1;
    wire [TAG_WIDTH:0] tag_ram_dina;        //tag_ram写数据
        //data bank
    wire [BLOCK_NUM-1:0] wena_data_bank_way0;     //每个data_bank的写使能
    wire [BLOCK_NUM-1:0] wena_data_bank_way1;     //每个data_bank的写使能
    wire [31:0] data_bank_dina;             //data_bank的写数据（共用一个数据，通过改变使能以达到不同bank写不同数据的效果）
    
    //valid
    wire valid_way0, valid_way1;
    assign valid_way0 = tag_way0[0];
    assign valid_way1 = tag_way1[0];
    //hit & miss
    wire hit, miss, sel;
    assign sel = (tag_way1[TAG_WIDTH:1] == tag) ? 1'b1 : 1'b0;
    assign hit = valid_way0 && (tag_way0[TAG_WIDTH:1] == tag) ||
                 valid_way1 && (tag_way1[TAG_WIDTH:1] == tag);
    assign miss = ~hit;

    //evict
    wire evict_way;
    assign evict_way = LRU_bit[index];

    //load memory axi
    reg read_req;       //一次读事务
    reg addr_rcv;       //地址握手成功
    wire data_back;     //一次数据握手成功
    wire read_finish;   //读事务结束


    //-------------debug-------------
    wire [19:0] ram_tag0, ram_tag1;
    assign ram_tag0 = tag_way0[20:1];
    assign ram_tag1 = tag_way1[20:1];

    //计数

    //-------------debug-------------

//FSM
    reg [1:0] state;
    parameter IDLE = 2'b00, HitJudge = 2'b01, LoadMemory = 2'b11;
    always @(posedge clk) begin
        if(rst) begin
            state <= IDLE;
        end
        else begin
            case(state)
                IDLE        : state <= ~stallF ? HitJudge : IDLE;
                HitJudge    : state <= inst_en & miss ? LoadMemory : HitJudge;
                LoadMemory  : state <= read_finish & ~stallF ? HitJudge: 
                                       read_finish & stallF ? IDLE : state;
            endcase
        end
    end

//DATAPATH
    reg [31:0] saved_rdata;
    assign stall = ~(state==IDLE || (state==HitJudge && hit) || (state==LoadMemory) && read_finish);
    assign inst_rdata = hit ? (sel ? block_sel_way0 : block_sel_way1) :
                        saved_rdata;

//AXI
    always @(posedge clk) begin
        read_req <= (rst)               ? 1'b0 :
                    inst_en & (state == HitJudge) & miss & ~read_req ? 1'b1 :
                    read_finish         ? 1'b0 : read_req;
    end
    
    always @(posedge clk) begin
        addr_rcv <= rst              ? 1'b0 :
                    arvalid&&arready ? 1'b1 :
                    read_finish      ? 1'b0 : addr_rcv;
    end

    reg [2:0] cnt;  //burst传输，计数当前传递的bank的编号
    always @(posedge clk) begin
        cnt <= rst       ? 1'b0 :
               data_back ? cnt + 1 : cnt;
    end

    always @(posedge clk) begin
        if(cnt==offset)
            saved_rdata <= rdata;
    end

    assign data_back = addr_rcv & (rvalid & rready);
    assign read_finish = addr_rcv & (rvalid & rready & rlast);

    //AXI signal
    assign araddr = pcF;
    assign arlen = 8'd7;
    assign arvalid = read_req & ~addr_rcv;
    assign rready = addr_rcv;

//LRU
    wire write_LRU_en;
    assign write_LRU_en = hit | read_finish;
    
    reg [(1<<INDEX_WIDTH)-1:0] LRU_bit;
    always @(posedge clk) begin
        if(rst) begin
            LRU_bit <= 0;
        end
        //更新LRU
        else begin
            if(hit)  
                LRU_bit[index] = ~sel;  //0-> 下次替换way0, 1-> 下次替换way1。下次替换未命中的一路
            else if(read_finish)
                LRU_bit[index] = ~evict_way;
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
    assign wena_tag_ram_way0 = read_finish && ~evict_way;
    assign wena_tag_ram_way1 = read_finish && evict_way;

    assign tag_ram_dina = {tag, 1'b1};

        //data bank
    wire [BLOCK_NUM-1:0] wena_data_bank_mask;
        //解码器
    decoder3x8 decoder0(cnt, wena_data_bank_mask);
    
    assign wena_data_bank_way0 = wena_data_bank_mask & {BLOCK_NUM{data_back & ~evict_way}};
    assign wena_data_bank_way1 = wena_data_bank_mask & {BLOCK_NUM{data_back & evict_way}};

    assign data_bank_dina = rdata;

    d_tag_ram i_tag_ram_way0 (
        .clka(clk),    // input wire clka
        .ena(wena_tag_ram_way0),      // input wire ena
        .wea(wena_tag_ram_way0),      // input wire [0 : 0] wea
        .addra(addra),  // input wire [9 : 0] addra
        .dina(tag_ram_dina),    // input wire [20 : 0] dina
        .clkb(clk),    // input wire clkb
        .enb(enb),      // input wire enb
        .addrb(addrb),  // input wire [9 : 0] addrb
        .doutb(tag_way0)  // output wire [20 : 0] doutb
    );

    d_tag_ram i_tag_ram_way1 (
        .clka(clk),    // input wire clka
        .ena(wena_tag_ram_way1),      // input wire ena
        .wea(wena_tag_ram_way1),      // input wire [0 : 0] wea
        .addra(addra),  // input wire [9 : 0] addra
        .dina(tag_ram_dina),    // input wire [20 : 0] dina
        .clkb(clk),    // input wire clkb
        .enb(enb),      // input wire enb
        .addrb(addrb),  // input wire [9 : 0] addrb
        .doutb(tag_way1)  // output wire [20 : 0] doutb
    );

    genvar i;
    generate
        //way 0
        for(i = 0; i< BLOCK_NUM; i=i+1) begin: i_data_bank_way0
            d_data_bank data_bank (
                .clka(clk),    // input wire clka
                .ena(wena_data_bank_way0[i]),      // input wire ena
                .wea({4{wena_data_bank_way0[i]}}),      // input wire [3 : 0] wea
                .addra(addra),  // input wire [9 : 0] addra
                .dina(data_bank_dina),    // input wire [31 : 0] dina
                .clkb(clk),    // input wire clkb
                .enb(enb),      // input wire enb
                .addrb(addrb),  // input wire [9 : 0] addrb
                .doutb(block_way0[i])  // output wire [31 : 0] doutb
            );
        end
        //way 1
        for(i = 0; i< BLOCK_NUM; i=i+1) begin: i_data_bank_way1
            d_data_bank data_bank (
                .clka(clk),    // input wire clka
                .ena(wena_data_bank_way1[i]),      // input wire ena
                .wea({4{wena_data_bank_way1[i]}}),      // input wire [3 : 0] wea
                .addra(addra),  // input wire [9 : 0] addra
                .dina(data_bank_dina),    // input wire [31 : 0] dina
                .clkb(clk),    // input wire clkb
                .enb(enb),      // input wire enb
                .addrb(addrb),  // input wire [9 : 0] addrb
                .doutb(block_way1[i])  // output wire [31 : 0] doutb
            );
        end
    endgenerate
endmodule