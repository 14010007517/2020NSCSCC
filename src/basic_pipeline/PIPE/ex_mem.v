module ex_mem (
    input wire clk, rst,
    input wire stallM,
    input wire [31:0] pcE,
    input wire [31:0] alu_outE,
    input wire [31:0] rd2E,
    input wire [4:0] reg_writeE,
    input wire [31:0] instrE,

    output reg [31:0] pcM,
    output reg [31:0] alu_outM,
    output reg [31:0] rd2M,
    output reg [4:0] reg_writeM,
    output reg [31:0] instrM
);
    always @(posedge clk) begin
        if(rst) begin
            pcM <= 0;
            alu_outM <= 0;
            rd2M <= 0;
            reg_writeM <= 0;
            instrM <= 0;
        end
        if(~stallM) begin
            pcM <= pcE;
            alu_outM <= alu_outE;
            rd2M <= rd2E;
            reg_writeM <= reg_writeE;
            instrM <= instrE;
        end
    end
endmodule