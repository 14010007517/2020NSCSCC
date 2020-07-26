module hazard (
    input wire clk,rst,
    input wire [31:0] instrE,//no use
    input wire [31:0] instrM,//no use
    input wire i_cache_stall,
    input wire d_cache_stall,
    input wire pc_reg_ceF,
    input wire div_stallE,

    input wire flush_jump_confilctE, flush_pred_failedM, flush_exceptionM,

    input wire [4:0] rsE,
    input wire [4:0] rtE,
    input wire reg_write_enM,
    input wire reg_write_enW,
    input wire [4:0] reg_writeM,
    input wire [4:0] reg_writeW,

    input wire mem_read_enM,
    input wire mem_write_enM,
    input wire addrErrorLwM, addrErrorSwM,
    
    output wire stallF, stallD, stallE, stallM, stallW,
    output wire flushF, flushD, flushE, flushM, flushW,
    output wire cache_stall,
    output reg cache_stall_r,

    output wire [1:0] forward_aE, forward_bE, //00-> NONE, 01-> MEM, 10-> WB (LW instr)
    output wire inst_enF, mem_enM
);
    assign forward_aE = rsE != 0 && reg_write_enM && (rsE == reg_writeM) ? 2'b01 :
                        rsE != 0 && reg_write_enW && (rsE == reg_writeW) ? 2'b10 :
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

    assign cache_stall = i_cache_stall | d_cache_stall; //longest of lw, sw, 取指

    always @(posedge clk) begin
        cache_stall_r <= rst ? 1'b0: cache_stall;
    end

    assign inst_enF = pc_reg_ceF & ~(cache_stall | cache_stall_r);
    assign mem_enM = (mem_read_enM | mem_write_enM) & (~addrErrorSwM | ~addrErrorLwM) & ~(cache_stall | cache_stall_r);

    wire stall;
    assign stall = cache_stall | inst_enF;
    
    assign stallF = ~flush_exceptionM & (div_stallE | stall);
    assign stallD = stall | div_stallE;
    assign stallE = stall | div_stallE;
    assign stallM = stall;
    assign stallW = stall;              // 不暂停,会减少jr等指令冲突; (现在划去这句话)

    assign flushF = 1'b0;

    /* 当flush一个阶段时，如果其后面的阶段被暂停，则不能flush
    */
    //EX: jr(冲突), MEM: lw这种情况时，flush_jump_confilctE会导致暂停在D阶段jr的延迟槽指令消失
    assign flushD = flush_exceptionM | (flush_pred_failedM & ~stall) | (flush_jump_confilctE & ~stall);       
    //EX: div, MEM: beq, beq预测失败，要flush D和E，但由于div暂停在E，因此只需要flushD就可以了
    assign flushE = flush_exceptionM | (flush_pred_failedM & ~div_stallE & ~stall);                                      
    assign flushM = flush_exceptionM | (div_stallE & ~stall) ;
    assign flushW = 1'b0;
endmodule