module hit_rate(
    input wire clk, rst,
    input wire i_hit,
    input wire d_hit,
    input wire i_miss,
    input wire d_miss,
    input wire stallF
);

    reg [31:0] i_d, ix_dx, i_dx, ix_d;
    always@(posedge clk) begin
        i_d <= rst ? 0:
                i_hit & d_hit ? i_d + 1:
                i_d;
        i_dx <= rst ? 0:
                i_hit & d_miss ? i_dx + 1:
                i_dx;
        ix_d <= rst ? 0:
                i_miss & d_hit ? ix_d + 1:
                ix_d;
        ix_dx <= rst ? 0:
                i_miss & d_miss ? ix_dx + 1:
                ix_dx;
    end
endmodule
