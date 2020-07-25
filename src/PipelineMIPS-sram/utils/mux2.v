module mux2 #(parameter WIDTH=32) (
    input wire [WIDTH-1:0] x0, x1,
    input wire sel,

    output wire [WIDTH-1:0] y
);
    assign y = sel ? x1 : x0;
endmodule