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

      //cp0寄存器输出
      output wire [31:0] cp0_statusW, cp0_causeW, cp0_epcW, cp0_ebaseW
   );

   //-----------------cp0寄存器-------------------
   reg [31:0] index_reg;
   reg [31:0] random_reg;
   reg [31:0] entry_lo0_reg;
   reg [31:0] entry_lo1_reg;
   reg [31:0] contex_reg;
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

   assign cp0_statusW = status_reg;
   assign cp0_causeW  = cause_reg;
   assign cp0_epcW    = epc_reg;
   assign cp0_ebaseW  = ebase_reg;

   //other
   reg interval_flag;   //间隔一个时钟递增时钟计数器
   reg timer_int;       //计时器中断

   wire [31:0] pc_minus4;
   assign pc_minus4 = pcM - 4;

   //mtc0 & mfc0 special register select
   wire w_prid, w_ebase, w_config, w_config1;

   //always
   always @(posedge clk) begin
      if(rst) begin
         //cp0初始化
         status_reg    <= 32'b000000000_1_000000_00000000_000000_0_0;  //BEV置为1
         cause_reg     <= 32'b0_0_000000000000000_00000000_0_00000_00;
         count_reg     <= 32'b0;

         prid_reg      <= 32'h004c_0102;

         ebase_reg           <= 32'h8000_0000;
         config_reg          <= 32'h0000_8000;  //

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
            if(w_ebase) begin
               ebase_reg[29:12] <= wdata[29:12];   //Excepton base
            end
            if(w_config) begin
               config_reg[30:25] <= wdata[30:25];
               config_reg[2:0] <= wdata[2:0];
            end

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
               default: begin
                  /**/
               end
            endcase
         end
      end
   end

   wire wen_badvaddr;
   assign wen_badvaddr = (except_type==`EXC_TYPE_ADEL) || (except_type==`EXC_TYPE_ADES) ? 1'b1 : 1'b0;

   always @(posedge clk) begin
      if(wen_badvaddr)
         badvaddr_reg <= badvaddr;
   end

   assign w_prid = (addr == 5'd15 && sel==3'b0);
   assign w_ebase = (addr == 5'd15 && sel==3'b1);
   assign w_config = (addr == 5'd16 && sel==3'b0);
   assign w_config1 = (addr == 5'd16 && sel==3'b1);

   //read
   always @(addr, sel) begin
      case(addr)
         `CP0_INDEX    : begin
            rdata <= index_reg;
         end
         `CP0_RANDOM   : begin
            rdata <= random_reg;
         end
         `CP0_ENTRY_LO0: begin
            rdata <= entry_lo0_reg;
         end
         `CP0_ENTRY_LO1: begin
            rdata <= entry_lo1_reg;
         end
         `CP0_CONTEX   : begin
 				rdata <= contex_reg;            
         end
         `CP0_PAGE_MASK: begin
 				rdata <= page_mask_reg;            
         end
         `CP0_WIRED    : begin
 				rdata <= wired_reg;            
         end
         `CP0_BADVADDR : begin
 				rdata <= badvaddr_reg;            
         end
         `CP0_COUNT    : begin
 				rdata <= count_reg;            
         end
         `CP0_ENTRY_HI : begin
 				rdata <= entry_hi_reg;            
         end
         `CP0_COMPARE  : begin
 				rdata <= compare_reg;            
         end
         `CP0_STATUS   : begin
 				rdata <= status_reg;            
         end
         `CP0_CAUSE    : begin
 				rdata <= cause_reg;            
         end
         `CP0_EPC      : begin
 				rdata <= epc_reg;            
         end
         `CP0_PRID     : begin
 				rdata <= (sel==3'b000) ? prid_reg : ebase_reg;            
         end
         `CP0_CONFIG   : begin
 				rdata <= (sel==3'b000) ? config_reg : config1_reg;         
         end
         default:
            rdata <= 32'b0;
      endcase
   end
endmodule
