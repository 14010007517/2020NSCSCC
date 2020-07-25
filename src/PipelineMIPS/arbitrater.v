module arbitrater (
    input wire clk, rst,
    //I CACHE
    input wire [31:0] i_araddr,
    input wire [7:0] i_arlen,
    input wire i_arvalid,
    output wire i_arready,

    output wire [31:0] i_rdata,
    output wire i_rlast,
    output wire i_rvalid,
    input wire i_rready,

    //D CACHE
    input wire [31:0] d_araddr,
    input wire [7:0] d_arlen,
    input wire d_arvalid,
    output wire d_arready,

    output wire [31:0] d_rdata,
    output wire d_rlast,
    output wire d_rvalid,
    input wire d_rready,
    //write
    input wire [31:0] d_awaddr,
    input wire [7:0] d_awlen,
    input wire [2:0] d_awsize,
    input wire d_awvalid,
    output wire d_awready,
    
    input wire [31:0] d_wdata,
    input wire [3:0] d_wstrb,
    input wire d_wlast,
    input wire d_wvalid,
    output wire d_wready,

    output wire d_bvalid,
    input wire d_bready,
    //Outer
    input wire[3:0] arid,
    input wire[31:0] araddr,
    input wire[7:0] arlen,
    input wire[2:0] arsize,
    input wire[1:0] arburst,
    input wire[1:0] arlock,
    input wire[3:0] arcache,
    input wire[2:0] arprot,
    input wire arvalid,
    output wire arready,
                
    output wire[3:0] rid,
    output wire[31:0] rdata,
    output wire[1:0] rresp,
    output wire rlast,
    output wire rvalid,
    input wire rready,
               
    input wire[3:0] awid,
    input wire[31:0] awaddr,
    input wire[7:0] awlen,
    input wire[2:0] awsize,
    input wire[1:0] awburst,
    input wire[1:0] awlock,
    input wire[3:0] awcache,
    input wire[2:0] awprot,
    input wire awvalid,
    output wire awready,
    
    input wire[3:0] wid,
    input wire[31:0] wdata,
    input wire[3:0] wstrb,
    input wire wlast,
    input wire wvalid,
    output wire wready,
    
    output wire[3:0] bid,
    output wire[1:0] bresp,
    output bvalid,
    input bready
);

    wire ar_sel;     //0-> d_cache, 1-> i_cache
    reg [1:0] r_sel;      //2'b00-> no, 2'b01-> d_cache, 2'b10-> i_cache

    //ar
    assign ar_sel = ~d_arvalid & i_arvalid ? 1'b1 : 1'b0;

    //r
    always @(posedge clk) begin
        if(rvalid && rid==3'b000) begin
            r_sel <= 2'b01;
        end
        else if(rvalid && rid==3'b001) begin
            r_sel <= 2'b10;
        end
        else if(~rvalid) begin
            r_sel <= 2'b00;
        end
    end

    //I CACHE
    assign i_arready = arready & ar_sel;

    assign i_rdata = rdata;
    assign i_rlast = rlast;
    assign i_rvalid = rvalid && (r_sel==2'b10) ? 1'b1 : 1'b0;
    //D CACHE
    assign d_arready = arready & ~ar_sel;

    assign d_rdata = rdata;
    assign d_rlast = rlast;
    assign d_rvalid = rvalid && (r_sel==2'b01) ? 1'b1 : 1'b0;
    //AXI
    //ar
    assign arid = {2'b0, ar_sel};
    assign araddr = ar_sel ? i_araddr : d_araddr;
    assign arlen = ar_sel ? i_arlen : d_arlen;
    assign arsize  = 2'b10;         //读一个字
    assign arburst = 2'b10;         //Incrementing burst
    assign arlock  = 2'd0;
    assign arcache = 4'd0;
    assign arprot  = 3'd0;
    assign arvalid = ar_sel ? i_arvalid : d_arvalid;
                        //         
    //r
    assign rready = r_sel==2'b01 ? d_rready :
                    r_sel==2'b10 ? i_rready :
                    1'b0;
                        //            

    //aw
    assign awid    = 4'd0;
    assign awaddr  = d_awaddr;
    assign awlen   = d_awlen;      //8*4B
    assign awsize  = d_awsize;
    assign awburst = 2'b10;     //Incrementing burst
    assign awlock  = 2'd0;
    assign awcache = 4'd0;
    assign awprot  = 3'd0;
    assign awvalid = d_awvalid;
    //w
    assign wid    = 4'd0;
    assign wdata  = d_wdata;
    // assign wstrb  = do_size_r==2'd0 ? 4'b0001<<do_addr_r[1:0] :
    //                 do_size_r==2'd1 ? 4'b0011<<do_addr_r[1:0] : 4'b1111;
    assign wstrb = d_wstrb;
    assign wlast  = d_wlast;
    assign wvalid = d_wvalid;
    //b
    assign bready  = d_bready;
    
    //to d-cache
    assign d_awready = awready;
    assign d_wready  = wready;
    assign d_bvalid  = bvalid;
endmodule