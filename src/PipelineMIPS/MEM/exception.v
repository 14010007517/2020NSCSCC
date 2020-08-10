`include "defines.vh"

module exception(
   input rst,
   input ri, break, syscall, overflow, addrErrorSw, addrErrorLw, pcError, eretM,
   input [31:0] cp0_status, cp0_cause, cp0_epc, cp0_ebase,
   input [31:0] pcM,
   input [31:0] alu_outM,

   output [4:0] except_type,     //异常类型（同Cause CP0寄存器中的编码）
   output flush_exception,
   output [31:0] pc_exception,
   output pc_trap,
   output [31:0] badvaddrM
);

   //INTERUPT
   wire int;
   //             //IE             //EXL            
   assign int =   cp0_status[`IE_BIT] && ~cp0_status[`EXL_BIT] && (
                     //IM                 //IP
                  ( |(cp0_status[`IM1_IM0_BITS] & cp0_cause[`IP1_IP0_BITS]) ) ||        //soft interupt
                  ( |(cp0_status[`IM7_IM2_BITS] & cp0_cause[`IP7_IP2_BITS]) )           //hard interupt
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

   wire BEV;
   assign BEV = cp0_status[`BEV_BIT];

   wire tlb_refill;
   assign tlb_refill = 1'b0;

   wire [31:0] base, offset;

   assign base   = BEV ? 32'hbfc0_0200 : cp0_ebase;
   assign offset = tlb_refill ? 32'b0 : 32'h180;

   assign pc_exception = eretM ? cp0_epc : base + offset;

   assign pc_trap         =  (int) | (addrErrorLw | pcError | addrErrorSw) | (ri) | (break) | (overflow) | (eretM) | (syscall);

   assign flush_exception =  pc_trap;

   assign badvaddrM       =  (pcError) ? pcM : alu_outM       ;
   
endmodule
