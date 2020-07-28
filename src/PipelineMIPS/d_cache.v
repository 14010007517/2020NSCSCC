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
    reg read_req;       //一次读事务
    reg write_req;      //一次写事务
    reg raddr_rcv;      //读事务地址握手成功
    reg waddr_rcv;      //写事务地址握手成功
    reg wdata_rcv;      //写数据握手成功
    wire read_finish;   //读事务结束
    wire write_finish;  //写事务结束

    wire read, write;
    assign read = data_en & ~(|data_wen);
    assign write = data_en & |data_wen;



    //FSM
    reg [1:0] state;
    parameter IDLE = 2'b00, LoadMemory = 2'b01, WriteMemory = 2'b11;
    always @(posedge clk) begin
        if(rst) begin
            state <= IDLE;
        end
        else begin
            case(state)
                IDLE        : state <= read  ? LoadMemory  :
                                       write ? WriteMemory : IDLE;
                LoadMemory  : state <= read_finish ? IDLE : state;
                WriteMemory  : state <= write_finish ? IDLE : state;
            endcase
        end
    end

    assign hit = 1'b0;    
    //DATAPATH
    assign stall = (read_req &~read_finish) | (write_req & ~write_finish);
    assign data_rdata = rdata;
    

    always @(posedge clk) begin
        read_req <= (rst)            ? 1'b0 :
                    read & ~read_req ? 1'b1 :
                    read_finish      ? 1'b0 : read_req;
        
        write_req <= (rst)              ? 1'b0 :
                     write & ~write_req ? 1'b1 :
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

    //AXI
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
endmodule