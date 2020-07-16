module datapath (
    input wire clk, rst,

    //inst
    output wire [31:0] inst_addrF,
    output wire inst_enF,
    input wire [31:0] instrD,

    //data
    output wire mem_enM,                    
    output wire [31:0] mem_addrM,   //读/写地址
    input wire [31:0] mem_rdataW,   //读数据
    output wire [3:0] mem_wenM,     //写使能
    output wire [31:0] mem_wdataM   //写数据
);

//变量声明
//IF
    wire [31:0] pcF, pc_next, pc_plus4F;
//ID
    wire [31:0] pcD, pc_plus4D;
    wire [4:0] rsD, rtD, rdD, saD;

    wire [31:0] rd1D, rd2D;
    wire [31:0] immD;
    wire sign_extD;
    wire [31:0] pc_branchD;
    wire branch_takeD;
//EX
    wire [31:0] pcE;
    wire [31:0] rd1E, rd2E;
    wire [4:0] rtE, rdE;
    wire [31:0] immE;
    wire [31:0] pc_plus4E;

    wire [1:0] reg_dstE;
    wire [4:0] alu_controlE;

    wire [31:0] src_aE, src_bE, alu_outE;
    wire alu_srcE;
    wire [4:0] reg_writeE;
//MEM
    wire [31:0] pcM;
    wire [31:0] alu_outM;
    wire [31:0] rd2M;
    wire [4:0] reg_writeM;
    wire mem_read_enM;
    wire mem_write_enM;
//WB
    wire [31:0] pcW;
    wire reg_write_enW;
    wire [31:0] alu_outW;
    wire [4:0] reg_writeW;
    wire mem_to_regW;
    wire [31:0] resultW;

//-------------------------------------------------------------------
//模块实例化
    main_decoder main_decoder0(
        .clk(clk),
        .instrD(instrD),
        
        //ID
        .sign_extD(sign_extD),
        //EX
        .reg_dstE(reg_dstE),
        .alu_srcE(alu_srcE),
        //MEM
        .mem_read_enM(mem_read_enM),
        .mem_write_enM(mem_write_enM),
        //WB
        .reg_write_enW(reg_write_enW),
        .mem_to_regW(mem_to_regW)
    );

    alu_decoder alu_decoder0(
        .clk(clk),
        .instrD(instrD),

        .alu_controlE(alu_controlE)
    );

//IF
    assign pc_plus4F = pcF + 4;

    mux2 #(32) mux2_pc(pc_plus4F, pc_branchD, branch_takeD, pc_next);

    pc_reg pc_reg0(
        .clk(clk),
        .en(1'b1),
        .rst(rst),
        .pc_next(pc_next),

        .pc(pcF),
        .ce(inst_enF)
    );
    assign inst_addrF = pcF;
//IF_ID
    if_id if_id0(
        .clk(clk),
        .pcF(pcF),
        .pc_plus4F(pc_plus4F),
        
        .pcD(pcD),
        .pc_plus4D(pc_plus4D)
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
        .we3(reg_write_enW),
        .ra1(rsD), .ra2(rtD), .wa3(reg_writeW), 
        .wd3(resultW),

        .rd1(rd1D), .rd2(rd2D)
    );

    branch_predict branch_predict0(
        .instrD(instrD),
        .rd1D(rd1D),
        .rd2D(rd2D),

        .branch_takeD(branch_takeD)
    );

//ID_EX
    id_ex id_ex0(
        .clk(clk),
        .pcD(pcD),
        .rd1D(rd1D), .rd2D(rd2D),
        .rtD(rtD), .rdD(rdD),
        .immD(immD),
        .pc_plus4D(pc_plus4D),
        
        .pcE(pcE),
        .rd1E(rd1E), .rd2E(rd2E),
        .rtE(rtE), .rdE(rdE),
        .immE(immE),
        .pc_plus4E(pc_plus4E)
    );
//EX
    alu alu0(
        .src_aE(src_aE), .src_bE(src_bE),
        .alu_controlE(alu_controlE),

        .alu_outE(alu_outE)
    );

    //mux write reg
    mux4 #(5) mux4_reg_dst(rdE, rtE, 5'd31, 5'b0, reg_dstE, reg_writeE);

    //mux alu
    mux2 #(32) mux2_alu_srcb(rd2E, immE, alu_srcE, src_bE);
//EX_MEM
    ex_mem ex_mem0(
        .clk(clk),
        .pcE(pcE),
        .alu_outE(alu_outE),
        .rd2E(rd2E),
        .reg_writeE(reg_writeE),

        .pcM(pcM),
        .alu_outM(alu_outM),
        .rd2M(rd2M),
        .reg_writeM(reg_writeM)
    );
//MEM
    assign mem_addrM = alu_outM;
    assign mem_wdataM = rd2M;

    assign mem_enM = mem_read_enM | mem_write_enM; //读或者写
    assign mem_wenM = {4{mem_write_enM}};           //暂时只有sw
//MEM_WB
    mem_wb mem_wb0(
        .clk(clk),
        .pcM(pcM),
        .alu_outM(alu_outM),
        .reg_writeM(reg_writeM),

        .pcW(pcW),
        .alu_outW(alu_outW),
        .reg_writeW(reg_writeW)
    );

//WB
    mux2 #(32) mux2_mem_to_reg(alu_outW, mem_rdataW, mem_to_regW, resultW);


endmodule