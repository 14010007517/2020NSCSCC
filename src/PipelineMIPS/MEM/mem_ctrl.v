`include "defines.vh"

module mem_ctrl(
    input wire [13:0] l_s_typeM,
    input wire [1:0] addr,

    input wire [31:0] data_wdataM,  //rt_value
    output wire [31:0] mem_wdataM,
    output wire [3:0] mem_wenM,

    input wire [31:0] mem_rdataM,
    output wire [31:0] data_rdataM,

    output wire addr_error_sw, addr_error_lw
);
    wire [31:0] rt_valueM;
    assign rt_valueM = data_wdataM;

    wire ll, sc, lw, lh, lhu, lb, lbu, sw, sh, sb;
    wire lwl, lwr, swl, swr;
    wire addr_B0, addr_B2, addr_B1, addr_B3;
    
	assign {lwl, lwr, swl, swr, ll, sc, lw, lh, lhu, lb, lbu, sw, sh, sb} = l_s_typeM;

    assign addr_error_sw = ( ( sw | sc ) & ~addr_B0)
                        | (  sh & ~(addr_B0 | addr_B2));
    assign addr_error_lw = ( (lw | ll) & ~addr_B0)
                        | (( lh | lhu ) & ~(addr_B0 | addr_B2));

    

    assign addr_B0 = ~(|(addr[1:0] ^ 2'b00));
    assign addr_B2 = ~(|(addr[1:0] ^ 2'b10));
    assign addr_B1 = ~(|(addr[1:0] ^ 2'b01));
    assign addr_B3 = ~(|(addr[1:0] ^ 2'b11));

// wdata  and  byte_wen
    assign mem_wenM =     ( {4{( (sw | sc) & addr_B0  )}} & 4'b1111)
                        | ( {4{( sh & addr_B0  )}} & 4'b0011)
                        | ( {4{( sh & addr_B2  )}} & 4'b1100)
                        | ( {4{( sb & addr_B0  )}} & 4'b0001)
                        | ( {4{( sb & addr_B1  )}} & 4'b0010)
                        | ( {4{( sb & addr_B2  )}} & 4'b0100)
                        | ( {4{( sb & addr_B3  )}} & 4'b1000)
                        | ( {4{(swl & addr_B3  )}} & 4'b0001)
                        | ( {4{(swl & addr_B2  )}} & 4'b0011)
                        | ( {4{(swl & addr_B1  )}} & 4'b0111)
                        | ( {4{(swl & addr_B0  )}} & 4'b1111)
                        | ( {4{(swr & addr_B3  )}} & 4'b1111)
                        | ( {4{(swr & addr_B2  )}} & 4'b1110)
                        | ( {4{(swr & addr_B1  )}} & 4'b1100)
                        | ( {4{(swr & addr_B0  )}} & 4'b1000);

// rdata
// data ram 按字寻址
    assign mem_wdataM =   ({ 32{(sw | sc) }} & data_wdataM)
                        | ( {32{sh}}  & {2{data_wdataM[15:0]} })
                        | ( {32{sb}}  & {4{data_wdataM[7:0]}  })
                        | ( {32{swl & addr_B3  }} & {24'b0, data_wdataM[31:24]})
                        | ( {32{swl & addr_B2  }} & {16'b0, data_wdataM[31:16]})
                        | ( {32{swl & addr_B1  }} & { 8'b0, data_wdataM[31:8 ]})
                        | ( {32{swl & addr_B0  }} & data_wdataM)
                        | ( {32{swr & addr_B3  }} & data_wdataM)
                        | ( {32{swr & addr_B2  }} & {data_wdataM[23:0],  8'b0})
                        | ( {32{swr & addr_B1  }} & {data_wdataM[15:0], 16'b0})
                        | ( {32{swr & addr_B0  }} & {data_wdataM[7 :0], 24'b0});
    
    assign data_rdataM =  ( {32{(lw | ll)}}  & mem_rdataM)
                        | ( {32{lwl   & addr_B3}}  & {mem_rdataM[7:0 ], rt_valueM[23:0]} )
                        | ( {32{lwl   & addr_B2}}  & {mem_rdataM[15:0], rt_valueM[15:0]} )
                        | ( {32{lwl   & addr_B1}}  & {mem_rdataM[23:0], rt_valueM[7:0 ]} )
                        | ( {32{lwl   & addr_B0}}  &  mem_rdataM )
                        | ( {32{lwr   & addr_B3}}  &  mem_rdataM )
                        | ( {32{lwr   & addr_B2}}  & {rt_valueM[31:24], mem_rdataM[31:8 ]} )
                        | ( {32{lwr   & addr_B1}}  & {rt_valueM[31:16], mem_rdataM[31:16]} )
                        | ( {32{lwr   & addr_B0}}  & {rt_valueM[31:8 ], mem_rdataM[31:24]} )
                        | ( {32{ lh   & addr_B0}}  & { {16{mem_rdataM[15]}},  mem_rdataM[15:0]    })
                        | ( {32{ lh   & addr_B2}}  & { {16{mem_rdataM[31]}},  mem_rdataM[31:16]   })
                        | ( {32{ lhu  & addr_B0}}  & {  16'b0,                mem_rdataM[15:0]    })
                        | ( {32{ lhu  & addr_B2}}  & {  16'b0,                mem_rdataM[31:16]   })
                        | ( {32{ lb   & addr_B0}}  & { {24{mem_rdataM[7]}},   mem_rdataM[7:0]     })
                        | ( {32{ lb   & addr_B1}}  & { {24{mem_rdataM[15]}},  mem_rdataM[15:8]    })
                        | ( {32{ lb   & addr_B2}}  & { {24{mem_rdataM[23]}},  mem_rdataM[23:16]   })
                        | ( {32{ lb   & addr_B3}}  & { {24{mem_rdataM[31]}},  mem_rdataM[31:24]   })
                        | ( {32{ lbu  & addr_B0}}  & {  24'b0 ,               mem_rdataM[7:0]     })
                        | ( {32{ lbu  & addr_B1}}  & {  24'b0 ,               mem_rdataM[15:8]    })
                        | ( {32{ lbu  & addr_B2}}  & {  24'b0 ,               mem_rdataM[23:16]   })
                        | ( {32{ lbu  & addr_B3}}  & {  24'b0 ,               mem_rdataM[31:24]   });
endmodule