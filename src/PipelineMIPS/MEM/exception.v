`include "defines.vh"

module exception(
   input rst,
   input ri, break, syscall, overflow, addrErrorSw, addrErrorLw, pcError, eretM,
   input [31:0] cp0_status, cp0_cause, cp0_epc,
   input [31:0] pcM,
   input [31:0] alu_outM,

   output [31:0] except_type,
   output flush_exception,
   output [31:0] pc_exception,
   output pc_trap,
   output [31:0] badvaddrM
);

   //INTERUPT
   wire int;
   //             //IE             //EXL            
   assign int =   cp0_status[0] && ~cp0_status[1] && (
                     //IM                 //IP
                  ( |(cp0_status[9:8] & cp0_cause[9:8]) ) ||        //soft interupt
                  ( |(cp0_status[15:10] & cp0_cause[15:10]) )           //hard interupt
   );
   // 全局中断开启,且没有例外在处理,识别软件中断或者硬件中断;

   assign except_type =    (int)                   ? `EXC_TYPE_INT :
                           (addrErrorLw | pcError) ? `EXC_TYPE_ADEL :
                           (ri)                    ? `EXC_TYPE_RI :
                           (syscall)               ? `EXC_TYPE_SYS :
                           (break)                 ? `EXC_TYPE_BP :
                           (addrErrorSw)           ? `EXC_TYPE_ADES :
                           (overflow)              ? `EXC_TYPE_OV :
                           (eretM)                 ? `EXC_TYPE_ERET :
                                                     `EXC_TYPE_NOEXC;
   //interupt pc address
   // assign pc_exception =      (except_type == `EXC_TYPE_NOEXC) ? `ZeroWord:
   //                         (except_type == `EXC_TYPE_ERET)? cp0_epc :
   //                         32'hbfc0_0380;
   // assign pc_trap =        (except_type == `EXC_TYPE_NOEXC) ? 1'b0:
   //                         1'b1;
   // assign flush_exception =   (except_type == `EXC_TYPE_NOEXC) ? 1'b0:
   //                         1'b1;
   // assign badvaddrM =      (pcError) ? pcM : alu_outM;

   // // 提高性能;
    assign pc_exception    =  (int) | (addrErrorLw | pcError | addrErrorSw) | (ri) | (break) | (overflow) |(syscall) ? 32'hbfc0_0380 : 
                              (eretM)  ?     cp0_epc :
                              `ZeroWord;

    assign pc_trap         =  (int) | (addrErrorLw | pcError | addrErrorSw) | (ri) | (break) | (overflow) | (eretM) | (syscall);

    assign flush_exception =  pc_trap;

    assign badvaddrM       =  (pcError) ? pcM : alu_outM       ;
   
endmodule
