module hazard (
    input wire clk,rst,
    input wire i_cache_stall,
    input wire d_cache_stall,
    input wire div_stallE,
    input wire mult_stallE,
    input wire [9:0] l_s_typeE,

    input wire flush_jump_confilctE, flush_pred_failedM, flush_exceptionM,

    input wire [4:0] rsE, rsD,
    input wire [4:0] rtE, rtD,
    input wire reg_write_enE, reg_write_enM, reg_write_enW,
    input wire [4:0] reg_writeE, reg_writeM, reg_writeW,
    
    output wire stallF, stallD, stallE, stallM, stallW,
    output wire flushF, flushD, flushE, flushM, flushW,
    output wire [1:0] forward_aE, forward_bE
);
    assign forward_aE = rsE != 0 && reg_write_enM && (rsE == reg_writeM) ? 2'b01 :
                        rsE != 0 && reg_write_enW && (rsE == reg_writeW) ? 2'b10 :
                        2'b00;
    assign forward_bE = rtE != 0 && reg_write_enM && (rtE == reg_writeM) ? 2'b01 :
                        rtE != 0 && reg_write_enW && (rtE == reg_writeW) ? 2'b10 :
                        2'b00;
    wire stall_ltypeD; // 将lw读出的数据，在mem阶段不进行前推；若产生冲突： ID：add； EXE：lw，则暂停一个周期，产生一个空泡，在wb阶段前推
    assign stall_ltypeD = (|(l_s_typeE[7:3]) | l_s_typeE[9]) & ((rsD != 0 && reg_write_enE && (rsD == reg_writeE)) || 
                                               (rtD != 0 && reg_write_enE && (rtD == reg_writeE))
                                              ) & ~flush_exceptionM & ~flush_pred_failedM; //若M阶段产生分支预测失败，则D阶段指令无需执行，故不用暂停
    
    wire longest_stall;
    assign longest_stall = i_cache_stall | d_cache_stall | div_stallE | mult_stallE;
    
    assign stallF = longest_stall | stall_ltypeD;
    assign stallD = longest_stall | stall_ltypeD;
    assign stallE = longest_stall;
    assign stallM = longest_stall;
    assign stallW = longest_stall;

    /* 当flush一个阶段时，如果其后面的阶段被暂停，则不能flush
    */
    assign flushF = 1'b0;
    assign flushD = flush_exceptionM;
    assign flushE = flush_exceptionM | (flush_pred_failedM & ~longest_stall) | (stall_ltypeD & ~longest_stall);     
    assign flushM = flush_exceptionM;
    assign flushW = 1'b0;
endmodule