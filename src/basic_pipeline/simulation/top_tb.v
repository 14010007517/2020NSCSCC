`timescale 1ns / 1ps

module testbench();
    reg clk;
	reg rst_n;

	wire[31:0] writedata,dataadr;
	wire memwrite;

	soc_top soc(rst_n, clk);

	initial begin
		rst_n = 0;
		#133 rst_n = 1;
	end

	always begin
		clk <= 1;
		#10;
		clk <= 0;
		#10;
	
	end
endmodule