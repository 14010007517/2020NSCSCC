module i_cache (
    input wire clk, rst,
    //datapath
    input wire inst_en,
    input wire [31:0] inst_addr,
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

    reg read_req;       //一次读事务
    reg addr_rcv;       //地址握手成功
    wire read_finish;   //读事务结束

    always @(posedge clk) begin
        read_req <= (rst)               ? 1'b0 :
                    inst_en & ~read_req ? 1'b1 :
                    read_finish         ? 1'b0 : read_req;
    end
    
    always @(posedge clk) begin
        addr_rcv <= rst              ? 1'b0 :
                    arvalid&&arready ? 1'b1 :
                    read_finish      ? 1'b0 : addr_rcv;
    end

    assign read_finish = addr_rcv & (rvalid & rready & rlast);

    //DATAPATH
    assign stall = read_req & ~read_finish;
    assign inst_rdata = rdata;

    //AXI
    assign araddr = inst_addr;
    assign arlen = 8'b0;
    assign arvalid = read_req & ~addr_rcv;
    assign rready = addr_rcv;


endmodule