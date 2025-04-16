module ALU(
  input  wire [18:0] alu_op,
  input  wire [31:0] alu_src1,
  input  wire [31:0] alu_src2,
  output wire [31:0] alu_result
);

wire op_add;   //add operation
wire op_sub;   //sub operation
wire op_slt;   //signed compared and set less than
wire op_sltu;  //unsigned compared and set less than
wire op_and;   //bitwise and
wire op_nor;   //bitwise nor
wire op_or;    //bitwise or
wire op_xor;   //bitwise xor
wire op_sll;   //logic left shift
wire op_srl;   //logic right shift
wire op_sra;   //arithmetic right shift
wire op_lui;   //Load Upper Immediate

wire op_mul;
wire op_mulh;
wire op_mulhu;
wire op_div;
wire op_divu;
wire op_rem;
wire op_remu;

// control code decomposition
assign op_add  = alu_op[ 0];
assign op_sub  = alu_op[ 1];
assign op_slt  = alu_op[ 2];
assign op_sltu = alu_op[ 3];
assign op_and  = alu_op[ 4];
assign op_nor  = alu_op[ 5];
assign op_or   = alu_op[ 6];
assign op_xor  = alu_op[ 7];
assign op_sll  = alu_op[ 8];
assign op_srl  = alu_op[ 9];
assign op_sra  = alu_op[10];
assign op_lui  = alu_op[11];

assign op_mul   = alu_op[12];
assign op_mulh  = alu_op[13];
assign op_mulhu = alu_op[14];
assign op_div   = alu_op[15];
assign op_divu  = alu_op[16];
assign op_rem   = alu_op[17];
assign op_remu  = alu_op[18];

wire [31:0] add_sub_result;
wire [31:0] slt_result;
wire [31:0] sltu_result;
wire [31:0] and_result;
wire [31:0] nor_result;
wire [31:0] or_result;
wire [31:0] xor_result;
wire [31:0] lui_result;
wire [31:0] sll_result;
wire [63:0] sr64_result;
wire [31:0] sr_result;

wire [31:0] mul_result;
wire [31:0] mulh_result;
wire [31:0] mulhu_result;
wire [31:0] div_result;
wire [31:0] divu_result;
wire [31:0] rem_result;
wire [31:0] remu_result;

// 32-bit adder
wire [31:0] adder_a;
wire [31:0] adder_b;
wire        adder_cin;
wire [31:0] adder_result;
wire        adder_cout;

assign adder_a   = alu_src1;
assign adder_b   = (op_sub | op_slt | op_sltu) ? ~alu_src2 : alu_src2;  //src1 - src2 rj-rk
assign adder_cin = (op_sub | op_slt | op_sltu) ? 1'b1      : 1'b0;
assign {adder_cout, adder_result} = adder_a + adder_b + adder_cin;

// ADD, SUB result
assign add_sub_result = adder_result;

// SLT result
assign slt_result[31:1] = 31'b0;   //rj < rk 1
assign slt_result[0]    = (alu_src1[31] & ~alu_src2[31])
                        | ((alu_src1[31] ~^ alu_src2[31]) & adder_result[31]);

// SLTU result
assign sltu_result[31:1] = 31'b0;
assign sltu_result[0]    = ~adder_cout;

// bitwise operation
assign and_result = alu_src1 & alu_src2;
assign or_result  = alu_src1 | alu_src2;
assign nor_result = ~or_result;
assign xor_result = alu_src1 ^ alu_src2;
assign lui_result = alu_src2;

// SLL result
assign sll_result = alu_src1 << alu_src2[4:0];   //rj << ui5

// SRL, SRA result
assign sr64_result = {{32{op_sra & alu_src1[31]}}, alu_src1[31:0]} >> alu_src2[4:0]; //rj >> i5

assign sr_result   = sr64_result[31:0];

// MUL result
wire [32:0] ex_src1;
wire [32:0] ex_src2;
wire [65:0] mul_tmp_res;
assign ex_src1 = op_mulhu ? {1'b0,alu_src1}        :
                 op_divu  ? {1'b0,alu_src1}        :
                 op_remu  ? {1'b0,alu_src1}        :
                             {alu_src1[31],alu_src1};
assign ex_src2 = op_mulhu ? {1'b0,alu_src2}        :
                 op_divu  ? {1'b0,alu_src2}        :
                 op_remu  ? {1'b0,alu_src2}        :
                             {alu_src2[31],alu_src2};                   
Mul_wallace my_mul (
  .a  (ex_src1    ),
  .b  (ex_src2    ),
  .res(mul_tmp_res)
);
assign mul_result   = mul_tmp_res[31:0];
assign mulh_result  = mul_tmp_res[63:32];
assign mulhu_result = mul_tmp_res[63:32];

// DIV result

// MOD result
wire [32:0]remainder;
wire [32:0]quotient;
FIND1 u1_FIND1(
    .data(src1),
    .pos(pos1)
);

FIND1 u2_FIND1(
    .data(src0),
    .pos(pos2)
);

DIVALL u_DIVALL(
    .src0(src0),
    .src1(src1),
    .remainder(remainder),
    .quotient(quotient),
    .pos1(pos1),
    .pos2(pos2)
);

// DIV result
assign div_result  = quotient[31:0];
assign divu_result = quotient[31:0];

// MOD result
assign rem_result  = remainder[31:0];
assign remu_result = remainder[31:0];

// final result mux
assign alu_result = ({32{op_add|op_sub}} & add_sub_result)
                  | ({32{op_slt       }} & slt_result)
                  | ({32{op_sltu      }} & sltu_result)
                  | ({32{op_and       }} & and_result)
                  | ({32{op_nor       }} & nor_result)
                  | ({32{op_or        }} & or_result)
                  | ({32{op_xor       }} & xor_result)
                  | ({32{op_lui       }} & lui_result)
                  | ({32{op_sll       }} & sll_result)
                  | ({32{op_srl|op_sra}} & sr_result)
                  | ({32{op_mul       }} & mul_result)
                  | ({32{op_mulh      }} & mulh_result)
                  | ({32{op_mulhu     }} & mulhu_result)
                  | ({32{op_div       }} & div_result)
                  | ({32{op_divu      }} & divu_result)
                  | ({32{op_rem       }} & rem_result)
                  | ({32{op_remu      }} & remu_result);

endmodule

module Mul_wallace(
    input       [32: 0]     a,
    input       [32: 0]     b,
    output      [65: 0]     res
);
    // 构造booth编码
    // booth[i] = 3'd0对应0,3'd1时对应x,3'd2时对应2x,3'd7时对应-x,3'd6时对应-2x
    wire [2:0]  booth[16:0];
    assign booth[16] =  ( (b[32] == 1'b0) ? ((b[31] == 1'b0) ? 3'd0 : 3'd1 ) :   ((b[31] == 1'b0) ? 3'd1 : 3'd2) ) ;
    assign booth[15] =  (  b[31] == 1'b0 ) ? 
                        ( (b[30] == 1'b0) ? ((b[29] == 1'b0) ? 3'd0 : 3'd1 ) :   ((b[29] == 1'b0) ? 3'd1 : 3'd2) ) :
                        ( (b[30] == 1'b0) ? ((b[29] == 1'b0) ? 3'd6 : 3'd7 ) :   ((b[29] == 1'b0) ? 3'd7 : 3'd0) ) ;
    assign booth[14] =  (  b[29] == 1'b0 ) ? 
                        ( (b[28] == 1'b0) ? ((b[27] == 1'b0) ? 3'd0 : 3'd1 ) :   ((b[27] == 1'b0) ? 3'd1 : 3'd2) ) :
                        ( (b[28] == 1'b0) ? ((b[27] == 1'b0) ? 3'd6 : 3'd7 ) :   ((b[27] == 1'b0) ? 3'd7 : 3'd0) ) ;
    assign booth[13] =  (  b[27] == 1'b0 ) ? 
                        ( (b[26] == 1'b0) ? ((b[25] == 1'b0) ? 3'd0 : 3'd1 ) :   ((b[25] == 1'b0) ? 3'd1 : 3'd2) ) :
                        ( (b[26] == 1'b0) ? ((b[25] == 1'b0) ? 3'd6 : 3'd7 ) :   ((b[25] == 1'b0) ? 3'd7 : 3'd0) ) ;
    assign booth[12] =  (  b[25] == 1'b0 ) ? 
                        ( (b[24] == 1'b0) ? ((b[23] == 1'b0) ? 3'd0 : 3'd1 ) :   ((b[23] == 1'b0) ? 3'd1 : 3'd2) ) :
                        ( (b[24] == 1'b0) ? ((b[23] == 1'b0) ? 3'd6 : 3'd7 ) :   ((b[23] == 1'b0) ? 3'd7 : 3'd0) ) ;
    assign booth[11] =  (  b[23] == 1'b0 ) ? 
                        ( (b[22] == 1'b0) ? ((b[21] == 1'b0) ? 3'd0 : 3'd1 ) :   ((b[21] == 1'b0) ? 3'd1 : 3'd2) ) :
                        ( (b[22] == 1'b0) ? ((b[21] == 1'b0) ? 3'd6 : 3'd7 ) :   ((b[21] == 1'b0) ? 3'd7 : 3'd0) ) ;
    assign booth[10] =  (  b[21] == 1'b0 ) ? 
                        ( (b[20] == 1'b0) ? ((b[19] == 1'b0) ? 3'd0 : 3'd1 ) :   ((b[19] == 1'b0) ? 3'd1 : 3'd2) ) :
                        ( (b[20] == 1'b0) ? ((b[19] == 1'b0) ? 3'd6 : 3'd7 ) :   ((b[19] == 1'b0) ? 3'd7 : 3'd0) ) ;
    assign booth[ 9] =  (  b[19] == 1'b0 ) ? 
                        ( (b[18] == 1'b0) ? ((b[17] == 1'b0) ? 3'd0 : 3'd1 ) :   ((b[17] == 1'b0) ? 3'd1 : 3'd2) ) :
                        ( (b[18] == 1'b0) ? ((b[17] == 1'b0) ? 3'd6 : 3'd7 ) :   ((b[17] == 1'b0) ? 3'd7 : 3'd0) ) ;
    assign booth[ 8] =  (  b[17] == 1'b0 ) ? 
                        ( (b[16] == 1'b0) ? ((b[15] == 1'b0) ? 3'd0 : 3'd1 ) :   ((b[15] == 1'b0) ? 3'd1 : 3'd2) ) :
                        ( (b[16] == 1'b0) ? ((b[15] == 1'b0) ? 3'd6 : 3'd7 ) :   ((b[15] == 1'b0) ? 3'd7 : 3'd0) ) ;
    assign booth[ 7] =  (  b[15] == 1'b0 ) ? 
                        ( (b[14] == 1'b0) ? ((b[13] == 1'b0) ? 3'd0 : 3'd1 ) :   ((b[13] == 1'b0) ? 3'd1 : 3'd2) ) :
                        ( (b[14] == 1'b0) ? ((b[13] == 1'b0) ? 3'd6 : 3'd7 ) :   ((b[13] == 1'b0) ? 3'd7 : 3'd0) ) ;
    assign booth[ 6] =  (  b[13] == 1'b0 ) ? 
                        ( (b[12] == 1'b0) ? ((b[11] == 1'b0) ? 3'd0 : 3'd1 ) :   ((b[11] == 1'b0) ? 3'd1 : 3'd2) ) :
                        ( (b[12] == 1'b0) ? ((b[11] == 1'b0) ? 3'd6 : 3'd7 ) :   ((b[11] == 1'b0) ? 3'd7 : 3'd0) ) ;
    assign booth[ 5] =  (  b[11] == 1'b0 ) ? 
                        ( (b[10] == 1'b0) ? ((b[ 9] == 1'b0) ? 3'd0 : 3'd1 ) :   ((b[ 9] == 1'b0) ? 3'd1 : 3'd2) ) :
                        ( (b[10] == 1'b0) ? ((b[ 9] == 1'b0) ? 3'd6 : 3'd7 ) :   ((b[ 9] == 1'b0) ? 3'd7 : 3'd0) ) ;
    assign booth[ 4] =  (  b[ 9] == 1'b0 ) ? 
                        ( (b[ 8] == 1'b0) ? ((b[ 7] == 1'b0) ? 3'd0 : 3'd1 ) :   ((b[ 7] == 1'b0) ? 3'd1 : 3'd2) ) :
                        ( (b[ 8] == 1'b0) ? ((b[ 7] == 1'b0) ? 3'd6 : 3'd7 ) :   ((b[ 7] == 1'b0) ? 3'd7 : 3'd0) ) ;
    assign booth[ 3] =  (  b[ 7] == 1'b0 ) ? 
                        ( (b[ 6] == 1'b0) ? ((b[ 5] == 1'b0) ? 3'd0 : 3'd1 ) :   ((b[ 5] == 1'b0) ? 3'd1 : 3'd2) ) :
                        ( (b[ 6] == 1'b0) ? ((b[ 5] == 1'b0) ? 3'd6 : 3'd7 ) :   ((b[ 5] == 1'b0) ? 3'd7 : 3'd0) ) ;
    assign booth[ 2] =  (  b[ 5] == 1'b0 ) ? 
                        ( (b[ 4] == 1'b0) ? ((b[ 3] == 1'b0) ? 3'd0 : 3'd1 ) :   ((b[ 3] == 1'b0) ? 3'd1 : 3'd2) ) :
                        ( (b[ 4] == 1'b0) ? ((b[ 3] == 1'b0) ? 3'd6 : 3'd7 ) :   ((b[ 3] == 1'b0) ? 3'd7 : 3'd0) ) ;
    assign booth[ 1] =  (  b[ 3] == 1'b0 ) ? 
                        ( (b[ 2] == 1'b0) ? ((b[ 1] == 1'b0) ? 3'd0 : 3'd1 ) :   ((b[ 1] == 1'b0) ? 3'd1 : 3'd2) ) :
                        ( (b[ 2] == 1'b0) ? ((b[ 1] == 1'b0) ? 3'd6 : 3'd7 ) :   ((b[ 1] == 1'b0) ? 3'd7 : 3'd0) ) ;
    assign booth[ 0] =  (  b[ 1] == 1'b0 ) ? 
                        ( (b[ 0] == 1'b0) ? ((1'b0  == 1'b0) ? 3'd0 : 3'd1 ) :   ((1'b0  == 1'b0) ? 3'd1 : 3'd2) ) :
                        ( (b[ 0] == 1'b0) ? ((1'b0  == 1'b0) ? 3'd6 : 3'd7 ) :   ((1'b0  == 1'b0) ? 3'd7 : 3'd0) ) ;

    // 由booth编码构造16个相加项
    wire [65:0] add [16:0];
    wire [65:0] temp_a = {33'd0, a};
    wire [65:0] temp_not = ~temp_a + 1; 
    assign add[16] = ((booth[16] == 3'd0) ? 66'd0 : ((booth[16] == 3'd1) ? temp_a  : ((booth[16] == 3'd2) ? temp_a << 1 : ((booth[16] == 3'd7) ? temp_not  : temp_not << 1 )))) << 32;         
    assign add[15] = ((booth[15] == 3'd0) ? 66'd0 : ((booth[15] == 3'd1) ? temp_a  : ((booth[15] == 3'd2) ? temp_a << 1 : ((booth[15] == 3'd7) ? temp_not  : temp_not << 1 )))) << 30;
    assign add[14] = ((booth[14] == 3'd0) ? 66'd0 : ((booth[14] == 3'd1) ? temp_a  : ((booth[14] == 3'd2) ? temp_a << 1 : ((booth[14] == 3'd7) ? temp_not  : temp_not << 1 )))) << 28;
    assign add[13] = ((booth[13] == 3'd0) ? 66'd0 : ((booth[13] == 3'd1) ? temp_a  : ((booth[13] == 3'd2) ? temp_a << 1 : ((booth[13] == 3'd7) ? temp_not  : temp_not << 1 )))) << 26;
    assign add[12] = ((booth[12] == 3'd0) ? 66'd0 : ((booth[12] == 3'd1) ? temp_a  : ((booth[12] == 3'd2) ? temp_a << 1 : ((booth[12] == 3'd7) ? temp_not  : temp_not << 1 )))) << 24;
    assign add[11] = ((booth[11] == 3'd0) ? 66'd0 : ((booth[11] == 3'd1) ? temp_a  : ((booth[11] == 3'd2) ? temp_a << 1 : ((booth[11] == 3'd7) ? temp_not  : temp_not << 1 )))) << 22;
    assign add[10] = ((booth[10] == 3'd0) ? 66'd0 : ((booth[10] == 3'd1) ? temp_a  : ((booth[10] == 3'd2) ? temp_a << 1 : ((booth[10] == 3'd7) ? temp_not  : temp_not << 1 )))) << 20;
    assign add[ 9] = ((booth[ 9] == 3'd0) ? 66'd0 : ((booth[ 9] == 3'd1) ? temp_a  : ((booth[ 9] == 3'd2) ? temp_a << 1 : ((booth[ 9] == 3'd7) ? temp_not  : temp_not << 1 )))) << 18;
    assign add[ 8] = ((booth[ 8] == 3'd0) ? 66'd0 : ((booth[ 8] == 3'd1) ? temp_a  : ((booth[ 8] == 3'd2) ? temp_a << 1 : ((booth[ 8] == 3'd7) ? temp_not  : temp_not << 1 )))) << 16;
    assign add[ 7] = ((booth[ 7] == 3'd0) ? 66'd0 : ((booth[ 7] == 3'd1) ? temp_a  : ((booth[ 7] == 3'd2) ? temp_a << 1 : ((booth[ 7] == 3'd7) ? temp_not  : temp_not << 1 )))) << 14;
    assign add[ 6] = ((booth[ 6] == 3'd0) ? 66'd0 : ((booth[ 6] == 3'd1) ? temp_a  : ((booth[ 6] == 3'd2) ? temp_a << 1 : ((booth[ 6] == 3'd7) ? temp_not  : temp_not << 1 )))) << 12;
    assign add[ 5] = ((booth[ 5] == 3'd0) ? 66'd0 : ((booth[ 5] == 3'd1) ? temp_a  : ((booth[ 5] == 3'd2) ? temp_a << 1 : ((booth[ 5] == 3'd7) ? temp_not  : temp_not << 1 )))) << 10;
    assign add[ 4] = ((booth[ 4] == 3'd0) ? 66'd0 : ((booth[ 4] == 3'd1) ? temp_a  : ((booth[ 4] == 3'd2) ? temp_a << 1 : ((booth[ 4] == 3'd7) ? temp_not  : temp_not << 1 )))) <<  8;
    assign add[ 3] = ((booth[ 3] == 3'd0) ? 66'd0 : ((booth[ 3] == 3'd1) ? temp_a  : ((booth[ 3] == 3'd2) ? temp_a << 1 : ((booth[ 3] == 3'd7) ? temp_not  : temp_not << 1 )))) <<  6;
    assign add[ 2] = ((booth[ 2] == 3'd0) ? 66'd0 : ((booth[ 2] == 3'd1) ? temp_a  : ((booth[ 2] == 3'd2) ? temp_a << 1 : ((booth[ 2] == 3'd7) ? temp_not  : temp_not << 1 )))) <<  4;
    assign add[ 1] = ((booth[ 1] == 3'd0) ? 66'd0 : ((booth[ 1] == 3'd1) ? temp_a  : ((booth[ 1] == 3'd2) ? temp_a << 1 : ((booth[ 1] == 3'd7) ? temp_not  : temp_not << 1 )))) <<  2;
    assign add[ 0] = ((booth[ 0] == 3'd0) ? 66'd0 : ((booth[ 0] == 3'd1) ? temp_a  : ((booth[ 0] == 3'd2) ? temp_a << 1 : ((booth[ 0] == 3'd7) ? temp_not  : temp_not << 1 ))));

    // 使用全加器逐层累加
    // CSA中间量保存
    wire [65:0] temp_add [29:0];
    // 例化CSA
    CSA #(66) csa_1(
        .a   (add[ 2]) ,
        .b   (add[ 1]),
        .c   (add[ 0]),
        .y1  (temp_add[ 1]),
        .y2  (temp_add[ 0])
    );
    CSA #(66) csa_2(
        .a   (add[ 5]) ,
        .b   (add[ 4]),
        .c   (add[ 3]),
        .y1  (temp_add[ 3]),
        .y2  (temp_add[ 2])
    ); 
    CSA #(66) csa_3(
        .a   (add[ 8]) ,
        .b   (add[ 7]),
        .c   (add[ 6]),
        .y1  (temp_add[ 5]),
        .y2  (temp_add[ 4])
    ); 
    CSA #(66) csa_4(
        .a   (add[11]) ,
        .b   (add[10]),
        .c   (add[ 9]),
        .y1  (temp_add[ 7]),
        .y2  (temp_add[ 6])
    ); 
    CSA #(66) csa_5(
        .a   (add[14]) ,
        .b   (add[13]),
        .c   (add[12]),
        .y1  (temp_add[ 9]),
        .y2  (temp_add[ 8])
    ); 
    CSA #(66) csa_6(
        .a   (add[15]) ,
        .b   (add[16]) ,
        .c   (temp_add[ 0]),
        .y1  (temp_add[11]),
        .y2  (temp_add[10])
    ); 
    CSA #(66) csa_7(
        .a   (temp_add[ 3]),
        .b   (temp_add[ 2]),
        .c   (temp_add[ 1]),
        .y1  (temp_add[13]),
        .y2  (temp_add[12])
    ); 
    CSA #(66) csa_8(
        .a   (temp_add[ 6]),
        .b   (temp_add[ 5]),
        .c   (temp_add[ 4]),
        .y1  (temp_add[15]),
        .y2  (temp_add[14])
    ); 
    CSA #(66) csa_9(
        .a   (temp_add[ 9]),
        .b   (temp_add[ 8]),
        .c   (temp_add[ 7]),
        .y1  (temp_add[17]),
        .y2  (temp_add[16])
    ); 
    CSA #(66) csa_10(
        .a   (temp_add[12]),
        .b   (temp_add[11]),
        .c   (temp_add[10]),
        .y1  (temp_add[19]),
        .y2  (temp_add[18])
    ); 
    CSA #(66) csa_11(
        .a   (temp_add[15]),
        .b   (temp_add[14]),
        .c   (temp_add[13]),
        .y1  (temp_add[21]),
        .y2  (temp_add[20])
    ); 
    CSA #(66) csa_12(
        .a   (temp_add[18]),
        .b   (temp_add[17]),
        .c   (temp_add[16]),
        .y1  (temp_add[23]),
        .y2  (temp_add[22])
    ); 
    CSA #(66) csa_13(
        .a   (temp_add[21]),
        .b   (temp_add[20]),
        .c   (temp_add[19]),
        .y1  (temp_add[25]),
        .y2  (temp_add[24])
    ); 
    CSA #(66) csa_14(
        .a   (temp_add[22]),
        .b   (temp_add[23]),
        .c   (temp_add[24]),
        .y1  (temp_add[27]),
        .y2  (temp_add[26])
    ); 
    CSA #(66) csa_15(
        .a  (temp_add[25]),
        .b  (temp_add[26]),
        .c  (temp_add[27]),
        .y1 (temp_add[29]),
        .y2 (temp_add[28])
    );

    // 最后一层全加器
    assign res = temp_add[29] + temp_add[28];

endmodule

module CSA #(
    parameter WIDTH = 66
)(
    input       [WIDTH-1: 0]     a,
    input       [WIDTH-1: 0]     b,
    input       [WIDTH-1: 0]     c,
    output      [WIDTH-1: 0]     y1,
    output      [WIDTH-1: 0]     y2
);
    wire        [WIDTH-1:0]         y2_tmp;

    assign y1       = a ^ b ^ c;
    assign y2_tmp   = (a & b) | (b & c) | (c & a); 
    assign y2       = y2_tmp << 1;
endmodule

module DIVALL(
    input [32 : 0] src0,
    input [32 : 0] src1,
    output [32 : 0] remainder,
    output [32 : 0] quotient,
    input [32 : 0] pos1,
    input [32 : 0] pos2
);

    wire [32:0] remainder_reg[0:32], quotient_reg[0:32];

    assign remainder = remainder_reg[0];
    assign quotient = quotient_reg[32] |quotient_reg[31] | quotient_reg[30] | quotient_reg[29] | quotient_reg[28] | quotient_reg[27] | quotient_reg[26] |
                     quotient_reg[25] | quotient_reg[24] | quotient_reg[23] | quotient_reg[22] | quotient_reg[21] | quotient_reg[20] |
                     quotient_reg[19] | quotient_reg[18] | quotient_reg[17] | quotient_reg[16] | quotient_reg[15] | quotient_reg[14] |
                     quotient_reg[13] | quotient_reg[12] | quotient_reg[11] | quotient_reg[10] | quotient_reg[9] | quotient_reg[8] |
                     quotient_reg[7] | quotient_reg[6] | quotient_reg[5] | quotient_reg[4] | quotient_reg[3] | quotient_reg[2] |
                     quotient_reg[1] | quotient_reg[0];


    DIV u32_DIV(
        .src0(src0),
        .src1(src1),
        .src0_out(remainder_reg[32]),
        .spo(quotient_reg[32]),
        .idx(32),
        .pos1(pos1),
        .pos2(pos2)
    );

    DIV u31_DIV(
        .src0(remainder_reg[32]),
        .src1(src1),
        .src0_out(remainder_reg[31]),
        .spo(quotient_reg[31]),
        .idx(31),
        .pos1(pos1),
        .pos2(pos2)
    );

    DIV u30_DIV(
        .src0(remainder_reg[31]),
        .src1(src1),
        .src0_out(remainder_reg[30]),
        .spo(quotient_reg[30]),
        .idx(30),
        .pos1(pos1),
        .pos2(pos2)
    );

    DIV u29_DIV(
        .src0(remainder_reg[30]),
        .src1(src1),
        .src0_out(remainder_reg[29]),
        .spo(quotient_reg[29]),
        .idx(29),
        .pos1(pos1),
        .pos2(pos2)
    );

    DIV u28_DIV(
        .src0(remainder_reg[29]),
        .src1(src1),
        .src0_out(remainder_reg[28]),
        .spo(quotient_reg[28]),
        .idx(28),
        .pos1(pos1),
        .pos2(pos2)
    );

    DIV u27_DIV(
        .src0(remainder_reg[28]),
        .src1(src1),
        .src0_out(remainder_reg[27]),
        .spo(quotient_reg[27]),
        .idx(27),
        .pos1(pos1),
        .pos2(pos2)
    );

    DIV u26_DIV(
        .src0(remainder_reg[27]),
        .src1(src1),
        .src0_out(remainder_reg[26]),
        .spo(quotient_reg[26]),
        .idx(26),
        .pos1(pos1),
        .pos2(pos2)
    );

    DIV u25_DIV(
        .src0(remainder_reg[26]),
        .src1(src1),
        .src0_out(remainder_reg[25]),
        .spo(quotient_reg[25]),
        .idx(25),
        .pos1(pos1),
        .pos2(pos2)
    );

    DIV u24_DIV(
        .src0(remainder_reg[25]),
        .src1(src1),
        .src0_out(remainder_reg[24]),
        .spo(quotient_reg[24]),
        .idx(24),
        .pos1(pos1),
        .pos2(pos2)
    );

    DIV u23_DIV(
        .src0(remainder_reg[24]),
        .src1(src1),
        .src0_out(remainder_reg[23]),
        .spo(quotient_reg[23]),
        .idx(23),
        .pos1(pos1),
        .pos2(pos2)
    );

    DIV u22_DIV(
        .src0(remainder_reg[23]),
        .src1(src1),
        .src0_out(remainder_reg[22]),
        .spo(quotient_reg[22]),
        .idx(22),
        .pos1(pos1),
        .pos2(pos2)
    );

    DIV u21_DIV(
        .src0(remainder_reg[22]),
        .src1(src1),
        .src0_out(remainder_reg[21]),
        .spo(quotient_reg[21]),
        .idx(21),
        .pos1(pos1),
        .pos2(pos2)
    );

    DIV u20_DIV(
        .src0(remainder_reg[21]),
        .src1(src1),
        .src0_out(remainder_reg[20]),
        .spo(quotient_reg[20]),
        .idx(20),
        .pos1(pos1),
        .pos2(pos2)
    );

    DIV u19_DIV(
        .src0(remainder_reg[20]),
        .src1(src1),
        .src0_out(remainder_reg[19]),
        .spo(quotient_reg[19]),
        .idx(19),
        .pos1(pos1),
        .pos2(pos2)
    );

    DIV u18_DIV(
        .src0(remainder_reg[19]),
        .src1(src1),
        .src0_out(remainder_reg[18]),
        .spo(quotient_reg[18]),
        .idx(18),
        .pos1(pos1),
        .pos2(pos2)
    );

    DIV u17_DIV(
        .src0(remainder_reg[18]),
        .src1(src1),
        .src0_out(remainder_reg[17]),
        .spo(quotient_reg[17]),
        .idx(17),
        .pos1(pos1),
        .pos2(pos2)
    );

    DIV u16_DIV(
        .src0(remainder_reg[17]),
        .src1(src1),
        .src0_out(remainder_reg[16]),
        .spo(quotient_reg[16]),
        .idx(16),
        .pos1(pos1),
        .pos2(pos2)
    );

    DIV u15_DIV(
        .src0(remainder_reg[16]),
        .src1(src1),
        .src0_out(remainder_reg[15]),
        .spo(quotient_reg[15]),
        .idx(15),
        .pos1(pos1),
        .pos2(pos2)
    );

    DIV u14_DIV(
        .src0(remainder_reg[15]),
        .src1(src1),
        .src0_out(remainder_reg[14]),
        .spo(quotient_reg[14]),
        .idx(14),
        .pos1(pos1),
        .pos2(pos2)
    );

    DIV u13_DIV(
        .src0(remainder_reg[14]),
        .src1(src1),
        .src0_out(remainder_reg[13]),
        .spo(quotient_reg[13]),
        .idx(13),
        .pos1(pos1),
        .pos2(pos2)
    );

    DIV u12_DIV(
        .src0(remainder_reg[13]),
        .src1(src1),
        .src0_out(remainder_reg[12]),
        .spo(quotient_reg[12]),
        .idx(12),
        .pos1(pos1),
        .pos2(pos2)
    );

    DIV u11_DIV(
        .src0(remainder_reg[12]),
        .src1(src1),
        .src0_out(remainder_reg[11]),
        .spo(quotient_reg[11]),
        .idx(11),
        .pos1(pos1),
        .pos2(pos2)
    );

    DIV u10_DIV(
        .src0(remainder_reg[11]),
        .src1(src1),
        .src0_out(remainder_reg[10]),
        .spo(quotient_reg[10]),
        .idx(10),
        .pos1(pos1),
        .pos2(pos2)
    );

    DIV u9_DIV(
        .src0(remainder_reg[10]),
        .src1(src1),
        .src0_out(remainder_reg[9]),
        .spo(quotient_reg[9]),
        .idx(9),
        .pos1(pos1),
        .pos2(pos2)
    );

    DIV u8_DIV(
        .src0(remainder_reg[9]),
        .src1(src1),
        .src0_out(remainder_reg[8]),
        .spo(quotient_reg[8]),
        .idx(8),
        .pos1(pos1),
        .pos2(pos2)
    );

    DIV u7_DIV(
        .src0(remainder_reg[8]),
        .src1(src1),
        .src0_out(remainder_reg[7]),
        .spo(quotient_reg[7]),
        .idx(7),
        .pos1(pos1),
        .pos2(pos2)
    );

    DIV u6_DIV(
        .src0(remainder_reg[7]),
        .src1(src1),
        .src0_out(remainder_reg[6]),
        .spo(quotient_reg[6]),
        .idx(6),
        .pos1(pos1),
        .pos2(pos2)
    );

    DIV u5_DIV(
        .src0(remainder_reg[6]),
        .src1(src1),
        .src0_out(remainder_reg[5]),
        .spo(quotient_reg[5]),
        .idx(5),
        .pos1(pos1),
        .pos2(pos2)
    );

    DIV u4_DIV(
        .src0(remainder_reg[5]),
        .src1(src1),
        .src0_out(remainder_reg[4]),
        .spo(quotient_reg[4]),
        .idx(4),
        .pos1(pos1),
        .pos2(pos2)
    );

    DIV u3_DIV(
        .src0(remainder_reg[4]),
        .src1(src1),
        .src0_out(remainder_reg[3]),
        .spo(quotient_reg[3]),
        .idx(3),
        .pos1(pos1),
        .pos2(pos2)
    );

    DIV u2_DIV(
        .src0(remainder_reg[3]),
        .src1(src1),
        .src0_out(remainder_reg[2]),
        .spo(quotient_reg[2]),
        .idx(2),
        .pos1(pos1),
        .pos2(pos2)
    );

    DIV u1_DIV(
        .src0(remainder_reg[2]),
        .src1(src1),
        .src0_out(remainder_reg[1]),
        .spo(quotient_reg[1]),
        .idx(1),
        .pos1(pos1),
        .pos2(pos2)
    );

    DIV u0_DIV(
        .src0(remainder_reg[1]),
        .src1(src1),
        .src0_out(remainder_reg[0]),
        .spo(quotient_reg[0]),
        .idx(0),
        .pos1(pos1),
        .pos2(pos2)
    );


endmodule

module DIV(
    input [32 : 0] src0,
    input [32 : 0] src1,
    output reg [32 : 0] src0_out,
    output reg [32 : 0] spo,
    input [32 : 0] idx,
    input [ 7 : 0] pos1,
    input [ 7 : 0] pos2
);
    wire [32:0] slt, src0_new;

    wire [32:0] adder_a;
    wire [32:0] adder_b;
    wire [32:0] adder_result;
    wire        adder_cout;
    wire [32:0] move;

    assign src0_new = ($signed(idx+1-pos1) > 0) ? (src1 << (idx - pos1)) : 32'h7fffffff;

    assign adder_a   = src0_new;
    assign adder_b   = ~src0;
    assign {adder_cout, adder_result} = adder_a + adder_b + 32'b1;

    assign slt[32:1] = 31'b0;   //rj < rk 1
    assign slt[0]    = (idx > pos2) ? 0 : ((src0_new[32] & ~src0[32])
                            | ((src0_new[32] ~^ src0[32]) & adder_result[32]));

    wire [32:0] write_pos;

    assign write_pos = ($signed(idx+1-pos1) > 0) ? idx-pos1 : 0;

    always @(*) begin
        if(slt[0]) begin
            spo[write_pos] = 1;
            src0_out = src0 - src0_new;
        end
        else begin
            spo[write_pos] = 0;
            src0_out = src0;
        end
    end
endmodule

module FIND1 (
    input       [32: 0]     data,
    output reg  [ 7: 0]     pos
);
    wire        [32:0]      atad;
    wire        [32:0]      atad_pos;

    assign atad[32] = data[0];
    assign atad[31] = data[1];
    assign atad[30] = data[2];
    assign atad[29] = data[3];
    assign atad[28] = data[4];
    assign atad[27] = data[5];
    assign atad[26] = data[6];
    assign atad[25] = data[7];
    assign atad[24] = data[8];
    assign atad[23] = data[9];
    assign atad[22] = data[10];
    assign atad[21] = data[11];
    assign atad[20] = data[12];
    assign atad[19] = data[13];
    assign atad[18] = data[14];
    assign atad[17] = data[15];
    assign atad[16] = data[16];
    assign atad[15] = data[17];
    assign atad[14] = data[18];
    assign atad[13] = data[19];
    assign atad[12] = data[20];
    assign atad[11] = data[21];
    assign atad[10] = data[22];
    assign atad[9]  = data[23];
    assign atad[8]  = data[24];
    assign atad[7]  = data[25];
    assign atad[6]  = data[26];
    assign atad[5]  = data[27];
    assign atad[4]  = data[28];
    assign atad[3]  = data[29];
    assign atad[2]  = data[30];
    assign atad[1]  = data[31];
    assign atad[0]  = data[32];
    
    assign atad_pos = atad & (~(atad-1));

    always @(*) begin
        case(atad_pos)
            (1<<32): pos = 0;
            (1<<31): pos = 1;
            (1<<30): pos = 2;
            (1<<29): pos = 3;
            (1<<28): pos = 4;
            (1<<27): pos = 5;
            (1<<26): pos = 6;
            (1<<25): pos = 7;
            (1<<24): pos = 8;
            (1<<23): pos = 9;
            (1<<22): pos = 10;
            (1<<21): pos = 11;
            (1<<20): pos = 12;
            (1<<19): pos = 13;
            (1<<18): pos = 14;
            (1<<17): pos = 15;
            (1<<16): pos = 16;
            (1<<15): pos = 17;
            (1<<14): pos = 18;
            (1<<13): pos = 19;
            (1<<12): pos = 20;
            (1<<11): pos = 21;
            (1<<10): pos = 22;
            (1<<9):  pos = 23;
            (1<<8):  pos = 24;
            (1<<7):  pos = 25;
            (1<<6):  pos = 26;
            (1<<5):  pos = 27;
            (1<<4):  pos = 28;
            (1<<3):  pos = 29;
            (1<<2):  pos = 30;
            (1<<1):  pos = 31;
            (1<<0):  pos = 32;
            default: pos = 33;
        endcase
    end

endmodule