module id_ex (
    input wire clk, rst,
    input wire stallE,
    input wire flushE,
    input wire [31:0] pcD,
    input wire [31:0] rd1D, rd2D,
    input wire [4:0] rsD, rtD, rdD,
    input wire [31:0] immD,
    input wire [31:0] pc_plus4D,
    input wire [31:0] instrD,
    input wire [31:0] pc_branchD,
    input wire pred_takeD,
    input wire branchD,
    input wire jump_conflictD,


    output reg [31:0] pcE,
    output reg [31:0] rd1E, rd2E,
    output reg [4:0] rsE, rtE, rdE,
    output reg [31:0] immE,
    output reg [31:0] pc_plus4E,
    output reg [31:0] instrE,
    output reg [31:0] pc_branchE,
    output reg pred_takeE,
    output reg branchE,
    output reg jump_conflictE
);
    always @(posedge clk) begin
        if(rst | flushE) begin
            pcE <= 0;
            rd1E <= 0;
            rd2E <= 0;
            rsE <= 0;
            rtE <= 0;
            rdE <= 0;
            immE <= 0;
            pc_plus4E <= 0;
            instrE <= 0;
            pc_branchE <= 0;
            pred_takeE <= 0;
            branchE <= 0;
            jump_conflictE <= 0;
        end
        else if(~stallE) begin
            pcE <= pcD;
            rd1E <= rd1D;
            rd2E <= rd2D;
            rsE <= rsD;
            rtE <= rtD;
            rdE <= rdD;
            immE <= immD;
            pc_plus4E <= pc_plus4D;
            instrE <= instrD;
            pc_branchE <= pc_branchD;
            pred_takeE <= pred_takeD;
            branchE <= branchD;
            jump_conflictE <= jump_conflictD;
        end
    end
endmodule