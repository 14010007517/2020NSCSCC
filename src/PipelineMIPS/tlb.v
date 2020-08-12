`include "defines.vh"

module tlb (
    input clk, rst,
    input wire [31:0] inst_vaddr,
    input wire [31:0] data_vaddr,
    input wire inst_en,
    input wire mem_read_enM, mem_write_enM,

    output wire [31:0] inst_paddr,
    output wire [31:0] data_paddr,
    output wire no_cache_i,
    output wire no_cache_d,
    
    //异常
    output wire inst_tlb_refill, inst_tlb_invalid,
    output wire data_tlb_refill, data_tlb_invalid, data_tlb_modify,

    //TLB指令
	input  wire        TLBP,
	input  wire        TLBR,
    input  wire        TLBWI,
    input  wire        TLBWR,
    
    input  wire [31:0] EntryHi_in,
	input  wire [31:0] PageMask_in,
	input  wire [31:0] EntryLo0_in,
	input  wire [31:0] EntryLo1_in,
	input  wire [31:0] Index_in,
    input  wire [31:0] Random_in,

	output wire [31:0] EntryHi_out,
	output wire [31:0] PageMask_out,
	output wire [31:0] EntryLo0_out,
	output wire [31:0] EntryLo1_out,
	output wire [31:0] Index_out
);

//TLB
reg [31:0] TLB_EntryHi  [`TLB_LINE_NUM-1:0]; //G位放在EntryHi的第12位
reg [31:0] TLB_PageMask [`TLB_LINE_NUM-1:0];
reg [31:0] TLB_EntryLo0 [`TLB_LINE_NUM-1:0];
reg [31:0] TLB_EntryLo1 [`TLB_LINE_NUM-1:0];

wire [`TLB_LINE_NUM-1: 0] i_find_mask, d_find_mask; 
wire [`LOG2_TLB_LINE_NUM-1: 0] d_find_index;

wire inst_find, data_find;
assign inst_find = |i_find_mask;
assign data_find = |d_find_mask;

wire [31:0] i_tlb_entrylo, d_tlb_entrylo;        //从tlb中找到的项

wire [`TAG_WIDTH-1: 0] i_tlb_pfn , d_tlb_pfn;
wire [5:0]             i_tlb_flag, d_tlb_flag;
assign i_tlb_pfn  = i_tlb_entrylo[`PFN_BITS];
assign i_tlb_flag = i_tlb_entrylo[`FLAG_BITS];
assign d_tlb_pfn  = d_tlb_entrylo[`PFN_BITS];
assign d_tlb_flag = d_tlb_entrylo[`FLAG_BITS];

//inst
wire [`TAG_WIDTH-1:0] inst_vpn, inst_pfn;
wire [`OFFSET_WIDTH-1:0] inst_offset;
assign inst_vpn    = inst_vaddr[31: `OFFSET_WIDTH];
assign inst_offset = inst_vaddr[`OFFSET_WIDTH-1:0];

wire inst_kseg01;
assign inst_kseg01 = inst_vaddr[31:30]==2'b10 ? 1'b1 : 1'b0;

assign inst_pfn = inst_kseg01 ? {3'b0, inst_vpn[`TAG_WIDTH-4:0]} : i_tlb_pfn;

//data
wire [`TAG_WIDTH-1:0] data_vpn, data_pfn;
wire [`OFFSET_WIDTH-1:0] data_offset;
assign data_vpn    = data_vaddr[31:`OFFSET_WIDTH];
assign data_offset = data_vaddr[`OFFSET_WIDTH-1:0];

wire data_kseg01;
assign data_kseg01 = data_vaddr[31:30]==2'b10 ? 1'b1 : 1'b0;

assign data_pfn = data_kseg01 ? {3'b0, data_vpn[`TAG_WIDTH-4:0]} : d_tlb_pfn;

//--------------------------output---------------------------------
//地址映射
assign inst_paddr = {inst_pfn, inst_offset};
assign data_paddr = {data_pfn, data_offset};

assign no_cache_i = inst_kseg01 ? (inst_vaddr[31:29] == 3'b101 ? 1'b1 : 1'b0) :
                    i_tlb_flag[`C_BITS]==3'b010 ? 1'b1 : 1'b0;
assign no_cache_d = data_kseg01 ? (data_vaddr[31:29] == 3'b101 ? 1'b1 : 1'b0) :
                    d_tlb_flag[`C_BITS]==3'b010 ? 1'b1 : 1'b0;

//异常
    //取指TLB异常
assign inst_tlb_refill  = inst_kseg01 ? 1'b0 : (inst_en & ~inst_find);
assign inst_tlb_invalid = inst_kseg01 ? 1'b0 : (inst_en & inst_find & ~i_tlb_flag[`V_BIT]);

    //load/store TLB异常
wire data_V, data_D;
assign data_V = d_tlb_flag[`V_BIT];
assign data_D = d_tlb_flag[`D_BIT];

assign data_tlb_refill  = data_kseg01 ? 1'b0 : (mem_read_enM | mem_write_enM) & ~data_find;
assign data_tlb_invalid = data_kseg01 ? 1'b0 : (mem_read_enM | mem_write_enM) & data_find & ~data_V;
assign data_tlb_modify  = data_kseg01 ? 1'b0 : mem_write_enM & data_find & data_V & ~data_D;

//TLB指令
wire [`LOG2_TLB_LINE_NUM-1:0] index, random_index;
assign random_index = Random_in[`LOG2_TLB_LINE_NUM-1:0];
assign index = Index_in[`LOG2_TLB_LINE_NUM-1:0];

assign PageMask_out = (TLBR) ? TLB_PageMask[index] : 32'b0;
assign EntryHi_out  = (TLBR) ? TLB_EntryHi [index] : 32'b0;
assign EntryLo0_out = (TLBR) ? {TLB_EntryLo0[index][31:1], TLB_EntryHi[index][`G_BIT]} : 32'b0; //如果TLB G位为1，则EntryLo的G位返回1
assign EntryLo1_out = (TLBR) ? {TLB_EntryLo1[index][31:1], TLB_EntryHi[index][`G_BIT]} : 32'b0;
assign Index_out    = (TLBP) ? (data_find ? d_find_index : 32'h8000_0000) : 32'b0;
    //TLBWI
integer tt;
always @(posedge clk)
begin
    if(rst) begin
        for(tt=0; tt<`TLB_LINE_NUM; tt=tt+1) begin
            TLB_EntryHi [tt] <= 0;
            TLB_PageMask[tt] <= 0;
            TLB_EntryLo0[tt] <= 0;
            TLB_EntryLo1[tt] <= 0;
        end
    end
    else if (TLBWI)
    begin
        TLB_EntryHi [index][`VPN2_BITS] <= EntryHi_in[`VPN2_BITS] & ~PageMask_in[`VPN2_BITS];
        TLB_EntryHi [index][`G_BIT]     <= EntryLo0_in[0] & EntryLo1_in[0];
        TLB_EntryHi [index][`ASID_BITS] <= EntryHi_in[`ASID_BITS];
        TLB_PageMask[index]             <= PageMask_in;
        TLB_EntryLo0[index][`PFN_BITS]  <= EntryLo0_in[`PFN_BITS] & ~PageMask_in[`MASK_BITS];
        TLB_EntryLo0[index][`C_BITS]    <= EntryLo0_in[`C_BITS];
        TLB_EntryLo0[index][`D_BIT]     <= EntryLo0_in[`D_BIT];
        TLB_EntryLo0[index][`V_BIT]     <= EntryLo0_in[`V_BIT];
        TLB_EntryLo1[index][`PFN_BITS]  <= EntryLo1_in[`PFN_BITS] & ~PageMask_in[`MASK_BITS];
        TLB_EntryLo1[index][`C_BITS]    <= EntryLo1_in[`C_BITS];
        TLB_EntryLo1[index][`D_BIT]     <= EntryLo1_in[`D_BIT];
        TLB_EntryLo1[index][`V_BIT]     <= EntryLo1_in[`V_BIT];
    end
    else if(TLBWR)
    begin
        TLB_EntryHi [random_index][`VPN2_BITS]  <= EntryHi_in[`VPN2_BITS] & ~PageMask_in[`VPN2_BITS];
        TLB_EntryHi [random_index][`G_BIT]      <= EntryLo0_in[0] & EntryLo1_in[0];
        TLB_EntryHi [random_index][`ASID_BITS]  <= EntryHi_in[`ASID_BITS];
        TLB_PageMask[random_index]              <= PageMask_in;
        TLB_EntryLo0[random_index][`PFN_BITS]   <= EntryLo0_in[`PFN_BITS] & ~PageMask_in[`MASK_BITS];
        TLB_EntryLo0[random_index][`C_BITS]     <= EntryLo0_in[`C_BITS];
        TLB_EntryLo0[random_index][`D_BIT]      <= EntryLo0_in[`D_BIT];
        TLB_EntryLo0[random_index][`V_BIT]      <= EntryLo0_in[`V_BIT];
        TLB_EntryLo1[random_index][`PFN_BITS]   <= EntryLo1_in[`PFN_BITS] & ~PageMask_in[`MASK_BITS];
        TLB_EntryLo1[random_index][`C_BITS]     <= EntryLo1_in[`C_BITS];
        TLB_EntryLo1[random_index][`D_BIT]      <= EntryLo1_in[`D_BIT];
        TLB_EntryLo1[random_index][`V_BIT]      <= EntryLo1_in[`V_BIT];
    end
end
//------------------------------------------------------------------
wire [31:0] data_vaddr_probe;
assign data_vaddr_probe = TLBP ? EntryHi_in : data_vaddr;

genvar i;
generate
	for (i = 0; i < `TLB_LINE_NUM; i = i + 1)
	begin : find
		assign i_find_mask[i] = ((inst_vaddr[`VPN2_BITS] & ~TLB_PageMask[i][`VPN2_BITS]) == (TLB_EntryHi[i][`VPN2_BITS] & ~TLB_PageMask[i][`VPN2_BITS])) && (TLB_EntryHi[i][`G_BIT] || TLB_EntryHi[i][`ASID_BITS] == EntryHi_in[`ASID_BITS]); 
		assign d_find_mask[i] = ((data_vaddr_probe[`VPN2_BITS] & ~TLB_PageMask[i][`VPN2_BITS]) == (TLB_EntryHi[i][`VPN2_BITS] & ~TLB_PageMask[i][`VPN2_BITS])) && (TLB_EntryHi[i][`G_BIT] || TLB_EntryHi[i][`ASID_BITS] == EntryHi_in[`ASID_BITS]);		
	end
endgenerate

wire inst_odd, data_odd;
assign inst_odd = inst_vaddr[`OFFSET_WIDTH];
assign data_odd = data_vaddr_probe[`OFFSET_WIDTH];

assign i_tlb_entrylo = 
{32{i_find_mask[ 0]}} & ( ({32{~inst_odd}} & TLB_EntryLo0[ 0]) | ({32{ inst_odd}} & TLB_EntryLo1[ 0]) ) |
{32{i_find_mask[ 1]}} & ( ({32{~inst_odd}} & TLB_EntryLo0[ 1]) | ({32{ inst_odd}} & TLB_EntryLo1[ 1]) ) |
{32{i_find_mask[ 2]}} & ( ({32{~inst_odd}} & TLB_EntryLo0[ 2]) | ({32{ inst_odd}} & TLB_EntryLo1[ 2]) ) |
{32{i_find_mask[ 3]}} & ( ({32{~inst_odd}} & TLB_EntryLo0[ 3]) | ({32{ inst_odd}} & TLB_EntryLo1[ 3]) ) |
{32{i_find_mask[ 4]}} & ( ({32{~inst_odd}} & TLB_EntryLo0[ 4]) | ({32{ inst_odd}} & TLB_EntryLo1[ 4]) ) |
{32{i_find_mask[ 5]}} & ( ({32{~inst_odd}} & TLB_EntryLo0[ 5]) | ({32{ inst_odd}} & TLB_EntryLo1[ 5]) ) |
{32{i_find_mask[ 6]}} & ( ({32{~inst_odd}} & TLB_EntryLo0[ 6]) | ({32{ inst_odd}} & TLB_EntryLo1[ 6]) ) |
{32{i_find_mask[ 7]}} & ( ({32{~inst_odd}} & TLB_EntryLo0[ 7]) | ({32{ inst_odd}} & TLB_EntryLo1[ 7]) ) |
{32{i_find_mask[ 8]}} & ( ({32{~inst_odd}} & TLB_EntryLo0[ 8]) | ({32{ inst_odd}} & TLB_EntryLo1[ 8]) ) |
{32{i_find_mask[ 9]}} & ( ({32{~inst_odd}} & TLB_EntryLo0[ 9]) | ({32{ inst_odd}} & TLB_EntryLo1[ 9]) ) |
{32{i_find_mask[10]}} & ( ({32{~inst_odd}} & TLB_EntryLo0[10]) | ({32{ inst_odd}} & TLB_EntryLo1[10]) ) |
{32{i_find_mask[11]}} & ( ({32{~inst_odd}} & TLB_EntryLo0[11]) | ({32{ inst_odd}} & TLB_EntryLo1[11]) ) |
{32{i_find_mask[12]}} & ( ({32{~inst_odd}} & TLB_EntryLo0[12]) | ({32{ inst_odd}} & TLB_EntryLo1[12]) ) |
{32{i_find_mask[13]}} & ( ({32{~inst_odd}} & TLB_EntryLo0[13]) | ({32{ inst_odd}} & TLB_EntryLo1[13]) ) |
{32{i_find_mask[14]}} & ( ({32{~inst_odd}} & TLB_EntryLo0[14]) | ({32{ inst_odd}} & TLB_EntryLo1[14]) ) |
{32{i_find_mask[15]}} & ( ({32{~inst_odd}} & TLB_EntryLo0[15]) | ({32{ inst_odd}} & TLB_EntryLo1[15]) ) |
{32{i_find_mask[16]}} & ( ({32{~inst_odd}} & TLB_EntryLo0[16]) | ({32{ inst_odd}} & TLB_EntryLo1[16]) ) |
{32{i_find_mask[17]}} & ( ({32{~inst_odd}} & TLB_EntryLo0[17]) | ({32{ inst_odd}} & TLB_EntryLo1[17]) ) |
{32{i_find_mask[18]}} & ( ({32{~inst_odd}} & TLB_EntryLo0[18]) | ({32{ inst_odd}} & TLB_EntryLo1[18]) ) |
{32{i_find_mask[19]}} & ( ({32{~inst_odd}} & TLB_EntryLo0[19]) | ({32{ inst_odd}} & TLB_EntryLo1[19]) ) |
{32{i_find_mask[20]}} & ( ({32{~inst_odd}} & TLB_EntryLo0[20]) | ({32{ inst_odd}} & TLB_EntryLo1[20]) ) |
{32{i_find_mask[21]}} & ( ({32{~inst_odd}} & TLB_EntryLo0[21]) | ({32{ inst_odd}} & TLB_EntryLo1[21]) ) |
{32{i_find_mask[22]}} & ( ({32{~inst_odd}} & TLB_EntryLo0[22]) | ({32{ inst_odd}} & TLB_EntryLo1[22]) ) |
{32{i_find_mask[23]}} & ( ({32{~inst_odd}} & TLB_EntryLo0[23]) | ({32{ inst_odd}} & TLB_EntryLo1[23]) ) |
{32{i_find_mask[24]}} & ( ({32{~inst_odd}} & TLB_EntryLo0[24]) | ({32{ inst_odd}} & TLB_EntryLo1[24]) ) |
{32{i_find_mask[25]}} & ( ({32{~inst_odd}} & TLB_EntryLo0[25]) | ({32{ inst_odd}} & TLB_EntryLo1[25]) ) |
{32{i_find_mask[26]}} & ( ({32{~inst_odd}} & TLB_EntryLo0[26]) | ({32{ inst_odd}} & TLB_EntryLo1[26]) ) |
{32{i_find_mask[27]}} & ( ({32{~inst_odd}} & TLB_EntryLo0[27]) | ({32{ inst_odd}} & TLB_EntryLo1[27]) ) |
{32{i_find_mask[28]}} & ( ({32{~inst_odd}} & TLB_EntryLo0[28]) | ({32{ inst_odd}} & TLB_EntryLo1[28]) ) |
{32{i_find_mask[29]}} & ( ({32{~inst_odd}} & TLB_EntryLo0[29]) | ({32{ inst_odd}} & TLB_EntryLo1[29]) ) |
{32{i_find_mask[30]}} & ( ({32{~inst_odd}} & TLB_EntryLo0[30]) | ({32{ inst_odd}} & TLB_EntryLo1[30]) ) |
{32{i_find_mask[31]}} & ( ({32{~inst_odd}} & TLB_EntryLo0[31]) | ({32{ inst_odd}} & TLB_EntryLo1[31]) );

assign d_tlb_entrylo = 
{32{d_find_mask[ 0]}} & ( ({32{~data_odd}} & TLB_EntryLo0[ 0]) | ({32{ data_odd}} & TLB_EntryLo1[ 0]) ) |
{32{d_find_mask[ 1]}} & ( ({32{~data_odd}} & TLB_EntryLo0[ 1]) | ({32{ data_odd}} & TLB_EntryLo1[ 1]) ) |
{32{d_find_mask[ 2]}} & ( ({32{~data_odd}} & TLB_EntryLo0[ 2]) | ({32{ data_odd}} & TLB_EntryLo1[ 2]) ) |
{32{d_find_mask[ 3]}} & ( ({32{~data_odd}} & TLB_EntryLo0[ 3]) | ({32{ data_odd}} & TLB_EntryLo1[ 3]) ) |
{32{d_find_mask[ 4]}} & ( ({32{~data_odd}} & TLB_EntryLo0[ 4]) | ({32{ data_odd}} & TLB_EntryLo1[ 4]) ) |
{32{d_find_mask[ 5]}} & ( ({32{~data_odd}} & TLB_EntryLo0[ 5]) | ({32{ data_odd}} & TLB_EntryLo1[ 5]) ) |
{32{d_find_mask[ 6]}} & ( ({32{~data_odd}} & TLB_EntryLo0[ 6]) | ({32{ data_odd}} & TLB_EntryLo1[ 6]) ) |
{32{d_find_mask[ 7]}} & ( ({32{~data_odd}} & TLB_EntryLo0[ 7]) | ({32{ data_odd}} & TLB_EntryLo1[ 7]) ) |
{32{d_find_mask[ 8]}} & ( ({32{~data_odd}} & TLB_EntryLo0[ 8]) | ({32{ data_odd}} & TLB_EntryLo1[ 8]) ) |
{32{d_find_mask[ 9]}} & ( ({32{~data_odd}} & TLB_EntryLo0[ 9]) | ({32{ data_odd}} & TLB_EntryLo1[ 9]) ) |
{32{d_find_mask[10]}} & ( ({32{~data_odd}} & TLB_EntryLo0[10]) | ({32{ data_odd}} & TLB_EntryLo1[10]) ) |
{32{d_find_mask[11]}} & ( ({32{~data_odd}} & TLB_EntryLo0[11]) | ({32{ data_odd}} & TLB_EntryLo1[11]) ) |
{32{d_find_mask[12]}} & ( ({32{~data_odd}} & TLB_EntryLo0[12]) | ({32{ data_odd}} & TLB_EntryLo1[12]) ) |
{32{d_find_mask[13]}} & ( ({32{~data_odd}} & TLB_EntryLo0[13]) | ({32{ data_odd}} & TLB_EntryLo1[13]) ) |
{32{d_find_mask[14]}} & ( ({32{~data_odd}} & TLB_EntryLo0[14]) | ({32{ data_odd}} & TLB_EntryLo1[14]) ) |
{32{d_find_mask[15]}} & ( ({32{~data_odd}} & TLB_EntryLo0[15]) | ({32{ data_odd}} & TLB_EntryLo1[15]) ) |
{32{d_find_mask[16]}} & ( ({32{~data_odd}} & TLB_EntryLo0[16]) | ({32{ data_odd}} & TLB_EntryLo1[16]) ) |
{32{d_find_mask[17]}} & ( ({32{~data_odd}} & TLB_EntryLo0[17]) | ({32{ data_odd}} & TLB_EntryLo1[17]) ) |
{32{d_find_mask[18]}} & ( ({32{~data_odd}} & TLB_EntryLo0[18]) | ({32{ data_odd}} & TLB_EntryLo1[18]) ) |
{32{d_find_mask[19]}} & ( ({32{~data_odd}} & TLB_EntryLo0[19]) | ({32{ data_odd}} & TLB_EntryLo1[19]) ) |
{32{d_find_mask[20]}} & ( ({32{~data_odd}} & TLB_EntryLo0[20]) | ({32{ data_odd}} & TLB_EntryLo1[20]) ) |
{32{d_find_mask[21]}} & ( ({32{~data_odd}} & TLB_EntryLo0[21]) | ({32{ data_odd}} & TLB_EntryLo1[21]) ) |
{32{d_find_mask[22]}} & ( ({32{~data_odd}} & TLB_EntryLo0[22]) | ({32{ data_odd}} & TLB_EntryLo1[22]) ) |
{32{d_find_mask[23]}} & ( ({32{~data_odd}} & TLB_EntryLo0[23]) | ({32{ data_odd}} & TLB_EntryLo1[23]) ) |
{32{d_find_mask[24]}} & ( ({32{~data_odd}} & TLB_EntryLo0[24]) | ({32{ data_odd}} & TLB_EntryLo1[24]) ) |
{32{d_find_mask[25]}} & ( ({32{~data_odd}} & TLB_EntryLo0[25]) | ({32{ data_odd}} & TLB_EntryLo1[25]) ) |
{32{d_find_mask[26]}} & ( ({32{~data_odd}} & TLB_EntryLo0[26]) | ({32{ data_odd}} & TLB_EntryLo1[26]) ) |
{32{d_find_mask[27]}} & ( ({32{~data_odd}} & TLB_EntryLo0[27]) | ({32{ data_odd}} & TLB_EntryLo1[27]) ) |
{32{d_find_mask[28]}} & ( ({32{~data_odd}} & TLB_EntryLo0[28]) | ({32{ data_odd}} & TLB_EntryLo1[28]) ) |
{32{d_find_mask[29]}} & ( ({32{~data_odd}} & TLB_EntryLo0[29]) | ({32{ data_odd}} & TLB_EntryLo1[29]) ) |
{32{d_find_mask[30]}} & ( ({32{~data_odd}} & TLB_EntryLo0[30]) | ({32{ data_odd}} & TLB_EntryLo1[30]) ) |
{32{d_find_mask[31]}} & ( ({32{~data_odd}} & TLB_EntryLo0[31]) | ({32{ data_odd}} & TLB_EntryLo1[31]) );

assign d_find_index=
({5{d_find_mask[0 ]}} & 5'd0 ) |
({5{d_find_mask[1 ]}} & 5'd1 ) |
({5{d_find_mask[2 ]}} & 5'd2 ) |
({5{d_find_mask[3 ]}} & 5'd3 ) |
({5{d_find_mask[4 ]}} & 5'd4 ) |
({5{d_find_mask[5 ]}} & 5'd5 ) |
({5{d_find_mask[6 ]}} & 5'd6 ) |
({5{d_find_mask[7 ]}} & 5'd7 ) |
({5{d_find_mask[8 ]}} & 5'd8 ) |
({5{d_find_mask[9 ]}} & 5'd9 ) |
({5{d_find_mask[10]}} & 5'd10) |
({5{d_find_mask[11]}} & 5'd11) |
({5{d_find_mask[12]}} & 5'd12) |
({5{d_find_mask[13]}} & 5'd13) |
({5{d_find_mask[14]}} & 5'd14) |
({5{d_find_mask[15]}} & 5'd15) |
({5{d_find_mask[16]}} & 5'd16) |
({5{d_find_mask[17]}} & 5'd17) |
({5{d_find_mask[18]}} & 5'd18) |
({5{d_find_mask[19]}} & 5'd19) |
({5{d_find_mask[20]}} & 5'd20) |
({5{d_find_mask[21]}} & 5'd21) |
({5{d_find_mask[22]}} & 5'd22) |
({5{d_find_mask[23]}} & 5'd23) |
({5{d_find_mask[24]}} & 5'd24) |
({5{d_find_mask[25]}} & 5'd25) |
({5{d_find_mask[26]}} & 5'd26) |
({5{d_find_mask[27]}} & 5'd27) |
({5{d_find_mask[28]}} & 5'd28) |
({5{d_find_mask[29]}} & 5'd29) |
({5{d_find_mask[30]}} & 5'd30) |
({5{d_find_mask[31]}} & 5'd31);

endmodule