module datapath (
    input wire clk, rst,
    input wire [5:0] ext_int,
    
    //inst
    output wire [31:0] pcF,
    output wire [31:0] pc_next,
    output wire inst_enF,
    input wire [31:0] instrF,
    input wire i_cache_stall,
    output wire stallF,

    //data
    output wire mem_enM,                    
    output wire [31:0] mem_addrM,   //读/写地址
    input wire [31:0] mem_rdataM,   //读数据
    output wire [3:0] mem_wenM,     //写使能
    output wire [31:0] mem_wdataM,  //写数据
    input wire d_cache_stall,
    output wire [31:0] mem_addrE,
    output wire mem_read_enE,
    output wire mem_write_enE,
    output wire stallM,

    //debug
    output wire [31:0]  debug_wb_pc,      
    output wire [3:0]   debug_wb_rf_wen,
    output wire [4:0]   debug_wb_rf_wnum, 
    output wire [31:0]  debug_wb_rf_wdata
);

//变量声明
//IF
    wire [31:0] pc_plus4F;
    wire pc_reg_ceF;
    wire [2:0] pc_sel;
    wire pc_errorF;
    wire is_in_delayslot_iF;
//ID
    wire [31:0] instrD;
    wire [31:0] pcD, pc_plus4D;
    wire [4:0] rsD, rtD, rdD, saD;

    wire [31:0] rd1D, rd2D;
    wire [31:0] immD;
    wire sign_extD;
    wire [31:0] pc_branchD;
    wire pred_takeD;
    wire branchD;
    wire flush_pred_failedM;
    wire [31:0] pc_jumpD;
    wire jumpD;
    wire jump_conflictD;
    wire is_in_delayslot_iD;
    wire [4:0] alu_controlD;
    wire [4:0] branch_judge_controlD;
    wire is_divD;
//EX
    wire [31:0] pcE;
    wire [31:0] rd1E, rd2E, mem_wdataE;
    wire [4:0] rsE, rtE, rdE, saE;
    wire [31:0] immE;
    wire [31:0] pc_plus4E;
    wire pred_takeE;

    wire [1:0] reg_dstE;
    wire [4:0] alu_controlE;

    wire [31:0] src_aE, src_bE;
    wire [63:0] alu_outE;
    wire alu_imm_selE;
    wire [4:0] reg_writeE;
    wire [31:0] instrE;
    wire branchE;
    wire [31:0] pc_branchE;
    wire [31:0] pc_jumpE;
    wire jump_conflictE;
    wire reg_write_enE;
    wire div_stallE;
    wire [31:0] rs_valueE, rt_valueE;
    wire flush_jump_confilctE;
    wire is_in_delayslot_iE;
    wire overflowE;
    wire jumpE;
    wire actual_takeE;
    wire [4:0] branch_judge_controlE;
//MEM
    wire [31:0] pcM;
    wire [31:0] alu_outM;
    wire [4:0] reg_writeM;
    wire [31:0] instrM;
    wire mem_read_enM;
    wire mem_write_enM;
    wire reg_write_enM;
    wire mem_to_regM;
    wire [31:0] resultM;
    wire [31:0] resultM_without_rdata;
    wire actual_takeM;
    wire succM;
    wire pred_takeM;
    wire branchM;
    wire [31:0] pc_branchM;

    wire [31:0] mem_ctrl_rdataM;
    wire [31:0] mem_wdataM_temp;
    wire [31:0] mem_ctrl_rdataM;

    wire hilo_wenE;
    wire [31:0] hilo_oM;
    wire [63:0] hiloM;
    wire hilo_to_regM;
    wire riM;
    wire breakM;
    wire syscallM;
    wire eretM;
    wire overflowM;
    wire addrErrorLwM, addrErrorSwM;
    wire pcErrorM;

    wire [31:0] except_typeM;
    wire [31:0] cp0_statusM;
    wire [31:0] cp0_causeM;
    wire [31:0] cp0_epcM;

    wire flush_exceptionM;
    wire [31:0] pc_exceptionM;
    wire pc_trapM;
    wire [31:0] badvaddrM;
    wire is_in_delayslot_iM;
    wire [4:0] rdM;
    wire cp0_to_regM;
    wire mem_error_enM;
    wire cp0_wenM;
    wire [31:0] rt_valueM;
//WB
    wire [31:0] pcW;
    wire reg_write_enW;
    wire [31:0] alu_outW;
    wire [4:0] reg_writeW;
    wire [31:0] resultW;

    wire [31:0] cp0_statusW, cp0_causeW, cp0_epcW, cp0_data_oW;
    
    wire [7:0] l_s_typeD, l_s_typeE, l_s_typeM;
    wire [3:0] addr_typeD, addr_typeE, addr_typeM;
    wire mult_stallE;
    wire is_multD;

// stall

//--------------------debug---------------------
    assign debug_wb_pc          = datapath.pcM;
    assign debug_wb_rf_wen      = {4{reg_write_enM & ~stallW & ~flush_exceptionM}};
    assign debug_wb_rf_wnum     = datapath.reg_writeM;
    assign debug_wb_rf_wdata    = datapath.resultM;
//-------------------------------------------------------------------
//模块实例化
    main_decoder main_decoder0(
        .clk(clk), .rst(rst),
        .instrD(instrD),
        
        .stallE(stallE), .stallM(stallM), .stallW(stallW),
        .flushE(flushE), .flushM(flushM), .flushW(flushW),
        //ID
        .sign_extD(sign_extD),
        .is_divD(is_divD),
        .is_multD(is_multD),
        .l_s_typeD(l_s_typeD),
        //EX
        .reg_dstE(reg_dstE),
        .alu_imm_selE(alu_imm_selE),
        .reg_write_enE(reg_write_enE),
        .hilo_wenE(hilo_wenE),
        .mem_read_enE(mem_read_enE),
        .mem_write_enE(mem_write_enE),
        //MEM
        .mem_read_enM(mem_read_enM),
        .mem_write_enM(mem_write_enM),
        .reg_write_enM(reg_write_enM),
        .mem_to_regM(mem_to_regM),
        .hilo_to_regM(hilo_to_regM),
        .riM(riM),
        .breakM(breakM),
        .syscallM(syscallM),
        .eretM(eretM),
        .cp0_wenM(cp0_wenM),
        .cp0_to_regM(cp0_to_regM)

        //WB
    );
    alu_decoder alu_decoder0(
        .instrD(instrD),

        .alu_controlD(alu_controlD),
        .branch_judge_controlD(branch_judge_controlD)
    );

    wire stallD, stallE, stallW;
    wire flushF, flushD, flushE, flushM, flushW;
    wire [1:0] forward_aE, forward_bE;
    hazard hazard0(
        .clk(clk), .rst(rst),

        .i_cache_stall(i_cache_stall),
        .d_cache_stall(d_cache_stall),
        .div_stallE(div_stallE),
        .mult_stallE(mult_stallE),
        .l_s_typeE(l_s_typeE),

        .flush_jump_confilctE   (flush_jump_confilctE),
        .flush_pred_failedM     (flush_pred_failedM),
        .flush_exceptionM       (flush_exceptionM),

        .rsE(rsE),  .rsD(rsD),
        .rtE(rtE),  .rtD(rtD),
        .reg_write_enE(reg_write_enE),
        .reg_write_enM(reg_write_enM),
        .reg_write_enW(reg_write_enW),
        .reg_writeE(reg_writeE),
        .reg_writeM(reg_writeM),
        .reg_writeW(reg_writeW),

        .stallF(stallF), .stallD(stallD), .stallE(stallE), .stallM(stallM), .stallW(stallW),
        .flushF(flushF), .flushD(flushD), .flushE(flushE), .flushM(flushM), .flushW(flushW),
        .forward_aE(forward_aE), .forward_bE(forward_bE)
    );

//IF
    assign pc_plus4F = pcF + 4;

    pc_ctrl pc_ctrl0(
        //branch
        .branchD(branchD),              //D阶段是branch指令
        .branchM(branchM),              //M阶段是branch指令
        .pred_takeD(pred_takeD),        //D阶段预测跳转
        .succM(succM),                  //M阶段验证预测正确
        .actual_takeM(actual_takeM),    //M阶段判断跳转

        //jump + exception
        .pc_trapM(pc_trapM),            //M阶段异常
        .jumpD(jumpD),                  //D阶段是jump类指令
        .jump_conflictD(jump_conflictD),//D阶段jump数据冲突
        .jump_conflictE(jump_conflictE),//D阶段的jump冲突传到E阶段

        .pc_sel(pc_sel)
    );

    mux8 #(32) mux8_pc_next(
        .x7(32'b0),
        .x6(pc_exceptionM),             //异常的跳转地址
        .x5(pc_plus4E),                 //预测跳，实际不跳。将pc_next指向branch指令的PC+8（注：pc_plus4E等价于branch指令的PC+8） //可以保证延迟槽指令不会被flush，故plush_4E存在
        .x4(pc_branchM),                //预测不跳，实际跳转。将pc_next指向pc_branchD传到M阶段的值
        .x3(pc_jumpE),                  //jump冲突，在E阶段获得跳转的地址
        .x2(pc_jumpD),                  //D阶段jump不冲突跳转的地址（rs寄存器或立即数）
        .x1(pc_branchD),                //D阶段预测跳转的跳转地址（PC+offset）
        .x0(pc_plus4F),                 //下一条指令的地址
        .sel(pc_sel),

        .y(pc_next)
    );
    
    pc_reg pc_reg0(
        .clk(clk),
        .stallF(stallF),
        .rst(rst),
        .pc_next(pc_next),

        .pc(pcF),
        .ce(pc_reg_ceF)
    );

    assign pc_errorF = pcF[1:0]!=2'b0 ? 1'b1 : 1'b0;

    assign inst_enF = pc_reg_ceF & ~flush_exceptionM & ~pc_errorF & ~flush_pred_failedM & ~flush_jump_confilctE;

    assign is_in_delayslot_iF = branchD | jumpD;
//IF_ID
    if_id if_id0(
        .clk(clk), .rst(rst),
        .stallD(stallD),
        .flushD(flushD),
        .pcF(pcF),
        .pc_plus4F(pc_plus4F),
        .instrF(instrF),
        .is_in_delayslot_iF(is_in_delayslot_iF),
        
        .pcD(pcD),
        .pc_plus4D(pc_plus4D),
        .instrD(instrD),
        .is_in_delayslot_iD(is_in_delayslot_iD)
    );

    //use for debug
    wire [44:0] ascii;
    inst_ascii_decoder inst_ascii_decoder0(
        .instr(instrD),
        .ascii(ascii)
    );
//ID
    assign rsD = instrD[25:21];
    assign rtD = instrD[20:16];
    assign rdD = instrD[15:11];
    assign saD = instrD[10:6];

    imm_ext imm_ext0(
        .imm(instrD[15:0]),
        .sign_ext(sign_extD),

        .imm_ext(immD)
    );
    assign pc_branchD = {immD[29:0], 2'b00} + pc_plus4D;

    regfile regfile0(
        .clk(clk),
        .stallW(stallW),
        .we3(reg_write_enM & ~flush_exceptionM),
        .ra1(rsD), .ra2(rtD), .wa3(reg_writeM), 
        .wd3(resultM),

        .rd1(rd1D), .rd2(rd2D)
    );

    branch_predict branch_predict0(
        .clk(clk), .rst(rst),
        .instrD(instrD),
        .immD(immD),
        .pcD(pcD),
        .pcM(pcM),
        .branchM(branchM),
        .actual_takeM(actual_takeM),

        .branchD(branchD),
        .pred_takeD(pred_takeD)
    );

    //jump
    jump_predict jump_predict0(
        .instrD(instrD),
        .pc_plus4D(pc_plus4D),
        .rd1D(rd1D),
        .reg_write_enE(reg_write_enE), .reg_write_enM(reg_write_enM),
        .reg_writeE(reg_writeE), .reg_writeM(reg_writeM),

        .jumpD(jumpD),                      //是jump类指令(j, jr)
        .jump_conflictD(jump_conflictD),    //jr rs寄存器发生冲突
        .pc_jumpD(pc_jumpD)                 //D阶段最终跳转地址
    );
//ID_EX
    id_ex id_ex0(
        .clk(clk),
        .rst(rst),
        .stallE(stallE),
        .flushE(flushE),
        .pcD(pcD),
        .rsD(rsD), .rd1D(rd1D), .rd2D(rd2D),
        .rtD(rtD), .rdD(rdD),
        .immD(immD),
        .pc_plus4D(pc_plus4D),
        .instrD(instrD),
        .branchD(branchD),
        .pred_takeD(pred_takeD),
        .pc_branchD(pc_branchD),
        .jump_conflictD(jump_conflictD),
        .is_in_delayslot_iD(is_in_delayslot_iD),
        .saD(saD),
        .alu_controlD(alu_controlD),
        .jumpD(jumpD),
        .branch_judge_controlD(branch_judge_controlD),
        .l_s_typeD(l_s_typeD),
        
        .pcE(pcE),
        .rsE(rsE), .rd1E(rd1E), .rd2E(rd2E),
        .rtE(rtE), .rdE(rdE),
        .immE(immE),
        .pc_plus4E(pc_plus4E),
        .instrE(instrE),
        .branchE(branchE),
        .pred_takeE(pred_takeE),
        .pc_branchE(pc_branchE),
        .jump_conflictE(jump_conflictE),
        .is_in_delayslot_iE(is_in_delayslot_iE),
        .saE(saE),
        .alu_controlE(alu_controlE),
        .jumpE(jumpE),
        .branch_judge_controlE(branch_judge_controlE),
        .l_s_typeE(l_s_typeE)
    );
//EX
    alu_lg alu0(
        .clk(clk),
        .rst(rst),
        .flushE(flushE),
        .flush_exceptionM(flush_exceptionM),
        .stallM(stallM),
        .src_aE(src_aE), .src_bE(src_bE),
        .alu_controlE(alu_controlE),
        .sa(saE),
        .hilo(hiloM),
        .stallD(stallD),
        .is_divD(is_divD),
        .is_multD(is_multD),

        .div_stallE(div_stallE),
        .mult_stallE(mult_stallE),
        .alu_outE(alu_outE),
        .overflowE(overflowE)
    );

    assign mem_addrE = alu_outE[31:0];

    //mux write reg
    mux4 #(5) mux4_reg_dst(rdE, rtE, 5'd31, 5'b0, reg_dstE, reg_writeE);

    //数据前推(bypass)
    mux4 #(32) mux4_forward_aE(
        rd1E,                       
        resultM_without_rdata,
        resultW,
        pc_plus4D,                          // 执行jalr，jal指令；写入到$ra寄存器的数据（跳转指令对应延迟槽指令的下一条指令的地址即PC+8） //可以保证延迟槽指令不会被flush，故plush_4D存在
        {2{jumpE | branchE}} | forward_aE,  // 当exe阶段是jal或者jalr指令，或者bxxzal时，jumpE | branchE== 1；选择pc_plus4D；

        src_aE
    );
    mux4 #(32) mux4_forward_bE(
        rd2E,                               //
        resultM_without_rdata,                            //
        resultW,                            // 
        immE,                               //立即数
        {2{alu_imm_selE}} | forward_bE,     //main_decoder产生alu_imm_selE信号，表示alu第二个操作数为立即数

        src_bE
    );
    mux4 #(32) mux4_rs_valueE(rd1E, resultM_without_rdata, resultW, 32'b0, forward_aE, rs_valueE); //数据前推后的rs寄存器的值
    mux4 #(32) mux4_rt_valueE(rd2E, resultM_without_rdata, resultW, 32'b0, forward_bE, rt_valueE); //数据前推后的rt寄存器的值

    //计算branch结果
    branch_judge branch_judge0(
        .branch_judge_controlE(branch_judge_controlE),
        .src_aE(rs_valueE),
        .src_bE(rt_valueE),

        .actual_takeE(actual_takeE)
    );

    //jump
    assign pc_jumpE = rs_valueE;
    assign flush_jump_confilctE = jump_conflictE;
//EX_MEM
    ex_mem ex_mem0(
        .clk(clk),
        .rst(rst),
        .stallM(stallM),
        .flushM(flushM),
        .pcE(pcE),
        .alu_outE(alu_outE),
        .rt_valueE(rt_valueE),
        .reg_writeE(reg_writeE),
        .instrE(instrE),
        .branchE(branchE),
        .pred_takeE(pred_takeE),
        .pc_branchE(pc_branchE),
        .overflowE(overflowE),
        .is_in_delayslot_iE(is_in_delayslot_iE),
        .rdE(rdE),
        .actual_takeE(actual_takeE),
        .l_s_typeE(l_s_typeE),

        .pcM(pcM),
        .alu_outM(alu_outM),
        .rt_valueM(rt_valueM),
        .reg_writeM(reg_writeM),
        .instrM(instrM),
        .branchM(branchM),
        .pred_takeM(pred_takeM),
        .pc_branchM(pc_branchM),
        .overflowM(overflowM),
        .is_in_delayslot_iM(is_in_delayslot_iM),
        .rdM(rdM),
        .actual_takeM(actual_takeM),
        .l_s_typeM(l_s_typeM)
    );
//MEM
    assign mem_addrM = alu_outM;
    assign mem_enM = (mem_read_enM | mem_write_enM) & ~flush_exceptionM;

    // 是否需要控制 mem_en
    mem_ctrl mem_ctrl0(
        .l_s_typeM(l_s_typeM),
	    .addr(alu_outM),

        .data_wdataM(rt_valueM),    //原始的wdata
        .mem_wdataM(mem_wdataM),    //新的wdata
        .mem_wenM(mem_wenM),

        .mem_rdataM(mem_rdataM),    
        .data_rdataM(mem_ctrl_rdataM),

        .addr_error_sw(addrErrorSwM),
        .addr_error_lw(addrErrorLwM)
    );

    hilo_reg hilo0(
        .clk(clk),
        .rst(rst),
        .instrM(instrM),    // 用于识别mfhi，mflo，决定输出；
        .we(hilo_wenE & ~flush_exceptionM & ~stallM),     // both write lo and hi
        .hilo_i(alu_outE),

        .hilo_o(hilo_oM),   //传给resultM多选
        .hilo(hiloM)        //传给alu进行拼接
    );

    assign pcErrorM = |(pcM[1:0] ^ 2'b00);
    
    exception exception0(
        .rst(rst),
        .ri(riM), .break(breakM), .syscall(syscallM), .overflow(overflowM), .addrErrorSw(addrErrorSwM), .addrErrorLw(addrErrorLwM), .pcError(pcErrorM), .eretM(eretM),
        .cp0_status(cp0_statusW), .cp0_cause(cp0_causeW), .cp0_epc(cp0_epcW),
        .pcM(pcM),
        .alu_outM(alu_outM),

        .except_type(except_typeM),
        .flush_exception(flush_exceptionM),
        .pc_exception(pc_exceptionM),
        .pc_trap(pc_trapM),
        .badvaddrM(badvaddrM)
    );

    cp0_reg cp0(
        .clk(clk),
        .rst(rst),
        .ext_int(ext_int),
        .stallW(stallW),
        
        .en(flush_exceptionM),

        .we_i(cp0_wenM & ~stallW),
        .waddr_i(rdM),
        .data_i(rt_valueM),
        
        .raddr_i(rdM),
        .data_o(cp0_data_oW),

        .except_type_i(except_typeM),
        .current_inst_addr_i(pcM),
        .is_in_delayslot_i(is_in_delayslot_iM),
        .badvaddr_i(badvaddrM),

        .status_o(cp0_statusW),
        .cause_o(cp0_causeW),
        .epc_o(cp0_epcW)
    );

    mux4 #(32) mux4_mem_forward(alu_outM, 0, hilo_oM, cp0_data_oW, {(hilo_to_regM | cp0_to_regM), (mem_to_regM | cp0_to_regM)}, resultM_without_rdata);
    mux4 #(32) mux4_mem_to_reg(alu_outM, mem_ctrl_rdataM, hilo_oM, cp0_data_oW, {(hilo_to_regM | cp0_to_regM), (mem_to_regM | cp0_to_regM)}, resultM);

    //branch predict result
    assign succM = ~(pred_takeM ^ actual_takeM);
    assign flush_pred_failedM = ~succM;
//MEM_WB
    mem_wb mem_wb0(
        .clk(clk),
        .rst(rst),
        .stallW(stallW),
        .pcM(pcM),
        .alu_outM(alu_outM),
        .reg_writeM(reg_writeM),
        .reg_write_enM(reg_write_enM),
        .resultM(resultM),


        .pcW(pcW),
        .alu_outW(alu_outW),
        .reg_writeW(reg_writeW),
        .reg_write_enW(reg_write_enW),
        .resultW(resultW)
    );
//WB

endmodule