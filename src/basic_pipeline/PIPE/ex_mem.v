module ex_mem (
    input wire clk,
    input wire [31:0] pcE,
    input wire [31:0] alu_outE,
    input wire [31:0] rd2E,
    input wire [4:0] reg_writeE,

    output reg [31:0] pcM,
    output reg [31:0] alu_outM,
    output reg [31:0] rd2M,
    output reg [4:0] reg_writeM
);
    always @(posedge clk) begin
		pcM <= pcE;
		alu_outM <= alu_outE;
		rd2M <= rd2E;
		reg_writeM <= reg_writeE;
    end
endmodule