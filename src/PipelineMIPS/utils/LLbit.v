
module LLbit(
    input wire clk,
    input wire rst,
    
    //when an exception occurs, flash = 1, otherwise flash = 0
    input wire flush,

    // write operation
    input wire llE,
   
    output reg LLbit
    );

    always @ (posedge clk) begin
        LLbit <= rst | flush ? 1'b0 : 
                   llE ? 1'b1 : LLbit;
    end
endmodule
