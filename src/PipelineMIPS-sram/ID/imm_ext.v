module imm_ext(
    input wire [15:0] imm,
    input wire sign_ext,
    output wire [31:0] imm_ext
);
    assign imm_ext = sign_ext ? {{16{imm[15]}}, imm[15:0]}:
                                {16'b0, imm[15:0]}
                    ;
endmodule