`include "defines.vh"

module mem_ctrl(
    input wire [31:0] instrM,
    input wire [31:0] addr,

    input wire [31:0] data_wdataM,
    output wire [31:0] mem_wdataM,
    output wire [3:0] mem_wenM,

    input wire [31:0] mem_rdataM,
    output wire [31:0] data_rdata,

    output wire mem_error_enM,
    output wire addr_error_sw, addr_error_lw
);
    wire [3:0] mem_byte_wen;
    wire [5:0] op_code;

    wire instr_lw, instr_lh, instr_lb, instr_sw, instr_sh, instr_sb, instr_lhu;
    wire addr_W, addr_H, addr_H2, addr_B1, addr_B3;
    

    assign op_code = instrM[31:26];

    assign addr_W = ~(|(addr[1:0] ^ 2'b00));
    assign addr_H = ~(|(addr[1:0] ^ 2'b00)) | ~(|(addr[1:0] ^ 2'b10));
    assign addr_H2 = ~(|(addr[1:0] ^ 2'b10));
    assign addr_B1 = ~(|(addr[1:0] ^ 2'b01));
    assign addr_B3 = ~(|(addr[1:0] ^ 2'b11));

    assign instr_lw = ~(|(op_code ^ `EXE_LW));
    assign instr_lb = ~(|(op_code ^ `EXE_LB)) | ~(|(op_code ^ `EXE_LBU)) ;
    assign instr_lh = ~(|(op_code ^ `EXE_LH)) | ~(|(op_code ^ `EXE_LHU)) ;
    assign instr_lbu = ~(|(op_code ^ `EXE_LBU)) ;
    assign instr_lhu = ~(|(op_code ^ `EXE_LHU)) ;
    assign instr_sw = ~(|(op_code ^ `EXE_SW)); 
    assign instr_sh = ~(|(op_code ^ `EXE_SH));
    assign instr_sb = ~(|(op_code ^ `EXE_SB));


    assign addr_error_sw = (instr_sw & ~addr_W)
                        | (instr_sh & ~addr_H);
    assign addr_error_lw = (instr_lw & ~addr_W)
                        | (instr_lh & ~addr_H);
    assign mem_error_enM = ~addr_error_lw & ~addr_error_sw; 


// wdata  and  byte_wen
    assign mem_wenM = ( {4{( instr_sw & addr_W )}} & 4'b1111)
                        | ( {4{( instr_sh & addr_W  )}} & 4'b0011)
                        | ( {4{( instr_sh & addr_H2 )}} & 4'b1100)
                        | ( {4{( instr_sb & addr_W  )}} & 4'b0001)
                        | ( {4{( instr_sb & addr_B1 )}} & 4'b0010)
                        | ( {4{( instr_sb & addr_H2 )}} & 4'b0100)
                        | ( {4{( instr_sb & addr_B3 )}} & 4'b1000);

// rdata
// data ram 按字寻址
    assign mem_wdataM =   ({ 32{instr_sw}} & data_wdataM)
                        | ( {32{instr_sh}}  & {2{data_wdataM[15:0]} })
                        | ( {32{instr_sb}}  & {4{data_wdataM[7:0]}  });
// 所以还是取了整个字：    
    assign data_rdata =  ( {32{instr_lw}}   & mem_rdataM)
                        | ( {32{ instr_lh   & addr_W}}   & { {16{mem_rdataM[15]}},  mem_rdataM[15:0]    })
                        | ( {32{ instr_lh   & addr_H2}}  & { {16{mem_rdataM[31]}},  mem_rdataM[31:16]   })
                        | ( {32{ instr_lhu  & addr_W}}   & {  16'b0,                mem_rdataM[15:0]    })
                        | ( {32{ instr_lhu  & addr_H2}}  & {  16'b0,                mem_rdataM[31:16]   })
                        | ( {32{ instr_lb   & addr_W}}   & { {24{mem_rdataM[7]}},   mem_rdataM[7:0]     })
                        | ( {32{ instr_lb   & addr_B1}}  & { {24{mem_rdataM[15]}},  mem_rdataM[15:8]    })
                        | ( {32{ instr_lb   & addr_H2}}  & { {24{mem_rdataM[23]}},  mem_rdataM[23:16]   })
                        | ( {32{ instr_lb   & addr_B3}}  & { {24{mem_rdataM[31]}},  mem_rdataM[31:24]   })
                        | ( {32{ instr_lbu  & addr_W}}   & {  24'b0 ,               mem_rdataM[7:0]     })
                        | ( {32{ instr_lbu  & addr_B1}}  & {  24'b0 ,               mem_rdataM[15:8]    })
                        | ( {32{ instr_lbu  & addr_H2}}  & {  24'b0 ,               mem_rdataM[23:16]   })
                        | ( {32{ instr_lbu  & addr_B3}}  & {  24'b0 ,               mem_rdataM[31:24]   });
endmodule