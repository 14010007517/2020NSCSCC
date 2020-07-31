module hazard (
    input wire clk,rst,
    input wire [31:0] instrE,//no use
    input wire [31:0] instrM,//no use
    input wire i_cache_stall,
    input wire d_cache_stall,
    input wire mem_read_enM,
    input wire mem_write_enM,
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
    output wire [1:0] forward_aE, forward_bE //00-> NONE, 01-> MEM, 10-> WB (LW instr)
);
    assign forward_aE = rsE != 0 && reg_write_enM && (rsE == reg_writeM) ? 2'b01 :
                        rsE != 0 && reg_write_enW && (rsE == reg_writeW) ? 2'b10 :
                        2'b00;
    assign forward_bE = reg_write_enM && (rtE == reg_writeM) ? 2'b01 :
                        reg_write_enW && (rtE == reg_writeW) ? 2'b10 :
                        2'b00;
    
    wire longest_stall;
    
    assign longest_stall = i_cache_stall | d_cache_stall | div_stallE; //longest of lw, sw, 取指 and div_stall;
    
    assign stallF = ~flush_exceptionM & longest_stall;
    assign stallD = longest_stall;
    assign stallE = longest_stall;
    assign stallM = longest_stall;
    assign stallW = longest_stall;              // 不暂停,会减少jr等指令冲突; (现在划去这句话)

    assign flushF = 1'b0;

    /* 当flush一个阶段时，如果其后面的阶段被暂停，则不能flush
    */
    //EX: jr(冲突), MEM: lw这种情况时，flush_jump_confilctE会导致暂停在D阶段jr的延迟槽指令消失
    assign flushD = flush_exceptionM | (flush_pred_failedM & ~longest_stall) | (flush_jump_confilctE & ~longest_stall);       
    //EX: div, MEM: beq, beq预测失败，要flush D和E，但由于div暂停在E，因此只需要flushD就可以了
    assign flushE = flush_exceptionM | (flush_pred_failedM & ~longest_stall);                                      
    assign flushM = flush_exceptionM;
    assign flushW = 1'b0;
endmodule