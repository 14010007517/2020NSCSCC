module hazard (
    input wire clk,rst,
    input wire [31:0] instrE,//no use
    input wire [31:0] instrM,//no use
    input wire i_cache_stall,
    input wire d_cache_stall,
    input wire mem_read_enM,
    input wire mem_write_enM,
    input wire div_stallE,
    input wire mult_stallE,
    input wire [7:0] l_s_typeE,

    input wire flush_jump_confilctE, flush_pred_failedM, flush_exceptionM,

    input wire [4:0] rsE, rsD,
    input wire [4:0] rtE, rtD,
    input wire reg_write_enE,
    input wire reg_write_enM,
    input wire reg_write_enW,
    input wire [4:0] reg_writeM, reg_writeE,
    input wire [4:0] reg_writeW, 
    
    output wire stallF, stallD, stallE, stallM, stallW,
    output wire flushF, flushD, flushE, flushM, flushW,
    output wire [1:0] forward_aE, forward_bE //00-> NONE, 01-> MEM, 10-> WB (LW instr)
);
    assign forward_aE = rsE != 0 && reg_write_enM && (rsE == reg_writeM) ? 2'b01 :
                        rsE != 0 && reg_write_enW && (rsE == reg_writeW) ? 2'b10 :
                        2'b00;
    assign forward_bE = rtE != 0 && reg_write_enM && (rtE == reg_writeM) ? 2'b01 :
                        rtE != 0 && reg_write_enW && (rtE == reg_writeW) ? 2'b10 :
                        2'b00;
    wire stall_ltypeE; // 将lw读出的数据，在mem阶段不进行前推；若产生冲突： ID：add； EXE：lw，则暂停一个周期，产生一个空泡，在wb阶段前推
    assign stall_ltypeE = |(l_s_typeE[7:3]) & ((rsD != 0 && reg_write_enE && (rsD == reg_writeE)) || (rtD != 0 && reg_write_enE && (rtD == reg_writeE)));
    
    wire longest_stall;
    
    assign longest_stall = i_cache_stall | d_cache_stall | div_stallE | mult_stallE;
    
    assign stallF = ~flush_exceptionM & (longest_stall | (stall_ltypeE & ~flush_pred_failedM));
    assign stallD = (longest_stall | stall_ltypeE);
    assign stallE = longest_stall;
    assign stallM = longest_stall;
    assign stallW = longest_stall;              // 不暂停,会减少jr等指令冲突; (现在划去这句话)

    assign flushF = 1'b0;

    /* 当flush一个阶段时，如果其后面的阶段被暂停，则不能flush
    */
    //EX: jr(冲突), MEM: lw这种情况时，flush_jump_confilctE会导致暂停在D阶段jr的延迟槽指令消失
    assign flushD = flush_exceptionM | (flush_pred_failedM & ~longest_stall) | (flush_jump_confilctE & ~longest_stall & ~stall_ltypeE);       
    //EX: div, MEM: beq, beq预测失败，要flush D和E，但由于div暂停在E，因此只需要flushD就可以了
    assign flushE = flush_exceptionM | (flush_pred_failedM & ~longest_stall) | (stall_ltypeE & ~longest_stall);     
    // 当检测到冲突时，
    assign flushM = flush_exceptionM;
    assign flushW = 1'b0;
endmodule