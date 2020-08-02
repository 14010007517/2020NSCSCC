module decoder2x4 (
    // input wire [WIDTH-1 : 0] x,
    input wire [1 : 0] x,

    // output wire [(1<<WIDTH-1 : 0] y
    output reg [3 : 0] y

);
    always @(x) begin
        case(x)
            2'b00 : y =  4'b0001;
            2'b01 : y =  4'b0010;
            2'b10 : y =  4'b0100;
            2'b11 : y =  4'b1000;
        endcase
    end
endmodule