module IF(input wire clk,
          input wire rst,
          input wire en,
          input wire [31:0] pc,
          output wire [31:0] pc_next);
        
        pc #(32) PC(.clk(clk), .en(), .rst(rst), .pc(pc), .pc_next(pc_next));


endmodule