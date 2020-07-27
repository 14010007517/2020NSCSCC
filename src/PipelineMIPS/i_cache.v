module i_cache (
    input wire clk, rst,
    //datapath
    input wire inst_en,
    input wire [31:0] pc_next,
    input wire [31:0] pcF,
    output wire [31:0] inst_rdata,
    output wire stall,

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
    //cache configure
    parameter TAG_WIDTH = 20, INDEX_WIDTH = 10, OFFSET_WIDTH = 2;
    
    wire [TAG_WIDTH-1    : 0] tag;
    wire [INDEX_WIDTH-1  : 0] index;
    wire [OFFSET_WIDTH-1 : 0] offset;

    assign tag      = pcF[31                         : INDEX_WIDTH+OFFSET_WIDTH ];
    assign index    = pcF[INDEX_WIDTH+OFFSET_WIDTH-1 : OFFSET_WIDTH             ];
    assign offset   = pcF[OFFSET_WIDTH-1             : 0                        ];

    //cache ram
    wire [20:0] tag_way0, tag_way1;
    wire [31:0] data_bank0_way0, data_bank0_way1;

    wire en_way0, en_way1;
    wire wen_way0, wen_way1;
    //hit & miss
    wire hit, miss, sel;

    //load memory axi
    reg read_req;       //一次读事务
    reg addr_rcv;       //地址握手成功
    wire read_finish;   //读事务结束

    //LRU
    reg [(1<<INDEX_WIDTH)-1:0] LRU_bit;
    always @(posedge clk) begin
        if(rst) begin
            LRU_bit <= 0;
        end
        //更新LRU
        else if(hit) begin
            LRU_bit[index] = ~sel;  //0-> 下次替换way0, 1-> 下次替换way1。下次替换未命中的一路
        end
    end

    //hit & miss
    //-------------debug-------------
    wire [19:0] ram_tag0, ram_tag1;
    assign ram_tag0 = tag_way0[20:1];
    assign ram_tag1 = tag_way1[20:1];
    //-------------debug-------------

    assign sel = (tag_way1[20:1] == tag) ? 1'b1 : 1'b0;
    assign hit = tag_way0[0] && (tag_way0[20:1] == tag) ||
                 tag_way1[0] && (tag_way1[20:1] == tag);
    assign miss = ~hit;

    //FSM
    reg [1:0] state;
    parameter IDLE = 2'b00, LoadMemory = 2'b01, Refill = 2'b11;
    always @(posedge clk) begin
        if(rst) begin
            state <= IDLE;
        end
        else begin
            case(state)
                IDLE        : state <= inst_en & miss ? LoadMemory : state;
                LoadMemory  : state <= read_finish ? Refill : state;
                Refill      : state <= IDLE;
            endcase
        end
    end

    //refill cache
    wire evict_way;
    assign evict_way = LRU_bit[index];
    assign en_way0 = state == IDLE || wen_way0;
    assign en_way1 = state == IDLE || wen_way1;

    assign wen_way0 = (state == Refill) && ~evict_way;
    assign wen_way1 = (state == Refill) && evict_way;

    //DATAPATH
    // assign stall = read_req & ~read_finish;
    assign stall = |state;
    assign inst_rdata = hit ? (sel ? data_bank0_way1 : data_bank0_way0) :
                        rdata;

    //load memory axi
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

    //AXI
    assign araddr = pcF;
    assign arlen = 8'b0;
    assign arvalid = read_req & ~addr_rcv;
    assign rready = addr_rcv;


    //ram
    wire [9:0] next_index;
    wire [9:0] addra;
    assign next_index = pc_next[INDEX_WIDTH+OFFSET_WIDTH-1 : OFFSET_WIDTH];
    assign addra = state==Refill ? index : next_index;

    i_tag_ram i_tag_ram_way0 (
        .clka(clk),    // input wire clka
        .ena(en_way0),      // input wire ena
        .wea(wen_way0),      // input wire [0 : 0] wea
        .addra(addra),  // input wire [9 : 0] addra
        .dina({tag, 1'b1}),    // input wire [20 : 0] dina
        .douta(tag_way0)  // output wire [20 : 0] douta
    );

    i_tag_ram i_tag_ram_way1 (
        .clka(clk),    // input wire clka
        .ena(en_way1),      // input wire ena
        .wea(wen_way1),      // input wire [0 : 0] wea
        .addra(addra),  // input wire [9 : 0] addra
        .dina({tag, 1'b1}),    // input wire [20 : 0] dina
        .douta(tag_way1)  // output wire [20 : 0] douta
    );

    data_bank i_data_bank0_way0 (
        .clka(clk),    // input wire clka
        .ena(en_way0),      // input wire ena
        .wea(wen_way0),      // input wire [0 : 0] wea
        .addra(addra),  // input wire [9 : 0] addra
        .dina(rdata),    // input wire [31 : 0] dina
        .douta(data_bank0_way0)  // output wire [31 : 0] douta
    );

    data_bank i_data_bank0_way1 (
        .clka(clk),    // input wire clka
        .ena(en_way1),      // input wire ena
        .wea(wen_way1),      // input wire [0 : 0] wea
        .addra(addra),  // input wire [9 : 0] addra
        .dina(rdata),    // input wire [31 : 0] dina
        .douta(data_bank0_way1)  // output wire [31 : 0] douta
    );

endmodule