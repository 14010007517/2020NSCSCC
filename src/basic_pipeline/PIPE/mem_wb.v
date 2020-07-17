module mem_wb (
    input wire clk,
    input wire [31:0] pcM,
    input wire [31:0] alu_outM,
    input wire [4:0] reg_writeM,
    input wire reg_write_enM,

    output reg [31:0] pcW,
    output reg [31:0] alu_outW,
    output reg [4:0] reg_writeW
    output wire reg_write_enW
);
    always @(posedge clk) begin
        pcW <= pcM;
        alu_outW <= alu_outM;
        reg_writeW <= reg_writeM;
        reg_write_enW <= reg_write_enM;
    end
endmodule