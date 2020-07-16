module mem_wb (
    input wire clk,
    input wire [31:0] pcM,
    input wire [31:0] alu_outM,
    input wire [4:0] reg_writeM,

    output reg [31:0] pcW,
    output reg [31:0] alu_outW,
    output reg [4:0] reg_writeW
);
    always @(posedge clk) begin
        pcW <= pcM;
        alu_outW <= alu_outM;
        reg_writeW <= reg_writeM;
    end
endmodule