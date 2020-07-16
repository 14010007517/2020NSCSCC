module if_id(
    input clk,
    input wire [31:0] pcF,
    input wire [31:0] pc_plus4F,


    output reg [31:0] pcD,
    output reg [31:0] pc_plus4D
);

    always @(posedge clk) begin
        pcD <= pcF;
        pc_plus4D <= pc_plus4F;
    end
endmodule