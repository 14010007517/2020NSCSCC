module pc #(parameter WIDTH = 32)
           (input clk,
            en,
            rst,
            input [WIDTH-1:0] pc,
            output reg [WIDTH-1:0] pc_next);
    
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            pc_next <= 32'hbfbffffc;
        end
        else if (en) begin
            pc_next <= pc;
        end
    end
    
endmodule
