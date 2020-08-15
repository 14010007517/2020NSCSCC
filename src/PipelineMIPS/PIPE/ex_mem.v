module ex_mem (
    input wire clk, rst,flushM,
    input wire stallM,
    input wire [31:0] pcE,
    input wire [63:0] alu_outE,
    input wire [31:0] rt_valueE,
    input wire [4:0] reg_writeE,
    input wire [31:0] instrE,
    input wire branchE,
    input wire pred_takeE,
    input wire [31:0] pc_branchE,
    input wire overflowE,
    input wire is_in_delayslot_iE,
    input wire [4:0] rdE,
    input wire actual_takeE,
    input wire [13:0] l_s_typeE,
    input wire [1:0] mfhi_loE,
    input wire mem_read_enE, 	
    input wire mem_write_enE,    
    input wire reg_write_enE,     
    input wire mem_to_regE,   	
    input wire hilo_to_regE, 	
    input wire riE,  			
    input wire breakE,   		
    input wire syscallE, 		
    input wire eretE,    		
    input wire cp0_wenE, 		
    input wire cp0_to_regE, 
    input wire [3:0] tlb_typeE, 	
    input wire inst_tlb_refillE, inst_tlb_invalidE,
    input wire [31:0] mem_addrE,
    input wire trap_resultE,
    input wire branchL_E,
    input wire [6:0] cacheE,

    output reg [31:0] pcM,
    output reg [31:0] alu_outM,
    output reg [31:0] rt_valueM,
    output reg [4:0] reg_writeM,
    output reg [31:0] instrM,
    output reg branchM,
    output reg pred_takeM,
    output reg [31:0] pc_branchM,
    output reg overflowM,        
    output reg is_in_delayslot_iM,
    output reg [4:0] rdM,
    output reg actual_takeM,
    output reg [13:0] l_s_typeM,
    output reg [1:0] mfhi_loM,
    output reg mem_read_enM,	
    output reg mem_write_enM,
    output reg reg_write_enM, 
    output reg mem_to_regM, 	
    output reg hilo_to_regM,	
    output reg riM,			
    output reg breakM,		
    output reg syscallM,		
    output reg eretM,		
    output reg cp0_wenM,		
    output reg cp0_to_regM,
    output reg [3:0] tlb_typeM,
    output reg inst_tlb_refillM, inst_tlb_invalidM,
    output reg [31:0] mem_addrM,
    output reg trap_resultM,
    output reg branchL_M,
    output reg [6:0] cacheM
);

    always @(posedge clk) begin
        if(rst | flushM) begin
            pcM                     <=              0;
            alu_outM                <=              0;
            rt_valueM               <=              0;
            reg_writeM              <=              0;
            instrM                  <=              0;
            branchM                 <=              0;
            pred_takeM              <=              0;
            pc_branchM              <=              0;
            overflowM               <=              0;
            is_in_delayslot_iM      <=              0;
            rdM                     <=              0;
            actual_takeM            <=              0;
            l_s_typeM               <=              0;
            mfhi_loM                <=              0;
            mem_read_enM	        <=              0;
			mem_write_enM	        <=              0;
			reg_write_enM	        <=              0;
			mem_to_regM		        <=              0;
			hilo_to_regM	        <=              0;
			riM				        <=              0;
			breakM			        <=              0;
			syscallM		        <=              0;
			eretM			        <=              0;
			cp0_wenM		        <=              0;
			cp0_to_regM		        <=              0;
            tlb_typeM               <=              0;
            inst_tlb_refillM        <=              0;
            inst_tlb_invalidM       <=              0;
            mem_addrM               <=              0;
            trap_resultM            <=              0;
            branchL_M               <=              0;
            cacheM                  <=              0;
        end
        else if(~stallM) begin
            pcM                     <=      pcE                 ;
            alu_outM                <=      alu_outE[31:0]      ;
            rt_valueM               <=      rt_valueE           ;
            reg_writeM              <=      reg_writeE          ;
            instrM                  <=      instrE              ;
            branchM                 <=      branchE             ;
            pred_takeM              <=      pred_takeE          ;
            pc_branchM              <=      pc_branchE          ;
            overflowM               <=      overflowE           ;
            is_in_delayslot_iM      <=      is_in_delayslot_iE  ;
            rdM                     <=      rdE                 ;
            actual_takeM            <=      actual_takeE        ;
            l_s_typeM               <=      l_s_typeE           ;
            mfhi_loM                <=      mfhi_loE            ;
            mem_read_enM	        <=      mem_read_enE		;
            mem_write_enM	        <=      mem_write_enE	    ;
            reg_write_enM	        <=      reg_write_enE 	    ;
            mem_to_regM		        <=      mem_to_regE 		;
            hilo_to_regM	        <=      hilo_to_regE		;
            riM				        <=      riE				    ;
            breakM			        <=      breakE			    ;
            syscallM		        <=      syscallE			;
            eretM			        <=      eretE			    ;
            cp0_wenM		        <=      cp0_wenE			;
            cp0_to_regM		        <=      cp0_to_regE		    ;
            tlb_typeM               <=      tlb_typeE           ;
            inst_tlb_refillM        <=      inst_tlb_refillE    ;
            inst_tlb_invalidM       <=      inst_tlb_invalidE   ;
            mem_addrM               <=      mem_addrE           ;
            trap_resultM            <=      trap_resultE        ;
            branchL_M               <=      branchL_E           ;
            cacheM                  <=      cacheE              ;
        end
    end
endmodule