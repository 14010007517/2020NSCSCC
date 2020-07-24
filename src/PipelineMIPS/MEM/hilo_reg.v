`timescale 1ns / 1ps
`include "defines.vh"

module hilo_reg(
                input wire        clk,rst,we, //both write lo and hi
                input wire [31:0] instrM,

                input wire [63:0] hilo_i,
                output wire [31:0] hilo_o
                );
   wire [63:0] hilo_ii;
   reg [63:0] hilo;
   always @(posedge clk) begin
      if(we)
         hilo <= hilo_ii;
      else
         hilo <= hilo;
   end
   
   assign hilo_ii = ( {64{~rst & we}} & hilo_i );

   // 读cp0逻辑；
   wire mfhi;
   wire mflo;
   assign mfhi = ~(|(instrM[31:26] ^ `EXE_R_TYPE)) & ~(|(instrM[5:0] ^ `EXE_MFHI));
   assign mflo = ~(|(instrM[31:26] ^ `EXE_R_TYPE)) & ~(|(instrM[5:0] ^ `EXE_MFLO));

   assign hilo_o = ({32{mfhi}} & hilo[63:32]) | ({32{mflo}} & hilo[31:0]);
endmodule

