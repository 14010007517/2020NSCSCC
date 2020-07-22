`timescale 1ns / 1ps
`include "defines.vh"

module hilo_reg(
                input wire        clk,rst,we, //both write lo and hi
                input wire [31:0] instrM,

                input wire [63:0] hilo_i,
                output wire [31:0] hilo_o
                );
// 方案1
   // always @(posedge clk) begin
   //    if(rst) begin
   //       hilo_o <= 0;
   //    end else if (we) begin
   //       hilo_o <= hilo_i;
   //    end 
   // end

// 方案2
// 少了一级比较
   wire [63:0] hilo_ii;
   reg [63:0] hilo;
   always @(posedge clk) begin
      if(we)
         hilo <= hilo_ii;
      else
         hilo <= hilo_ii;
   end
   assign hilo_ii = ( {64{rst}} & 64'd0 )
                  ||( {64{~rst & we}} & hilo_i);
   // 读cp0逻辑；
   wire hi;
   wire lo;
   assign hi = ~(|(instrM[31:26] ^ `EXE_R_TYPE)) & ~(|(instrM[5:0] ^ `EXE_MFHI));
   assign lo = ~(|(instrM[31:26] ^ `EXE_R_TYPE)) & ~(|(instrM[5:0] ^ `EXE_MFLO));

   assign hilo_o = ({32{hi}} & hilo[63:32]) | ({32{lo}} & hilo[31:0]);

// 方案3
// 少了两级比较
// 同时将hilo_o声明为inout变量；
   // wire [63:0] hilo_ii;
   // always @(posedge clk) begin
   //    hilo_o <= hilo_ii
   // end
   // assign hilo_ii = ( {64{rst}} & 64'd0 )
   //                ||( {64{~rst & en}} & hilo_i)
   //                ||( {64{~rst & ~en}} & hilo_o);



endmodule

