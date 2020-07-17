module hazzard (
    input wire [31:0] instrE,//no use
    input wire [31:0] instrM,//no use

    input wire [4:0] rsE,
    input wire [4:0] rtE,
    input wire reg_write_enM,
    input wire reg_write_enW,
    input wire [4:0] reg_writeM,
    input wire [4:0] reg_writeW,

    input wire mem_read_enM,


    output wire stallF, stallD, stallE,
    output wire flushM,

    output wire [1:0] forward_aE, forward_bE
);
    wire stallF, stallD, stallE, stallM;
    wire flushF, flushD, flushE, flushM;

    wire stall_lw;  //add, lw 数据冲突无法仅靠数据前推解决（MEM阶段无法从内存取得数据），需要先暂停形成一个气泡，再前推

    wire [1:0] forward_aE, forward_bE; //00-> NONE, 01-> MEM, 10-> WB (LW instr)

    assign forward_aE = (rsE != 0) && reg_write_enM && (rsE == reg_writeM) ? 2'b01 :
                        (rsE != 0) && reg_write_enW && (rsE == reg_writeW) ? 2'b10 :
                        2'b00;
    assign forward_bE = (rtE != 0) && reg_write_enM && (rtE == reg_writeM) ? 2'b01 :
                        (rtE != 0) && reg_write_enW && (rtE == reg_writeW) ? 2'b10 :
                        2'b00;

    assign stall_lw = mem_read_enM && (
                        ((rsE != 0) && reg_write_enM && (rsE == reg_writeM)) ||
                        ((rtE != 0) && reg_write_enM && (rtE == reg_writeM))
                    );
    
    assign stallF = stall_lw;
    assign stallD = stall_lw;
    assign stallE = stall_lw;
    assign flushM = stall_lw;
endmodule