module regfile(
    input         clk,

    input  [4:0]  raddr1,
    output [31:0] rdata1,

    input  [4:0]  raddr2,
    output [31:0] rdata2,

    input         we,
    input  [4:0]  waddr,
    input  [31:0] wdata
);

	reg  [31:0] r [31:0];

	assign rdata1 = r[raddr1];
	assign rdata2 = r[raddr2];

	always @(posedge clk)
	begin
		r[0] <= 32'b0;
		if (we && (|waddr)) begin
			r[waddr] <= wdata;
		end
	end

endmodule
