//module:       div
//description:  radix-2 divider
//version:      1.4

/** log:
1.1: 增加了存储输入的逻辑 (不暂停M,W阶段, 数据前推导致输入发生变化)
1.2: 增加了flush逻辑，用于发生异常时停止计算除法（1.3: 合并到rst中）
1.3: 接口增加axi握手逻辑。其中“地址”握手(opn_valid)，认为是单向握手（slave随时都准备好接收输入）
1.4: rst时将一些reg清0，防止result出现xxx的情况
*/

module div_radix2(
    input wire clk,
    input wire rst,
    input wire [31:0] a,    //divident
    input wire [31:0] b,    //divisor
    input wire sign,        //1:signed

    input wire opn_valid,   //master操作数准备好
    output reg res_valid,   //slave计算结果准备好
    input wire res_ready,   //master可以接收计算结果
    output wire [63:0] result
);
    /** 计算过程
    1. 先取绝对值，计算出余数和商。再根据被除数、除数符号对结果调整
    2. 计算过程中，由于保证了remainer为正，因此最高位为0，可以用32位存储。而除数需用33位
    */

    reg [31:0] a_save, b_save;
    reg [63:0] SR;                  //shift register
    reg [32 :0] NEG_DIVISOR;        //divisor 2's complement
    wire [31:0] REMAINER, QUOTIENT;
    assign REMAINER = SR[63:32];
    assign QUOTIENT = SR[31: 0];

    wire [31:0] divident_abs;
    wire [32:0] divisor_abs;
    wire [31:0] remainer, quotient;

    assign divident_abs = (sign & a[31]) ? ~a + 1'b1 : a;
    //余数符号与被除数相同
    assign remainer = (sign & a_save[31]) ? ~REMAINER + 1'b1 : REMAINER;
    assign quotient = sign & (a_save[31] ^ b_save[31]) ? ~QUOTIENT + 1'b1 : QUOTIENT;
    assign result = {remainer,quotient};

    wire CO;
    wire [32:0] sub_result;
    wire [32:0] mux_result;
    //sub
    assign {CO,sub_result} = {1'b0,REMAINER} + NEG_DIVISOR;
    //mux
    assign mux_result = CO ? sub_result : {1'b0,REMAINER};

    //FSM
    reg [5:0] cnt;
    reg start_cnt;
    always @(posedge clk) begin
        if(rst) begin
            SR <= 0;
            a_save <= 0;
            b_save <= 0;

            cnt <= 0;
            start_cnt <= 1'b0;
        end
        else if(~start_cnt & opn_valid & ~res_valid) begin
            cnt <= 1;
            start_cnt <= 1'b1;
            //save a,b
            a_save <= a;
            b_save <= b;

            //Register init
            SR[63:0] <= {31'b0,divident_abs,1'b0}; //left shift one bit initially
            NEG_DIVISOR <= (sign & b[31]) ? {1'b1,b} : ~{1'b0,b} + 1'b1; //divisor_abs的补码
        end
        else if(start_cnt) begin
            if(cnt[5]) begin    //cnt == 32
                cnt <= 0;
                start_cnt <= 1'b0;
                
                //Output result
                SR[63:32] <= mux_result[31:0];
                SR[0] <= CO;
            end
            else begin
                cnt <= cnt + 1;

                SR[63:0] <= {mux_result[30:0],SR[31:1],CO,1'b0}; //wsl: write and shift left
            end
        end
    end

    wire data_go;
    assign data_go = res_valid & res_ready;
    always @(posedge clk) begin
        res_valid <= rst     ? 1'b0 :
                     cnt[5]  ? 1'b1 :
                     data_go ? 1'b0 : res_valid;
    end
endmodule