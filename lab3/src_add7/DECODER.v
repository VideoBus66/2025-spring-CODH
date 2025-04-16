module DECODER (
    input                   [31 : 0]            inst,

    output                  [18 : 0]            alu_op,

    output                  [ 3 : 0]            dmem_access,

    output                  [31 : 0]            imm,

    output                  [ 4 : 0]            rf_ra0,
    output                  [ 4 : 0]            rf_ra1,
    output                  [ 4 : 0]            rf_wa,
    output                  [ 0 : 0]            rf_we,
    output                  [ 1 : 0]            rf_wd_sel,

    output                  [ 0 : 0]            alu_src0_sel,
    output                  [ 0 : 0]            alu_src1_sel,

    output                  [ 3 : 0]            br_type
);
wire [ 6: 0]    inst_0_6;
wire [ 4: 0]    inst_7_11;
wire [ 2: 0]    inst_12_14;
wire [ 4: 0]    inst_15_19;
wire [ 4: 0]    inst_20_24;
wire [ 6: 0]    inst_25_31;

wire inst_sll;
wire inst_slli;
wire inst_srl;
wire inst_srli;
wire inst_sra;
wire inst_srai;

wire inst_add;
wire inst_addi;
wire inst_sub;
wire inst_xor;
wire inst_xori;
wire inst_or;
wire inst_ori;
wire inst_and;
wire inst_andi;

wire inst_slt;
wire inst_sltu;
wire inst_slti;
wire inst_sltiu;
wire inst_auipc;
wire inst_lui;

wire inst_beq;
wire inst_blt;
wire inst_bne;
wire inst_bge;
wire inst_bltu;
wire inst_bgeu;
wire inst_jal;
wire inst_jalr;

wire inst_lw;
wire inst_lb;
wire inst_lh;
wire inst_lbu;
wire inst_lhu;
wire inst_sw;
wire inst_sb;
wire inst_sh;

wire inst_mul;
wire inst_mulh;
wire inst_mulhu;
wire inst_div;
wire inst_divu;
wire inst_rem;
wire inst_remu;

wire s21_j;
wire s20_imm;
wire s13_br;
wire s12_ld;
wire s12_st;
wire s12_opjr;
wire u05_sh;

wire rf_nowe;
wire alu_src0_nosel;

assign inst_0_6     = inst[ 6: 0];
assign inst_7_11    = inst[11: 7];
assign inst_12_14   = inst[14:12];
assign inst_15_19   = inst[19:15];
assign inst_20_24   = inst[24:20];
assign inst_25_31   = inst[31:25];

assign inst_sll     = (inst_0_6 == 7'b0110011) & (inst_12_14 == 3'b001);
assign inst_slli    = (inst_0_6 == 7'b0010011) & (inst_12_14 == 3'b001);
assign inst_srl     = (inst_0_6 == 7'b0110011) & (inst_12_14 == 3'b101) & (inst_25_31 == 7'b0000000);
assign inst_srli    = (inst_0_6 == 7'b0010011) & (inst_12_14 == 3'b101) & (inst_25_31 == 7'b0000000);
assign inst_sra     = (inst_0_6 == 7'b0110011) & (inst_12_14 == 3'b101) & (inst_25_31 == 7'b0100000);
assign inst_srai    = (inst_0_6 == 7'b0010011) & (inst_12_14 == 3'b101) & (inst_25_31 == 7'b0100000);

assign inst_add     = (inst_0_6 == 7'b0110011) & (inst_12_14 == 3'b000) & (inst_25_31 == 7'b0000000);
assign inst_addi    = (inst_0_6 == 7'b0010011) & (inst_12_14 == 3'b000);
assign inst_sub     = (inst_0_6 == 7'b0110011) & (inst_12_14 == 3'b000) & (inst_25_31 == 7'b0100000);
assign inst_xor     = (inst_0_6 == 7'b0110011) & (inst_12_14 == 3'b100);
assign inst_xori    = (inst_0_6 == 7'b0010011) & (inst_12_14 == 3'b100);
assign inst_or      = (inst_0_6 == 7'b0110011) & (inst_12_14 == 3'b110);
assign inst_ori     = (inst_0_6 == 7'b0010011) & (inst_12_14 == 3'b110);
assign inst_and     = (inst_0_6 == 7'b0110011) & (inst_12_14 == 3'b111);
assign inst_andi    = (inst_0_6 == 7'b0010011) & (inst_12_14 == 3'b111);

assign inst_slt     = (inst_0_6 == 7'b0110011) & (inst_12_14 == 3'b010);
assign inst_sltu    = (inst_0_6 == 7'b0110011) & (inst_12_14 == 3'b011);
assign inst_slti    = (inst_0_6 == 7'b0010011) & (inst_12_14 == 3'b010);
assign inst_sltiu   = (inst_0_6 == 7'b0010011) & (inst_12_14 == 3'b011);
assign inst_auipc   = (inst_0_6 == 7'b0010111);
assign inst_lui     = (inst_0_6 == 7'b0110111);

assign inst_beq     = (inst_0_6 == 7'b1100011) & (inst_12_14 == 3'b000); 
assign inst_bne     = (inst_0_6 == 7'b1100011) & (inst_12_14 == 3'b001);
assign inst_blt     = (inst_0_6 == 7'b1100011) & (inst_12_14 == 3'b100);
assign inst_bge     = (inst_0_6 == 7'b1100011) & (inst_12_14 == 3'b101);
assign inst_bltu    = (inst_0_6 == 7'b1100011) & (inst_12_14 == 3'b110);
assign inst_bgeu    = (inst_0_6 == 7'b1100011) & (inst_12_14 == 3'b111);
assign inst_jal     = (inst_0_6 == 7'b1101111);
assign inst_jalr    = (inst_0_6 == 7'b1100111);

assign inst_lb      = (inst_0_6 == 7'b0000011) & (inst_12_14 == 3'b000);
assign inst_lh      = (inst_0_6 == 7'b0000011) & (inst_12_14 == 3'b001);
assign inst_lw      = (inst_0_6 == 7'b0000011) & (inst_12_14 == 3'b010);
assign inst_lbu     = (inst_0_6 == 7'b0000011) & (inst_12_14 == 3'b100);
assign inst_lhu     = (inst_0_6 == 7'b0000011) & (inst_12_14 == 3'b101);
assign inst_sb      = (inst_0_6 == 7'b0100011) & (inst_12_14 == 3'b000);
assign inst_sh      = (inst_0_6 == 7'b0100011) & (inst_12_14 == 3'b001);
assign inst_sw      = (inst_0_6 == 7'b0100011) & (inst_12_14 == 3'b010); 

assign inst_mul     = (inst_0_6 == 7'b0110011) & (inst_12_14 == 3'b000) & (inst_25_31 == 7'b0000001);
assign inst_mulh    = (inst_0_6 == 7'b0110011) & (inst_12_14 == 3'b001) & (inst_25_31 == 7'b0000001);
assign inst_mulhu   = (inst_0_6 == 7'b0110011) & (inst_12_14 == 3'b011) & (inst_25_31 == 7'b0000001);
assign inst_div     = (inst_0_6 == 7'b0110011) & (inst_12_14 == 3'b100) & (inst_25_31 == 7'b0000001);
assign inst_divu    = (inst_0_6 == 7'b0110011) & (inst_12_14 == 3'b101) & (inst_25_31 == 7'b0000001);
assign inst_rem     = (inst_0_6 == 7'b0110011) & (inst_12_14 == 3'b110) & (inst_25_31 == 7'b0000001);
assign inst_remu    = (inst_0_6 == 7'b0110011) & (inst_12_14 == 3'b111) & (inst_25_31 == 7'b0000001);

assign alu_op[ 0]     = inst_add    | inst_addi  | inst_auipc 
                        | inst_jal  | inst_jalr 
                        | inst_lb   | inst_lbu   | inst_lh   | inst_lhu  | inst_lw 
                        | inst_sb   | inst_sh    | inst_sw
                        | inst_beq  | inst_bne   | inst_blt  | inst_bge
                        | inst_bltu | inst_bgeu;
assign alu_op[ 1]     = inst_sub;
assign alu_op[ 2]     = inst_slt    | inst_slti;
assign alu_op[ 3]     = inst_sltu   | inst_sltiu;
assign alu_op[ 4]     = inst_and    | inst_andi ;
assign alu_op[ 5]     = 0;
assign alu_op[ 6]     = inst_or     | inst_ori;
assign alu_op[ 7]     = inst_xor    | inst_xori;
assign alu_op[ 8]     = inst_sll    | inst_slli;
assign alu_op[ 9]     = inst_srl    | inst_srli;
assign alu_op[10]     = inst_sra    | inst_srai;
assign alu_op[11]     = inst_lui;

assign alu_op[12]     = inst_mul;
assign alu_op[13]     = inst_mulh;
assign alu_op[14]     = inst_mulhu;
assign alu_op[15]     = inst_div;
assign alu_op[16]     = inst_divu;
assign alu_op[17]     = inst_rem;
assign alu_op[18]     = inst_remu;

assign s21_j          = inst_jal;
assign s20_imm        = inst_lui    | inst_auipc;
assign s13_br         = inst_beq    | inst_bne   | inst_blt  | inst_bge
                        | inst_bltu | inst_bgeu;
assign s12_ld         = inst_lb     | inst_lbu   | inst_lh   | inst_lhu  | inst_lw;
assign s12_st         = inst_sb     | inst_sh    | inst_sw;
assign s12_opjr       = inst_addi   | inst_andi  | inst_ori  | inst_xori 
                        | inst_slti | inst_sltiu | inst_jalr;
assign u05_sh         = inst_slli   | inst_srai  | inst_srli;

assign dmem_access    = s12_ld      ? {{1'b0},inst_12_14[2:0]}                                  :
                        s12_st      ? {{1'b1},inst_12_14[2:0]}                                  :
                                      4'b0111                                                   ;

assign imm            = s21_j       ? {{12{inst[31]}},inst[19:12],inst[20],inst[30:21],{1'b0}}  :
                        s20_imm     ? {{inst[31:12]},{12'b0}}                                   :
                        s13_br      ? {{20{inst[31]}},inst[7],inst[30:25],inst[11:8],{1'b0}}    :
                        s12_ld      ? {{20{inst[31]}},inst[31:20]}                              :
                        s12_st      ? {{20{inst[31]}},inst[31:25],inst[11: 7]}                  :
                        s12_opjr    ? {{20{inst[31]}},inst[31:20]}                              :
                        u05_sh      ? {{27'b0},inst[24:20]}                                     :
                                      0                                                         ;
assign rf_ra0         = inst_15_19;
assign rf_ra1         = inst_20_24;
assign rf_wa          = inst_7_11;
assign rf_nowe        = s12_st      | s13_br     | inst == 32'H00100073;
assign rf_we          = ~rf_nowe;
assign rf_wd_sel[0]   = inst_jal    | inst_jalr;
assign rf_wd_sel[1]   = s12_ld;

assign alu_src0_nosel = inst_auipc  | inst_beq   | inst_bne  | inst_blt  | inst_bge
                        | inst_bltu | inst_bgeu  | inst_jal;
assign alu_src0_sel   = ~alu_src0_nosel;
assign alu_src1_sel   = inst_addi   | inst_andi  | inst_ori  | inst_xori | inst_lui
                        | inst_slli | inst_srli  | inst_srai | inst_slti | inst_sltiu
                        | inst_beq  | inst_bne   | inst_blt  | inst_bge  
                        | inst_bltu | inst_bgeu  | inst_jal  | inst_jalr | inst_auipc 
                        | inst_lb   | inst_lbu   | inst_lh   | inst_lhu  | inst_lw
                        | inst_sb   | inst_sh    | inst_sw;

assign br_type        = (inst_0_6 == 7'b1100011) ? {1'b0,inst_12_14}     :
                        inst_jal                 ? 4'b1000               :
                        inst_jalr                ? 4'b1001               :
                                                   4'b1111               ;

endmodule