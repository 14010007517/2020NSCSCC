`timescale 1ns / 1ps

`include "defines.vh"

module cp0_reg(
      input wire clk,rst,
      input wire [5:0] ext_int,
      input wire stallW,      

      //mtc0 & mfc0
      input wire [4:0] addr,              
      input wire [2:0] sel,               
      input wire wen,                     //写cp0使能
      input wire [31:0] wdata,            //写cp0数据
      output reg [31:0] rdata,            //读cp0数据（组合逻辑读）

      //异常处理
      input wire flush_exception,         //异常
      input wire [4:0] except_type,       //异常类型（同异常码）
      input wire [31:0] pcM,              //发生异常指令的pc
      input wire is_in_delayslot,         //异常指令是否位于延迟槽
      input wire [31:0] badvaddr,         //最近一次导致发生地址错例外的虚地址(load/store, pc未对齐地址)

      // tlb处理
      input wire [2:0] tlb_typeM,                 //tlb写cp0使能
      input wire [31:0] entry_lo0_in,
      input wire [31:0] entry_lo1_in,
      input wire [31:0] page_mask_in,
      input wire [31:0] entry_hi_in,
      input wire [31:0] index_in,

      //cp0寄存器输出
      output wire [31:0] cp0_statusW, cp0_causeW, cp0_epcW, cp0_ebaseW,
      output wire [31:0] entry_hi_W, 
      output wire [31:0] page_mask_W,
      output wire [31:0] entry_lo0_W,
      output wire [31:0] entry_lo1_W,
      output wire [31:0] index_W,
      output wire [31:0] random_W
);


   //-----------------cp0寄存器-------------------
   reg [31:0] index_reg;
   reg [31:0] random_reg;
   reg [31:0] entry_lo0_reg;
   reg [31:0] entry_lo1_reg;
   reg [31:0] context_reg;
   reg [31:0] page_mask_reg;
   reg [31:0] wired_reg;

   reg [31:0] badvaddr_reg;
   reg [31:0] count_reg;
   reg [31:0] entry_hi_reg;
   reg [31:0] compare_reg;
   reg [31:0] status_reg;
   reg [31:0] cause_reg;
   reg [31:0] epc_reg;
   reg [31:0] prid_reg;    //15, 0

   reg [31:0] ebase_reg;   //15, 1
   reg [31:0] config_reg;  //16, 0
   reg [31:0] config1_reg; //16, 1
   //-------------------------------------------

   //cp0输出
   wire [31:0] cp0_statusW, cp0_causeW, cp0_epcW;

   assign cp0_statusW   =  status_reg;
   assign cp0_causeW    =  cause_reg;
   assign cp0_epcW      =  epc_reg;
   assign cp0_ebaseW    =  ebase_reg;

   assign entry_hi_W    =  entry_hi_reg;
   assign page_mask_W   =  page_mask_reg;
   assign entry_lo0_W   =  entry_lo0_reg;
   assign entry_lo1_W   =  entry_lo1_reg;
   assign index_W       =  index_reg;
   assign random_W      =  random_reg;


   //other
   reg interval_flag;   //间隔一个时钟递增时钟计数器
   reg timer_int;       //计时器中断

   wire [31:0] pc_minus4;
   assign pc_minus4 = pcM - 4;

   //always
   always @(posedge clk) begin
      if(rst) begin
         //cp0初始化
         status_reg    <= `STATUS_INIT;  //BEV置为1
         cause_reg     <= `CAUSE_INIT;
         count_reg     <= 32'b0;

         ebase_reg      <= 32'h8000_0000;

         config_reg     <= `CONFIG_INIT;
         config1_reg    <= `CONFIG1_INIT;
         prid_reg       <= `PRID_INIT;

         wired_reg      <= 32'b0;

         //other
         interval_flag <= 1'b0;
         timer_int <= 1'b0;
      end
      else begin
         //计时器加1
         interval_flag           <=~interval_flag;
         count_reg               <= interval_flag ?
                                    count_reg + 1 :
                                    count_reg;
         
         //外部中断
         cause_reg[`IP7_IP2_BITS] <= ~stallW ? ext_int : 0;

         //计时器中断
         if(compare_reg != 32'b0 && count_reg == compare_reg) begin
            timer_int <= 1'b1;
         end

         //异常处理
         if(flush_exception) begin
            if(&except_type) begin //eret
               status_reg[`EXL_BIT] <= 1'b0;
            end
            else begin
               epc_reg <= is_in_delayslot ? pc_minus4 : pcM;
               cause_reg[`BD_BIT] <= is_in_delayslot;

               status_reg[`EXL_BIT] <= 1'b1;
               cause_reg[`EXC_CODE_BITS] <= except_type;
            end
         end
         // mtc0
         else if(wen) begin
            case (addr)
               `CP0_COUNT: begin
                  count_reg <= wdata;
               end
               `CP0_STATUS: begin
                  status_reg[`IE_BIT] <= wdata[`IE_BIT];
                  status_reg[`EXL_BIT] <= wdata[`EXL_BIT];
                  status_reg[`IM7_IM0_BITS] <= wdata[`IM7_IM0_BITS];
                  status_reg[`BEV_BIT] <= wdata[`BEV_BIT];
               end
               `CP0_CAUSE: begin 
                  cause_reg[`IP1_IP0_BITS] <= wdata[`IP1_IP0_BITS];  //软件中断
               end
               `CP0_EPC: begin
                  epc_reg <= wdata;
               end
               `CP0_COMPARE: begin 
                  compare_reg <= wdata;
                  timer_int <= 1'b0;
               end
               `CP0_CONFIG: begin   //不会写config1
                  config_reg[`K23_BITS] <= wdata[`K23_BITS];
                  config_reg[`KU_BITS ] <= wdata[`KU_BITS ];
                  config_reg[`K0_BITS ] <= wdata[`K0_BITS ];
               end
               `CP0_WIRED: begin
                  wired_reg[`WIRED_BITS] <= wdata[`WIRED_BITS];
               end
               default: begin
                  /**/
               end
            endcase
         end
      end
   end

   //badvaddr
   wire badvaddr_wen;
   assign badvaddr_wen = (except_type==`EXC_CODE_ADEL) || (except_type==`EXC_CODE_ADES) ||
                         (except_type==`EXC_CODE_TLBL) || (except_type==`EXC_CODE_TLBS) ? 1'b1 : 1'b0;
   always @(posedge clk) begin
      if(badvaddr_wen)
         badvaddr_reg <= badvaddr;
   end

   //random: 在[wired_reg, tlb_line_num-1]之间循环
   wire wired_wen;
   assign wired_wen = wen & (addr == `CP0_WIRED);
   always @(posedge clk) begin
      if(rst) begin
         random_reg     <= `TLB_LINE_NUM-1;
      end
      else if(random_reg==wired_reg | wired_wen) begin
         random_reg <= `TLB_LINE_NUM-1;
      end
      else begin
         random_reg <= random_reg-1;
      end
   end

   //index, entry_hi/lo, page_mask
   wire mtc0_index, mtc0_entry_lo0, mtc0_entry_lo1, mtc0_entry_hi, mtc0_page_mask;
      //1. mtc0写
   assign mtc0_index     = wen & (addr == `CP0_INDEX);
   assign mtc0_entry_hi  = wen & (addr == `CP0_ENTRY_HI);
   assign mtc0_entry_lo0 = wen & (addr == `CP0_ENTRY_LO0);
   assign mtc0_entry_lo1 = wen & (addr == `CP0_ENTRY_LO1);
   assign mtc0_page_mask = wen & (addr == `CP0_PAGE_MASK);
      //2. tlb指令写
   wire tlbr, tlbp, tlbwi, tlbwr;
   assign {tlbwr, tlbwi, tlbr, tlbp} = tlb_typeM;
      //3. 异常更新 entry_hi
   wire tlb_exception;
   assign tlb_exception = ~|except_type[4:2] & |except_type[1:0]; //EXC_CODE_MOD, EXC_CODE_TLBL, EXC_CODE_TLBS

   always@(posedge clk) begin
      if(rst) begin
         index_reg <= 0;
         entry_lo0_reg <= 0;
         entry_lo1_reg <= 0;
         entry_hi_reg <= 0;
         page_mask_reg <= 0;
      end
      else begin
         index_reg[31]              <= tlbp           ? index_in[31] : index_reg[31];

         index_reg[`INDEX_BITS]     <= tlbp           ? index_in[`INDEX_BITS] :
                                       mtc0_index     ? wdata[`INDEX_BITS] : index_reg[`INDEX_BITS];

         entry_lo0_reg[`PFN_BITS]   <= tlbr           ? entry_lo0_in[`PFN_BITS] :
                                       mtc0_entry_lo0 ? wdata[`PFN_BITS] : entry_lo0_reg[`PFN_BITS];
         entry_lo0_reg[`FLAG_BITS]  <= tlbr           ? entry_lo0_in[`FLAG_BITS] :
                                       mtc0_entry_lo0 ? wdata[`FLAG_BITS] : entry_lo0_reg[`FLAG_BITS];

         entry_lo1_reg[`PFN_BITS]   <= tlbr           ? entry_lo1_in[`PFN_BITS] :
                                       mtc0_entry_lo1 ? wdata[`PFN_BITS] : entry_lo1_reg[`PFN_BITS];
         entry_lo1_reg[`FLAG_BITS]  <= tlbr           ? entry_lo1_in[`FLAG_BITS] :
                                       mtc0_entry_lo1 ? wdata[`FLAG_BITS] : entry_lo1_reg[`FLAG_BITS];

         entry_hi_reg[`VPN2_BITS]   <= tlbr           ? entry_hi_in[`VPN2_BITS] :
                                       mtc0_entry_hi  ? wdata[`VPN2_BITS] :
                                       tlb_exception  ? badvaddr[`VPN2_BITS] : entry_hi_reg[`VPN2_BITS];
         
         entry_hi_reg[`ASID_BITS]   <= tlbr           ? entry_hi_in[`ASID_BITS] :
                                       mtc0_entry_hi  ? wdata[`ASID_BITS] : entry_hi_reg[`ASID_BITS];

         page_mask_reg[`MASK_BITS]  <= tlbr           ? page_mask_in[`MASK_BITS] :
                                       mtc0_page_mask ? wdata[`MASK_BITS] : page_mask_reg[`MASK_BITS];
      end
   end

   //context
   wire mtc0_context;
   assign mtc0_context = wen & (addr == `CP0_CONTEXT);
   always @(posedge clk) begin
      if(rst)
         context_reg <= 32'b0;
      else if(mtc0_context)
         context_reg[`PTE_BASE_BITS] <= context_reg[`PTE_BASE_BITS];
      else if(tlb_exception)
         context_reg[`BAD_VPN2_BITS] <= badvaddr[`BAD_VPN2_BITS];
   end

   //Read
   always @(*) begin
      case(addr)
         `CP0_INDEX    : begin
            rdata = index_reg;
         end
         `CP0_RANDOM   : begin
            rdata = random_reg;
         end
         `CP0_ENTRY_LO0: begin
            rdata = entry_lo0_reg;
         end
         `CP0_ENTRY_LO1: begin
            rdata = entry_lo1_reg;
         end
         `CP0_CONTEXT: begin
            rdata <= context_reg;
         end
         `CP0_PAGE_MASK: begin
 				rdata = page_mask_reg;            
         end
         `CP0_WIRED    : begin
 				rdata = wired_reg;            
         end
         `CP0_BADVADDR : begin
 				rdata = badvaddr_reg;            
         end
         `CP0_COUNT    : begin
 				rdata = count_reg;            
         end
         `CP0_ENTRY_HI : begin
 				rdata = entry_hi_reg;            
         end
         `CP0_COMPARE  : begin
 				rdata = compare_reg;            
         end
         `CP0_STATUS   : begin
 				rdata = status_reg;            
         end
         `CP0_CAUSE    : begin
 				rdata = cause_reg;            
         end
         `CP0_EPC      : begin
 				rdata = epc_reg;            
         end
         `CP0_PRID     : begin
 				rdata = (sel==3'b000) ? prid_reg : ebase_reg;            
         end
         `CP0_CONFIG   : begin
 				rdata = (sel==3'b000) ? config_reg : config1_reg;         
         end
         default:
            rdata = 32'b0;
      endcase
   end
endmodule
