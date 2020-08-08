//module:       div
//description:  self-align divider
//              迭代次数约为，3 + max{2*(a的有效位数-b的有效位数), 0}
//version:      1.4

/** log:
1.1: 增加了存储输入的逻辑 (不暂停M,W阶段, 数据前推导致输入发生变化)
1.2: 增加了flush逻辑，用于发生异常时停止计算除法（1.3: 合并到rst中）
1.3: 接口增加axi握手逻辑。其中“地址”握手(opn_valid)，认为是单向握手（slave随时都准备好接收输入）
1.4: rst时将一些reg清0，防止result出现xxx的情况
*/

module div_self_align(
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
    /*
    注意点
    1. 先取绝对值，计算出余数和商。再根据被除数、除数符号对结果调整
    2. 初始情况SR的HW为除数（左移了1位），RMEAINER存被除数。迭代过后，SR的LW存商（逆序），REMAINER存余数。
    3. SR的HW扩展成了33位，防止无符号数除法时，初始化左移1位时，把最高位的1抹去。
    */

    reg [31:0] a_save, b_save;

    reg [64:0] SR;          //shift register
    reg [31:0] REMAINER;    //divisor 2's complement
    wire [31:0] QUOTIENT;
    wire [32:0] DIVISOR;

    wire [31:0] divident_abs;
    wire [31:0] divisor_abs;
    wire [31:0] remainer, quotient;

    //FSM
    reg start;
    reg left_shift;
    reg [31:0] flag;        //标记1的位置，可左右移动

    assign DIVISOR = SR[64:32];
    //倒序
    assign QUOTIENT = {SR[0],SR[1],SR[2],SR[3],SR[4],SR[5],SR[6],SR[7],SR[8],SR[9],SR[10],SR[11],SR[12],SR[13],SR[14],SR[15],SR[16],SR[17],SR[18],SR[19],SR[20],SR[21],SR[22],SR[23],SR[24],SR[25],SR[26],SR[27],SR[28],SR[29],SR[30],SR[31]};

    assign divident_abs = (sign & a[31]) ? ~a + 1'b1 : a;
    assign divisor_abs = (sign & b[31]) ? ~b + 1'b1 : b;
    //余数符号与被除数相同
    assign remainer = (sign & a_save[31]) ? ~REMAINER + 1'b1 : REMAINER;
    assign quotient = sign & (a_save[31] ^ b_save[31]) ? ~QUOTIENT + 1'b1 : QUOTIENT;
    assign result = {remainer,quotient};

    wire CO;
    wire [32:0] sub_result;
    wire [31:0] mux_result;
    //sub
    // wire [32:0] NEG_DIVISOR;
    // assign NEG_DIVISOR = ~DIVISOR + 1'b1;
    // assign {CO,sub_result} = {1'b0,REMAINER} + NEG_DIVISOR; //需要优化，不知道vivado会不会自己优化
    adderN #(33) ADDER(
        1'b1,~DIVISOR,{1'b0,REMAINER},
        sub_result,CO
    );
    //mux
    assign mux_result = ~left_shift & CO ? sub_result[31:0] : REMAINER; //右移且CO为1时余数更新

    //state machine
    always @(posedge clk) begin
        if(rst) begin
            SR <= 0;
            REMAINER <= 0;
            a_save <= 0;
            b_save <= 0;

            start <= 1'b0;
            left_shift <= 1'b1;
        end
        else if(~start & opn_valid & ~res_valid) begin
            start <= 1'b1;
            left_shift <= 1'b1;

            //save a,b
            a_save <= a;
            b_save <= b;

            //Initial register
            REMAINER <= divident_abs;
            SR[64:32] <= {divisor_abs[31:0],1'b0};  //初始化左移一格
            flag <= 32'h0000_0002;
            SR[31:0] <= 32'b0;
        end
        else if(start) begin
            if(left_shift & CO) begin
                SR <= {SR[63:0],1'b0};
                flag <= {flag[30:0],1'b0};
            end
            if(left_shift & ~CO) begin
                left_shift <= 1'b0;
                SR <= {1'b0,SR[64:1]};
                flag <= {1'b0,flag[31:1]};
            end
            else if(~left_shift) begin
                if(flag[0]) begin
                   //end
                    REMAINER <= mux_result;
                    SR[31] <= CO;

                    start <= 1'b0;
                end
                else begin
                    REMAINER <= mux_result;
                    SR <= {1'b0,SR[64:32],CO,SR[30:1]};
                    flag <= {1'b0,flag[31:1]};
                end
            end
        end
    end

    wire data_go;
    assign data_go = res_valid & res_ready;
    always @(posedge clk) begin
        res_valid <= rst     ? 1'b0 :
                     start & ~left_shift & flag[0] ? 1'b1 :
                     data_go ? 1'b0 : res_valid;
    end
endmodule

module full_adder(
    input Cin,x,y,
    output s,Cout
    );

    assign s  = x ^ y ^ Cin;
    assign Cout = (x & y) | (x & Cin) | (y & Cin);
endmodule

module adderN
    #(N = 32)(
    input carryin,
    input [N-1:0] x,y,
    output [N-1:0] s,
    output carryout
    );

    wire [N:0] c;

    assign c[0] = carryin;
    assign carryout = c[N];

    genvar i;
    generate
        for(i=0;i<N;i=i+1)
            full_adder stage(c[i],x[i],y[i],s[i],c[i+1]);
    endgenerate
endmodule