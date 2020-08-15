module id_ex (
    input wire clk, rst,
    input wire stallE,
    input wire flushE,
    input wire [31:0] pcD,
    input wire [31:0] rd1D, rd2D,
    input wire [4:0] rsD, rtD, rdD,
    input wire [31:0] immD,
    input wire [31:0] pc_plus4D,
    input wire [31:0] instrD,
    input wire [31:0] pc_branchD,
    input wire pred_takeD,
    input wire branchD,
    input wire jump_conflictD,
    input wire [4:0] saD,
    input wire is_in_delayslot_iD,
    input wire [5:0] alu_controlD,
    input wire jumpD,
    input wire [4:0] branch_judge_controlD,
    input wire [13:0] l_s_typeD,
    input wire [1:0] mfhi_loD,
    input wire [1:0] reg_dstD,		
    input wire alu_imm_selD,	
    input wire mem_read_enD,	
    input wire mem_write_enD,	
    input wire reg_write_enD,	
    input wire mem_to_regD,		
    input wire hilo_wenD,		
    input wire hilo_to_regD,	
    input wire riD,				
    input wire breakD,			
    input wire syscallD,		
    input wire eretD,			
    input wire cp0_wenD,		
    input wire cp0_to_regD,	
    input wire [3:0] tlb_typeD,
    input wire inst_tlb_refillD, inst_tlb_invalidD,
    input wire movnD, movzD,
    input wire branchL_D,
    input wire [6:0] cacheD,

    output reg [31:0] pcE,
    output reg [31:0] rd1E, rd2E,
    output reg [4:0] rsE, rtE, rdE,
    output reg [31:0] immE,
    output reg [31:0] pc_plus4E,
    output reg [31:0] instrE,
    output reg [31:0] pc_branchE,
    output reg pred_takeE,
    output reg branchE,
    output reg jump_conflictE,    
    output reg [4:0] saE,        
    output reg is_in_delayslot_iE,
    output reg [5:0] alu_controlE,
    output reg jumpE,
    output reg [4:0] branch_judge_controlE,
    output reg [13:0] l_s_typeE,
    output reg [1:0] mfhi_loE,

    output reg [1:0] reg_dstE,		
    output reg alu_imm_selE,	
    output reg mem_read_enE,	
    output reg mem_write_enE,	
    output reg reg_write_enE,	
    output reg mem_to_regE,		
    output reg hilo_wenE,		
    output reg hilo_to_regE,	
    output reg riE,				
    output reg breakE,			
    output reg syscallE,		
    output reg eretE,			
    output reg cp0_wenE,		
    output reg cp0_to_regE,
    output reg [3:0] tlb_typeE,
    output reg inst_tlb_refillE, inst_tlb_invalidE,
    output reg movnE, movzE,
    output reg branchL_E,
    output reg [6:0] cacheE
);
    always @(posedge clk) begin
        if(rst | flushE) begin
            pcE                     <=      0   ;
            rd1E                    <=      0   ;
            rd2E                    <=      0   ;
            rsE                     <=      0   ;
            rtE                     <=      0   ;
            rdE                     <=      0   ;
            immE                    <=      0   ;
            pc_plus4E               <=      0   ;
            instrE                  <=      0   ;
            pc_branchE              <=      0   ;
            pred_takeE              <=      0   ;
            branchE                 <=      0   ;
            jump_conflictE          <=      0   ;
            saE                     <=      0   ;
            is_in_delayslot_iE      <=      0   ;
            alu_controlE            <=      0   ;
            jumpE                   <=      0   ;
            branch_judge_controlE   <=      0   ;
            l_s_typeE               <=      0   ;
            mfhi_loE                <=      0   ;
            reg_dstE		        <=      0   ; 
			alu_imm_selE	        <=      0   ;
			mem_read_enE	        <=      0   ;
			mem_write_enE	        <=      0   ;
			reg_write_enE	        <=      0   ;
			mem_to_regE		        <=      0   ;
			hilo_wenE		        <=      0   ;
			hilo_to_regE	        <=      0   ;
			riE				        <=      0   ;
			breakE			        <=      0   ;
			syscallE		        <=      0   ;
			eretE			        <=      0   ;
			cp0_wenE		        <=      0   ;
			cp0_to_regE		        <=      0   ;
            tlb_typeE               <=      0   ;
            inst_tlb_refillE        <=      0   ;
            inst_tlb_invalidE       <=      0   ;
            movnE                   <=      0   ;
            movzE                   <=      0   ;
            branchL_E               <=      0   ;
            cacheE                  <=      0   ;
        end 
        else if(~stallE) begin
            pcE                     <=  pcD                     ;
            rd1E                    <=  rd1D                    ;
            rd2E                    <=  rd2D                    ;
            rsE                     <=  rsD                     ;
            rtE                     <=  rtD                     ;
            rdE                     <=  rdD                     ;
            immE                    <=  immD                    ;
            pc_plus4E               <=  pc_plus4D               ;
            instrE                  <=  instrD                  ;
            pc_branchE              <=  pc_branchD              ;
            pred_takeE              <=  pred_takeD              ;
            branchE                 <=  branchD                 ;
            jump_conflictE          <=  jump_conflictD          ;
            saE                     <=  saD                     ;
            is_in_delayslot_iE      <=  is_in_delayslot_iD      ;
            alu_controlE            <=  alu_controlD            ;
            jumpE                   <=  jumpD                   ;
            branch_judge_controlE   <=  branch_judge_controlD   ;
            l_s_typeE               <=  l_s_typeD               ;
            mfhi_loE                <=  mfhi_loD                ;
            reg_dstE		        <=  reg_dstD 		        ; 
			alu_imm_selE	        <=  alu_imm_selD 	        ;
			mem_read_enE	        <=  mem_read_enD		    ;
			mem_write_enE	        <=  mem_write_enD	        ;
			reg_write_enE	        <=  reg_write_enD 	        ;
			mem_to_regE		        <=  mem_to_regD 		    ;
			hilo_wenE		        <=  hilo_wenD		        ;
			hilo_to_regE	        <=  hilo_to_regD		    ;
			riE				        <=  riD				        ;
			breakE			        <=  breakD			        ;
			syscallE		        <=  syscallD			    ;
			eretE			        <=  eretD			        ;
			cp0_wenE		        <=  cp0_wenD			    ;
			cp0_to_regE		        <=  cp0_to_regD		        ;
            tlb_typeE               <=  tlb_typeD               ;
            inst_tlb_refillE        <=  inst_tlb_refillD        ;
            inst_tlb_invalidE       <=  inst_tlb_invalidD       ;
            movnE                   <=  movnD                   ;
            movzE                   <=  movzD                   ;
            branchL_E               <=  branchL_D               ;
            cacheE                  <=  cacheD                  ;
        end
    end

// // main_decoder 还未整合；
//     always@(posedge clk) begin
// 		if(rst | flushE) begin
// 			reg_dstE		<= 0; 
// 			alu_imm_selE	<= 0;
// 			mem_read_enE	<= 0;
// 			mem_write_enE	<= 0;
// 			reg_write_enE	<= 0;
// 			mem_to_regE		<= 0;
// 			hilo_wenE		<= 0;
// 			hilo_to_regE	<= 0;
// 			riE				<= 0;
// 			breakE			<= 0;
// 			syscallE		<= 0;
// 			eretE			<= 0;
// 			cp0_wenE		<= 0;
// 			cp0_to_regE		<= 0;
// 		end
// 		else if(~stallE)begin
// 			reg_dstE		<= reg_dstD 		; 
// 			alu_imm_selE	<= alu_imm_selD 	;
// 			mem_read_enE	<= mem_read_enD		;
// 			mem_write_enE	<= mem_write_enD	;
// 			reg_write_enE	<= reg_write_enD 	;
// 			mem_to_regE		<= mem_to_regD 		;
// 			hilo_wenE		<= hilo_wenD		;
// 			hilo_to_regE	<= hilo_to_regD		;
// 			riE				<= riD				;
// 			breakE			<= breakD			;
// 			syscallE		<= syscallD			;
// 			eretE			<= eretD			;
// 			cp0_wenE		<= cp0_wenD			;
// 			cp0_to_regE		<= cp0_to_regD		;
// 		end
//     end
endmodule