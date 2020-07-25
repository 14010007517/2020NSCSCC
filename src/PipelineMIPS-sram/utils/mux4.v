module mux4 #(parameter WIDTH=32) (
    input wire [WIDTH-1:0] x0, x1, x2, x3,
    input wire [1:0] sel,

    output wire [WIDTH-1:0] y
);
    assign y = sel[1] ? (sel[0] ? x3: x2):
                        (sel[0] ? x1: x0);
    
endmodule