`include "defines.vh"

module exception(
   input rst,
   input ri, break, syscall, overflow, addrErrorSw, addrErrorLw, pcError, eretM,
      //tlb exception
   input wire mem_read_enM,
   input wire mem_write_enM,
   input wire inst_tlb_refill,
   input wire inst_tlb_invalid,
   input wire data_tlb_refill,
   input wire data_tlb_invalid,
   input wire data_tlb_modify,

   input [31:0] cp0_status, cp0_cause, cp0_epc, cp0_ebase,
   input [31:0] pcM,
   input [31:0] alu_outM,

   output [4:0] except_type,     //异常类型（同Cause CP0寄存器中的编码）
   output flush_exception,
   output [31:0] pc_exception,
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

   //TLB
   wire tlb_mod, tlb_tlbl, tlb_tlbs;
   assign tlb_mod = data_tlb_modify;
   assign tlb_tlbl = inst_tlb_refill | inst_tlb_invalid | mem_read_enM & (data_tlb_refill | data_tlb_invalid);
   assign tlb_tlbs = mem_write_enM & (data_tlb_refill | data_tlb_invalid);

   assign except_type =    (int)                   ? `EXC_CODE_INT :
                           (addrErrorLw | pcError) ? `EXC_CODE_ADEL :
                           (tlb_mod)               ? `EXC_CODE_MOD :
                           (tlb_tlbl)              ? `EXC_CODE_TLBL :
                           (tlb_tlbs)              ? `EXC_CODE_TLBS :
                           (ri)                    ? `EXC_CODE_RI :
                           (syscall)               ? `EXC_CODE_SYS :
                           (break)                 ? `EXC_CODE_BP :
                           (addrErrorSw)           ? `EXC_CODE_ADES :
                           (overflow)              ? `EXC_CODE_OV :
                           (eretM)                 ? `EXC_CODE_ERET :
                                                     `EXC_CODE_NOEXC;

   wire BEV;
   assign BEV = cp0_status[`BEV_BIT];

   wire tlb_refill;
   assign tlb_refill = inst_tlb_refill | data_tlb_refill;

   wire [31:0] base, offset;

   assign base   = BEV ? 32'hbfc0_0200 : cp0_ebase;
   assign offset = tlb_refill ? 32'b0 : 32'h180;

   assign pc_exception = eretM ? cp0_epc : base + offset;

   assign flush_exception =  (int) | (addrErrorLw | pcError | addrErrorSw) | (ri) | (break) | (overflow) | (eretM) | (syscall);

   assign badvaddrM       =  (pcError | inst_tlb_invalid | inst_tlb_refill) ? pcM : alu_outM;
   
endmodule
