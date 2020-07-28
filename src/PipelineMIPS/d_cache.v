module d_cache (
    input wire clk, rst,
    //datapath
    input wire data_en,
    input wire [31:0] data_addr,
    output wire [31:0] data_rdata,
    input wire [3:0] data_wen,
    input wire [31:0] data_wdata,
    output wire stall,
    output wire hit,
    input wire mem_addrE,
    input wire mem_read_enE,
    input wire mem_write_enE,

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
    parameter TAG_WIDTH = 20, INDEX_WIDTH = 10, OFFSET_WIDTH = 2;
    
    wire [TAG_WIDTH-1    : 0] tag;
    wire [INDEX_WIDTH-1  : 0] index, indexE;
    wire [OFFSET_WIDTH-1 : 0] offset;

    assign tag      = data_addr[31                         : INDEX_WIDTH+OFFSET_WIDTH ];
    assign index    = data_addr[INDEX_WIDTH+OFFSET_WIDTH-1 : OFFSET_WIDTH             ];    
    assign indexE   = mem_addrE[INDEX_WIDTH+OFFSET_WIDTH-1 : OFFSET_WIDTH             ];
    assign offset   = data_addr[OFFSET_WIDTH-1             : 0                        ];

    //read
    wire read, write;
    assign read = data_en & ~(|data_wen);
    assign write = data_en & |data_wen;

    //cache ram
    wire [TAG_WIDTH:0] tag_way0, tag_way1;
    wire [31:0] data_bank0_way0, data_bank0_way1;

    //ram read
    wire enb_tag_ram;
    wire enb_data_bank;
    wire enb_data_way0, enb_data_way1;
    wire [INDEX_WIDTH-1:0] addrb;

    //ram write
    wire ena_way0, ena_way1
    wire wena_way0, wena_way1;  //当read miss | write时写; 当write hit时，可以只写data_bank
    wire [INDEX_WIDTH-1:0] addra;

    //axi req
    reg read_req;       //一次读事务
    reg write_req;      //一次写事务
    reg raddr_rcv;      //读事务地址握手成功
    reg waddr_rcv;      //写事务地址握手成功
    reg wdata_rcv;      //写数据握手成功
    wire read_finish;   //读事务结束
    wire write_finish;  //写事务结束

    //hit & miss
    wire hit, miss, sel;
    assign sel = (tag_way1[TAG_WIDTH:1] == tag) ? 1'b1 : 1'b0;
    assign hit = tag_way0[0] && (tag_way0[TAG_WIDTH:1] == tag) ||
                 tag_way1[0] && (tag_way1[TAG_WIDTH:1] == tag);
    
    //evict_way
    wire evict_way;
    assign evict_way = LRU_bit[index];

    //dirty
    wire dirty;
    assign dirty = evict_way ? dirty_bits_way1[index] : dirty_bits_way0[index];

//FSM
    reg [2:0] state;
    parameter IDLE = 3'b000, MissHandle=3'b001 , HitJudge = 3'b011, ReadFinish=3'b010, WriteFinish=3'b110;
    always @(posedge clk) begin
        if(rst) begin
            state <= IDLE;
        end
        else begin
            case(state)
                IDLE        : state <= HitJudge;
                HitJudge    : miss ? MissHandle : IDLE;
                MissHandle : ~read_req & ~write_req ? IDLE : state;
            endcase
        end
    end

//DATAPATH
    assign stall = state==MissHandle || (state==HitJudge && miss);
    assign data_rdata = hit ? (sel ? data_bank0_way1 : data_bank0_way0) :
                        rdata;

//AXI
    always @(posedge clk) begin
        read_req <= (rst)            ? 1'b0 :
                    (state == HitJudge) && miss && !read_req ? 1'b1 :
                    read_finish      ? 1'b0 : read_req;
        
        write_req <= (rst)              ? 1'b0 :
                     (state == HitJudge) && miss && dirty && !write_req ? 1'b1 :
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

    assign read_finish = raddr_rcv & (rvalid & rready & rlast);
    assign write_finish = waddr_rcv & wdata_rcv & (bvalid & bready);

    //AXI signal
    //read
    assign araddr = data_addr;
    assign arlen = 8'b0;
    assign arvalid = read_req & ~raddr_rcv;
    assign rready = raddr_rcv;
    //write
    assign awaddr = data_addr;
    assign awlen = 8'b0;
    assign awsize = data_wen==4'b1111 ? 4'b10 :
                    data_wen==4'b0011 || data_wen==4'b1100 ? 4'b01 : 4'b00;
    assign awvalid = write_req & ~waddr_rcv;

    assign wdata = data_wdata;
    assign wstrb = data_wen;
    assign wlast = 1'b1;
    assign wvalid = write_req & ~wdata_rcv;
    assign bready = waddr_rcv & wdata_rcv;

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

//dirty bit
    reg [(1<<INDEX_WIDTH)-1:0] dirty_bits_way0, dirty_bits_way1;
    always @(posedge clk) begin
        if(rst) begin
            dirty_bits_way0 <= 0;
            dirty_bits_way1 <= 0;
        end
        else begin
            if(read_finish) begin
                if(~evict_way) begin
                    dirty_bits_way0[index] <= 1'b0;
                end
                else begin
                    dirty_bits_way1[index] <= 1'b0;
                end
            end
        end
    end

//cache ram
    //read
    assign enb_tag_ram = (mem_read_enE || mem_write_enE) && state==IDLE;
    assign enb_data_bank = mem_read_enE && state==IDLE;                     //sw时，不用读取data

    assign addrb = indexE;  //read: 读tag ram和data ram; write: 读tag ram

    //write
    wire [TAG_WIDTH:0] tag_ram_dina;
    wire [31:0] data_bank0_dina;

    assign wena_way0 = read_finish & ~evict_way;    //lw
    assign wena_way1 = read_finish & evict_way;

    assign addra = index;
    assign tag_ram_dina = {tag, 1'b1};
    assign data_bank0_dina = rdata;

    assign ena_way0 = wena_way0;
    assign ena_way1 = wena_way1;

    d_tag_ram tag_ram_way0 (
        .clka(clk),    // input wire clka
        .ena(),      // input wire ena
        .wea(),      // input wire [0 : 0] wea
        .addra(addra),  // input wire [9 : 0] addra
        .dina(),    // input wire [20 : 0] dina
        .clkb(clk),    // input wire clkb
        .enb(enb_tag_ram),      // input wire enb
        .addrb(addrb),  // input wire [9 : 0] addrb
        .doutb(tag_way0)  // output wire [20 : 0] doutb
    );

    d_tag_ram tag_ram_way1 (
        .clka(clk),    // input wire clka
        .ena(),      // input wire ena
        .wea(),      // input wire [0 : 0] wea
        .addra(addra),  // input wire [9 : 0] addra
        .dina(),    // input wire [20 : 0] dina
        .clkb(clk),    // input wire clkb
        .enb(enb_tag_ram),      // input wire enb
        .addrb(addrb),  // input wire [9 : 0] addrb
        .doutb(tag_way1)  // output wire [20 : 0] doutb
    );

    d_data_bank data_bank0_way0 (
        .clka(clk),    // input wire clka
        .ena(),      // input wire ena
        .wea(),      // input wire [3 : 0] wea
        .addra(addra),  // input wire [9 : 0] addra
        .dina(),    // input wire [31 : 0] dina
        .clkb(clk),    // input wire clkb
        .enb(enb_data_bank),      // input wire enb
        .addrb(addrb),  // input wire [9 : 0] addrb
        .doutb(data_bank0_way0)  // output wire [31 : 0] doutb
    );

    d_data_bank data_bank0_way1 (
        .clka(clk),    // input wire clka
        .ena(),      // input wire ena
        .wea(),      // input wire [3 : 0] wea
        .addra(addra),  // input wire [9 : 0] addra
        .dina(),    // input wire [31 : 0] dina
        .clkb(clk),    // input wire clkb
        .enb(enb_data_bank),      // input wire enb
        .addrb(addrb),  // input wire [9 : 0] addrb
        .doutb(data_bank0_way1)  // output wire [31 : 0] doutb
    );
endmodule