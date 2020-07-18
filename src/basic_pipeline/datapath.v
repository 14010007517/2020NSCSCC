module datapath (
    input wire clk, rst,
    
    //inst
    output wire [31:0] inst_addrF,
    output wire inst_enF,
    input wire [31:0] instrF,  //注：instr ram时钟取反

    //data
    output wire mem_enM,                    
    output wire [31:0] mem_addrM,   //读/写地址
    input wire [31:0] mem_rdataM,   //读数据
    output wire [3:0] mem_wenM,     //写使能
    output wire [31:0] mem_wdataM,  //写数据
    input wire d_cache_stall
);

//变量声明
//IF
    wire [31:0] pcF, pc_next, pc_plus4F;
    wire pc_reg_ceF;
    wire [1:0] pc_sel;
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
    wire pred_failed_flushD;
//EX
    wire [31:0] pcE;
    wire [31:0] rd1E, rd2E;
    wire [4:0] rsE, rtE, rdE;
    wire [31:0] immE;
    wire [31:0] pc_plus4E;
    wire pred_takeE;

    wire [1:0] reg_dstE;
    wire [4:0] alu_controlE;

    wire [31:0] src_aE, src_bE, alu_outE;
    wire alu_imm_selE;
    wire [4:0] reg_writeE;
    wire [31:0] instrE;
    wire branchE;
    wire succE;
    wire actual_takeE;
    wire [31:0] pc_branchE;
//MEM
    wire [31:0] pcM;
    wire [31:0] alu_outM;
    wire [31:0] rd2M;
    wire [4:0] reg_writeM;
    wire [31:0] instrM;
    wire mem_read_enM;
    wire mem_write_enM;
    wire reg_write_enM;
    wire mem_to_regM;
    wire [31:0] resultM;
//WB
    wire [31:0] pcW;
    wire reg_write_enW;
    wire [31:0] alu_outW;
    wire [4:0] reg_writeW;
    wire [31:0] resultW;

//-------------------------------------------------------------------
//模块实例化
    main_decoder main_decoder0(
        .clk(clk), .rst(rst),
        .instrD(instrD),
        
        .stallE(stallE), .stallM(stallM), .stallW(stallW),
        //ID
        .sign_extD(sign_extD),
        //EX
        .reg_dstE(reg_dstE),
        .alu_imm_selE(alu_imm_selE),
        //MEM
        .mem_read_enM(mem_read_enM),
        .mem_write_enM(mem_write_enM),
        .reg_write_enM(reg_write_enM),
        .mem_to_regM(mem_to_regM)
        //WB
    );
    alu_decoder alu_decoder0(
        .clk(clk),
        .instrD(instrD),

        .alu_controlE(alu_controlE)
    );

    wire stallF, stallD, stallE, stallM, stallW;
    wire [1:0] forward_aE, forward_bE;
    hazard hazard0(
        .rst(rst),
        .instrE(instrE),
        .instrM(instrM),
        .d_cache_stall(d_cache_stall),
        .rsE(rsE),
        .rtE(rtE),
        .reg_write_enM(reg_write_enM),
        .reg_write_enW(reg_write_enW),
        .reg_writeM(reg_writeM),
        .reg_writeW(reg_writeW),
        .mem_read_enM(mem_read_enM),

        .stallF(stallF), .stallD(stallD), .stallE(stallE), .stallM(stallM), .stallW(stallW),
        .forward_aE(forward_aE), .forward_bE(forward_bE)
    );

//IF
    assign pc_plus4F = pcF + 4;

    mux4 #(32) mux4_pc(pc_plus4F, pc_branchD, pc_branchE, pc_plus4D, pc_sel, pc_next); //pc_plus4D等价于branch指令的PC+8

    pc_reg pc_reg0(
        .clk(clk),
        .stallF(stallF),
        .rst(rst),
        .pc_next(pc_next),

        .pc(pcF),
        .ce(pc_reg_ceF)
    );
    assign inst_addrF = pcF;
    assign inst_enF = pc_reg_ceF & ~stallF;

    pc_ctrl pc_ctrl0(
        .branchD(branchD),
        .branchE(branchE),
        .pred_takeD(pred_takeD),
        .succE(succE),
        .actual_takeE(actual_takeE),

        .pc_sel(pc_sel)
    );
//IF_ID
    if_id if_id0(
        .clk(clk), .rst(rst),
        .flushD(pred_failed_flushD),
        .stallD(stallD),
        .pcF(pcF),
        .pc_plus4F(pc_plus4F),
        .instrF(instrF),
        
        .pcD(pcD),
        .pc_plus4D(pc_plus4D),
        .instrD(instrD)
    );

    //use for debug
    wire [39:0] ascii;
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
        .we3(reg_write_enM & ~d_cache_stall),
        .ra1(rsD), .ra2(rtD), .wa3(reg_writeM), 
        .wd3(resultM),

        .rd1(rd1D), .rd2(rd2D)
    );

    branch_predict branch_predict0(
        .instrD(instrD),
        .immD(immD),

        .branchD(branchD),
        .pred_takeD(pred_takeD)
    );

//ID_EX
    id_ex id_ex0(
        .clk(clk),
        .rst(rst),
        .stallE(stallE),
        .pcD(pcD),
        .rsD(rsD), .rd1D(rd1D), .rd2D(rd2D),
        .rtD(rtD), .rdD(rdD),
        .immD(immD),
        .pc_plus4D(pc_plus4D),
        .instrD(instrD),
        .branchD(branchD),
        .pred_takeD(pred_takeD),
        .pc_branchD(pc_branchD),
        
        .pcE(pcE),
        .rsE(rsE), .rd1E(rd1E), .rd2E(rd2E),
        .rtE(rtE), .rdE(rdE),
        .immE(immE),
        .pc_plus4E(pc_plus4E),
        .instrE(instrE),
        .branchE(branchE),
        .pred_takeE(pred_takeE),
        .pc_branchE(pc_branchE)
    );
//EX
    alu alu0(
        .src_aE(src_aE), .src_bE(src_bE),
        .alu_controlE(alu_controlE),

        .alu_outE(alu_outE)
    );

    //mux write reg
    mux4 #(5) mux4_reg_dst(rdE, rtE, 5'd31, 5'b0, reg_dstE, reg_writeE);

    //mux alu imm sel
    // mux2 #(32) mux2_alu_imm_selb(rd2E, immE, alu_imm_selE, src_bE);

    //数据前推(bypass)
    mux4 #(32) mux4_forward_aE(rd1E, resultM, resultW, 32'b0, forward_aE, src_aE); 
    mux4 #(32) mux4_forward_bE(rd2E, resultM, resultW, immE, {alu_imm_selE|forward_bE[1], alu_imm_selE|forward_bE[0]}, src_bE);
    
    //branch predict result
    assign actual_takeE = branchE & alu_outE[0];
    assign succE = ~(pred_takeE ^ actual_takeE);
    assign pred_failed_flushD = ~succE;
//EX_MEM
    ex_mem ex_mem0(
        .clk(clk),
        .rst(rst),
        .stallM(stallM),
        .pcE(pcE),
        .alu_outE(alu_outE),
        .rd2E(rd2E),
        .reg_writeE(reg_writeE),
        .instrE(instrE),

        .pcM(pcM),
        .alu_outM(alu_outM),
        .rd2M(rd2M),
        .reg_writeM(reg_writeM),
        .instrM(instrM)
    );
//MEM
    assign mem_addrM = alu_outM;
    assign mem_wdataM = rd2M;

    assign mem_enM = mem_read_enM | mem_write_enM; //读或者写
    assign mem_wenM = {4{mem_write_enM}};           //暂时只有sw

    mux2 #(32) mux2_mem_to_reg(alu_outM, mem_rdataM, mem_to_regM, resultM);
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
    // mux2 #(32) mux2_mem_to_reg(alu_outW, mem_rdataW, mem_to_regW, resultW);


endmodule