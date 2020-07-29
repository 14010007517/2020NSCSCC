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
    parameter TAG_WIDTH = 20, INDEX_WIDTH = 10, OFFSET_WIDTH = 2;
    
    wire [TAG_WIDTH-1    : 0] tag;
    wire [INDEX_WIDTH-1  : 0] index, index_next;
    wire [OFFSET_WIDTH-1 : 0] offset;

    assign tag        = pcF     [31                         : INDEX_WIDTH+OFFSET_WIDTH ];
    assign index      = pcF     [INDEX_WIDTH+OFFSET_WIDTH-1 : OFFSET_WIDTH             ];
    assign index_next = pc_next [INDEX_WIDTH+OFFSET_WIDTH-1 : OFFSET_WIDTH             ];
    assign offset     = pcF     [OFFSET_WIDTH-1             : 0                        ];

    //cache ram
    //read
    wire enb;       //读使能，作用在tag_ram和data_bank，way0和way1上
    wire [INDEX_WIDTH-1:0] addrb;     //读地址，除了rst后的开始阶段特殊，其余都采用index_next
    wire [TAG_WIDTH:0] tag_way0, tag_way1;
    wire [31:0] data_bank0_way0, data_bank0_way1;

    //write
    wire wena_way0, wena_way1;          //写使能，作用在tag_ram和data_bank上，way0, way1需区分
    wire ena_way0, ena_way1;
    wire [INDEX_WIDTH-1:0] addra;       //写地址，为index
    wire [TAG_WIDTH:0] tag_ram_dina;    //写数据
    wire [31:0] data_bank0_dina;        //写数据

    //hit & miss
    wire hit, miss, sel;
    assign sel = (tag_way1[TAG_WIDTH:1] == tag) ? 1'b1 : 1'b0;
    assign hit = tag_way0[0] && (tag_way0[TAG_WIDTH:1] == tag) ||
                 tag_way1[0] && (tag_way1[TAG_WIDTH:1] == tag);
    assign miss = ~hit;

    //evict
    wire evict_way;
    assign evict_way = LRU_bit[index];

    //load memory axi
    reg read_req;       //一次读事务
    reg addr_rcv;       //地址握手成功
    wire read_finish;   //读事务结束

    //-------------debug-------------
    wire [19:0] ram_tag0, ram_tag1;
    assign ram_tag0 = tag_way0[20:1];
    assign ram_tag1 = tag_way1[20:1];

    //计数
    reg [31:0] total_instr, hit_num;
    always @(posedge clk) begin
        if(rst) begin
            total_instr <= 32'b0;
            hit_num <= 32'b0;
        end
        else begin
            if(state==LoadMemory) begin
                total_instr <= total_instr + 1;
            end
            if(state==HitJudge && hit) begin
                hit_num <= hit_num + 1;
            end
        end
    end
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
                IDLE        : state <= HitJudge;
                HitJudge    : state <= inst_en & miss ? LoadMemory : HitJudge;
                LoadMemory  : state <= read_finish ? IDLE : state;
            endcase
        end
    end

//DATAPATH
    assign stall = state==IDLE || (state==HitJudge && hit);
    assign inst_rdata = hit ? (sel ? data_bank0_way1 : data_bank0_way0) :
                        rdata;

//AXI
    always @(posedge clk) begin
        read_req <= (rst)               ? 1'b0 :
                    inst_en & miss & ~read_req ? 1'b1 :
                    read_finish         ? 1'b0 : read_req;
    end
    
    always @(posedge clk) begin
        addr_rcv <= rst              ? 1'b0 :
                    arvalid&&arready ? 1'b1 :
                    read_finish      ? 1'b0 : addr_rcv;
    end

    assign read_finish = addr_rcv & (rvalid & rready & rlast);

    //AXI signal
    assign araddr = pcF;
    assign arlen = 8'b0;
    assign arvalid = read_req & ~addr_rcv;
    assign rready = addr_rcv;

//LRU
    reg [(1<<INDEX_WIDTH)-1:0] LRU_bit;
    always @(posedge clk) begin
        if(rst) begin
            LRU_bit <= 0;
        end
        //更新LRU
        else begin
            if(hit) 
                LRU_bit[index] = ~sel;  //0-> 下次替换way0, 1-> 下次替换way1。下次替换未命中的一路
            else
                LRU_bit[index] = ~evict_way;
        end
    end

//cache ram
    //read
    wire enb;       //读使能，作用在tag_ram和data_bank，way0和way1上
    wire [INDEX_WIDTH-1:0] addrb;     //读地址，除了rst后的开始阶段特殊，其余都采用index_next

    assign enb = (state == IDLE);

    reg before_start_clk;  //标识rst结束后的第一个上升沿之前
    always @(posedge clk) begin
        before_start_clk <= rst ? 1'b1 : 1'b0;
    end
    assign addrb = before_start_clk ? index : index_next;

    //write
    wire wena_way0, wena_way1;          //写使能，作用在tag_ram和data_bank上，way0, way1需区分
    wire ena_way0, ena_way1;
    wire [INDEX_WIDTH-1:0] addra;       //写地址，为index
    wire [TAG_WIDTH:0] tag_ram_dina;    //写数据
    wire [31:0] data_bank0_dina;        //写数据

    assign wena_way0 = read_finish && ~evict_way;
    assign wena_way1 = read_finish && evict_way;

    assign ena_way0 = wena_way0;
    assign ena_way1 = wena_way1;

    assign addra = index;
    assign tag_ram_dina = {tag, 1'b1};
    assign data_bank0_dina = rdata;

    d_tag_ram i_tag_ram_way0 (
        .clka(clk),    // input wire clka
        .ena(ena_way0),      // input wire ena
        .wea(wena_way0),      // input wire [0 : 0] wea
        .addra(addra),  // input wire [9 : 0] addra
        .dina(tag_ram_dina),    // input wire [20 : 0] dina
        .clkb(clk),    // input wire clkb
        .enb(enb),      // input wire enb
        .addrb(addrb),  // input wire [9 : 0] addrb
        .doutb(tag_way0)  // output wire [20 : 0] doutb
    );

    d_tag_ram i_tag_ram_way1 (
        .clka(clk),    // input wire clka
        .ena(ena_way1),      // input wire ena
        .wea(wena_way1),      // input wire [0 : 0] wea
        .addra(addra),  // input wire [9 : 0] addra
        .dina(tag_ram_dina),    // input wire [20 : 0] dina
        .clkb(clk),    // input wire clkb
        .enb(enb),      // input wire enb
        .addrb(addrb),  // input wire [9 : 0] addrb
        .doutb(tag_way1)  // output wire [20 : 0] doutb
    );

    d_data_bank i_data_bank0_way0 (
        .clka(clk),    // input wire clka
        .ena(ena_way0),      // input wire ena
        .wea(wena_way0),      // input wire [3 : 0] wea
        .addra(addra),  // input wire [9 : 0] addra
        .dina(data_bank0_dina),    // input wire [31 : 0] dina
        .clkb(clk),    // input wire clkb
        .enb(enb),      // input wire enb
        .addrb(addrb),  // input wire [9 : 0] addrb
        .doutb(data_bank0_way0)  // output wire [31 : 0] doutb
    );

    d_data_bank i_data_bank0_way1 (
        .clka(clk),    // input wire clka
        .ena(ena_way1),      // input wire ena
        .wea(wena_way1),      // input wire [3 : 0] wea
        .addra(addra),  // input wire [9 : 0] addra
        .dina(data_bank0_dina),    // input wire [31 : 0] dina
        .clkb(clk),    // input wire clkb
        .enb(enb),      // input wire enb
        .addrb(addrb),  // input wire [9 : 0] addrb
        .doutb(data_bank0_way1)  // output wire [31 : 0] doutb
    );

endmodule