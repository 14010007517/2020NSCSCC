module hazard (
    input wire clk,rst,
    input wire [31:0] instrE,//no use
    input wire [31:0] instrM,//no use
    input wire i_cache_stall,
    input wire i_cache_hit,
    input wire d_cache_stall,
    input wire div_stallE,

    input wire flush_jump_confilctE, flush_pred_failedM, flush_exceptionM,

    input wire [4:0] rsE,
    input wire [4:0] rtE,
    input wire reg_write_enM,
    input wire reg_write_enW,
    input wire [4:0] reg_writeM,
    input wire [4:0] reg_writeW,
    
    output wire stallF, stallD, stallE, stallM, stallW,
    output wire flushF, flushD, flushE, flushM, flushW,
    output wire en_stall,

    output wire [1:0] forward_aE, forward_bE //00-> NONE, 01-> MEM, 10-> WB (LW instr)
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
    wire longest_stall;
    reg longest_stall_r;
    wire pipe_stall;
    
    assign longest_stall = i_cache_stall | d_cache_stall | div_stallE; //longest of lw, sw, 取指 and div_stall;
    // assign cache_stall = i_cache_stall | d_cache_stall; //longest of lw, sw, 取指 and div_stall;

    always @(posedge clk) begin
        longest_stall_r <= rst ? 1'b0: longest_stall;
    end

    assign en_stall = (longest_stall | longest_stall_r);
    
    assign pipe_stall = (~en_stall | longest_stall) & ~i_cache_hit;

    assign stallF = ~flush_exceptionM & pipe_stall;
    assign stallD = pipe_stall;
    assign stallE = pipe_stall;
    assign stallM = pipe_stall;
    assign stallW = pipe_stall;              // 不暂停,会减少jr等指令冲突; (现在划去这句话)

    assign flushF = 1'b0;

    /* 当flush一个阶段时，如果其后面的阶段被暂停，则不能flush
    */
    //EX: jr(冲突), MEM: lw这种情况时，flush_jump_confilctE会导致暂停在D阶段jr的延迟槽指令消失
    assign flushD = flush_exceptionM | (flush_pred_failedM & ~pipe_stall) | (flush_jump_confilctE & ~pipe_stall);       
    //EX: div, MEM: beq, beq预测失败，要flush D和E，但由于div暂停在E，因此只需要flushD就可以了
    assign flushE = flush_exceptionM | (flush_pred_failedM & ~div_stallE & ~pipe_stall);                                      
    assign flushM = flush_exceptionM | (div_stallE & ~pipe_stall) ;
    assign flushW = 1'b0;
endmodule