module id_ex (
    input wire clk,
    input wire [31:0] pcD,
    input wire [31:0] rd1D, rd2D,
    input wire [4:0] rtD, rdD,
    input wire [31:0] immD,
    input wire [31:0] pc_plus4D,
    input wire [31:0] instrD,
    input wire [4:0] rsD, rtD,

    output reg [31:0] pcE,
    output reg [31:0] rd1E, rd2E,
    output reg [4:0] rtE, rdE,
    output reg [31:0] immE,
    output reg [31:0] pc_plus4E,
    output wire [31:0] instrE,
    output wire [4:0] rsE, rtE
);
    always @(posedge clk) begin
        pcE <= pcD;
        rd1E <= rd1D;
        rd2E <= rd2D;
        rtE <= rtD;
        rdE <= rdD;
        immE <= immD;
        pc_plus4E <= pc_plus4D;
        instrE <= instrD;
        rsE <= rsD;
        rtE <= rtD;
    end
endmodule