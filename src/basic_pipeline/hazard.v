module hazard (
    input wire rst,
    input wire [31:0] instrE,//no use
    input wire [31:0] instrM,//no use
    input wire d_cache_stall,

    input wire [4:0] rsE,
    input wire [4:0] rtE,
    input wire reg_write_enM,
    input wire reg_write_enW,
    input wire [4:0] reg_writeM,
    input wire [4:0] reg_writeW,

    input wire mem_read_enM,
    
    output wire stallF, stallD, stallE, stallM, stallW,

    output wire [1:0] forward_aE, forward_bE
);
    wire stallF, stallD, stallE, stallM, stallW;
    wire flushF, flushD, flushE, flushM;

    wire [1:0] forward_aE, forward_bE; //00-> NONE, 01-> MEM, 10-> WB (LW instr)

    assign forward_aE = reg_write_enM && (rsE == reg_writeM) ? 2'b01 :
                        reg_write_enW && (rsE == reg_writeW) ? 2'b10 :
                        2'b00;
    assign forward_bE = reg_write_enM && (rtE == reg_writeM) ? 2'b01 :
                        reg_write_enW && (rtE == reg_writeW) ? 2'b10 :
                        2'b00;
    
    // reg stall_lw;  //add, lw 数据冲突无法仅靠数据前推解决（MEM阶段无法从内存取得数据），需要先暂停形成一个气泡，再前推
                      //更新1：通过mem_stall来暂停（相当于将MEM分为了两个阶段），故可以在MEM阶段前推
    // always @(*) begin
    //     stall_lw =  rst ? 1'b0 : mem_read_enM && (
    //                     (reg_write_enM && (rsE == reg_writeM)) ||
    //                     (reg_write_enM && (rtE == reg_writeM))
    //                 );
    // end
    
    assign stallF = d_cache_stall;
    assign stallD = d_cache_stall;
    assign stallE = d_cache_stall;
    assign stallM = d_cache_stall;
    assign stallW = d_cache_stall;
endmodule