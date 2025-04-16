module CPU (
    input                   [ 0 : 0]            clk,
    input                   [ 0 : 0]            rst,

    input                   [ 0 : 0]            global_en,

/* ------------------------------ Memory (inst) ----------------------------- */
    output                  [31 : 0]            imem_raddr,
    input                   [31 : 0]            imem_rdata,

/* ------------------------------ Memory (data) ----------------------------- */
    input                   [31 : 0]            dmem_rdata,
    output                  [ 0 : 0]            dmem_we,
    output                  [31 : 0]            dmem_addr,
    output                  [31 : 0]            dmem_wdata,

/* ---------------------------------- Debug --------------------------------- */
    output                  [ 0 : 0]            commit,
    output                  [31 : 0]            commit_pc,
    output                  [31 : 0]            commit_instr,
    output                  [ 0 : 0]            commit_halt,
    output                  [ 0 : 0]            commit_reg_we,
    output                  [ 4 : 0]            commit_reg_wa,
    output                  [31 : 0]            commit_reg_wd,
    output                  [ 0 : 0]            commit_dmem_we,
    output                  [31 : 0]            commit_dmem_wa,
    output                  [31 : 0]            commit_dmem_wd,

    input                   [ 4 : 0]            debug_reg_ra,   // TODO
    output                  [31 : 0]            debug_reg_rd    // TODO
);

wire        [31: 0]     cur_npc         ;
wire        [31: 0]     cur_pc          ;
wire        [ 1: 0]     npc_sel         ;
wire        [31: 0]     pc_add4         ;
wire        [31: 0]     pc_offs         ;
wire        [31: 0]     pc_j            ;

wire        [31: 0]     instr           ;

wire        [31: 0]     imm             ;
wire        [18: 0]     alu_op          ;
wire        [31: 0]     alu_src1        ;
wire        [31: 0]     alu_src2        ;
wire        [31: 0]     alu_result      ;
wire        [ 0: 0]     alu_src0_sel    ;
wire        [ 0: 0]     alu_src1_sel    ;

wire        [ 4: 0]     rf_ra0          ;
wire        [ 4: 0]     rf_ra1          ;
wire        [ 4: 0]     rf_wa           ;
wire        [31: 0]     rf_wd           ;
wire        [ 1: 0]     rf_wd_sel       ;
wire        [ 0: 0]     rf_we           ;
wire        [31: 0]     rf_rd0          ;
wire        [31: 0]     rf_rd1          ;

wire        [ 3: 0]     br_type         ;

wire        [ 3: 0]     dmem_access     ;
wire        [31: 0]     rd_out          ;
wire        [31: 0]     wd_out          ;
    // Commit
    reg  [ 0 : 0]   commit_reg          ;
    reg  [31 : 0]   commit_pc_reg       ;
    reg  [31 : 0]   commit_instr_reg    ;
    reg  [ 0 : 0]   commit_halt_reg     ;
    reg  [ 0 : 0]   commit_reg_we_reg   ;
    reg  [ 4 : 0]   commit_reg_wa_reg   ;
    reg  [31 : 0]   commit_reg_wd_reg   ;
    reg  [ 0 : 0]   commit_dmem_we_reg  ;
    reg  [31 : 0]   commit_dmem_wa_reg  ;
    reg  [31 : 0]   commit_dmem_wd_reg  ;

    // Commit
    always @(posedge clk) begin
        if (rst) begin
            commit_reg          <= 1'B0;
            commit_pc_reg       <= 32'H0;
            commit_instr_reg    <= 32'H0;
            commit_halt_reg     <= 1'B0;
            commit_reg_we_reg   <= 1'B0;
            commit_reg_wa_reg   <= 5'H0;
            commit_reg_wd_reg   <= 32'H0;
            commit_dmem_we_reg  <= 1'B0;
            commit_dmem_wa_reg  <= 32'H0;
            commit_dmem_wd_reg  <= 32'H0;
        end
        else if (global_en) begin
            commit_reg          <= 1'B1;
            commit_pc_reg       <= cur_pc;   // TODO
            commit_instr_reg    <= instr;   // TODO
            commit_halt_reg     <= instr == 32'H00100073;   // TODO
            commit_reg_we_reg   <= rf_we;   // TODO
            commit_reg_wa_reg   <= rf_wa;   // TODO
            commit_reg_wd_reg   <= rf_wd;   // TODO
            commit_dmem_we_reg  <= dmem_we;   // TODO
            commit_dmem_wa_reg  <= dmem_addr;   // TODO
            commit_dmem_wd_reg  <= dmem_wdata;   // TODO
        end
    end

    assign commit           = commit_reg;
    assign commit_pc        = commit_pc_reg;
    assign commit_instr     = commit_instr_reg;
    assign commit_halt      = commit_halt_reg;
    assign commit_reg_we    = commit_reg_we_reg;
    assign commit_reg_wa    = commit_reg_wa_reg;
    assign commit_reg_wd    = commit_reg_wd_reg;
    assign commit_dmem_we   = commit_dmem_we_reg;
    assign commit_dmem_wa   = commit_dmem_wa_reg;
    assign commit_dmem_wd   = commit_dmem_wd_reg;

assign instr        = imem_rdata;
assign imem_raddr   = cur_pc;

assign dmem_we      = dmem_access[3];
assign dmem_addr    = alu_result;
assign dmem_wdata   = wd_out;

assign pc_add4      = cur_pc + 32'h4;
assign pc_offs      = alu_result;
assign pc_j         = alu_result & ~1;

PC my_pc (
    .clk    (clk        ),
    .rst    (rst        ),
    .en     (global_en  ),    // 当 global_en 为高电平时，PC 才会更新，CPU 才会执行指令。
    .npc    (cur_npc    ),
    .pc     (cur_pc     )
);

BRANCH my_branch (
    .br_type    (br_type    ),
    .br_src0    (rf_rd0     ),
    .br_src1    (rf_rd1     ),
    .npc_sel    (npc_sel    )
);

NPCMUX my_npc_mux (
    .npc_sel    (npc_sel    ),
    .pc_add4    (pc_add4    ),
    .pc_offs    (pc_offs    ),
    .pc_j       (pc_j       ),
    .npc        (cur_npc    )
);

DECODER my_decoder (
    .inst           (instr          ),
    .alu_op         (alu_op         ),
    .dmem_access    (dmem_access    ),
    .imm            (imm            ),
    .rf_ra0         (rf_ra0         ),
    .rf_ra1         (rf_ra1         ),
    .rf_wa          (rf_wa          ),
    .rf_we          (rf_we          ),
    .rf_wd_sel      (rf_wd_sel      ),
    .alu_src0_sel   (alu_src0_sel   ),
    .alu_src1_sel   (alu_src1_sel   ),
    .br_type        (br_type        )
);

REG_FILE my_rf (
    .clk            (clk         ),
    .rf_ra0         (rf_ra0      ),
    .rf_ra1         (rf_ra1      ),
    .rf_wa          (rf_wa       ),
    .rf_we          (rf_we       ), 
    .rf_wd          (rf_wd       ),
    .rf_rd0         (rf_rd0      ),
    .rf_rd1         (rf_rd1      ),
    .debug_reg_ra   (debug_reg_ra),
    .debug_reg_rd   (debug_reg_rd)
);

MUX my_src1 (
    .src0       (cur_pc         ),
    .src1       (rf_rd0         ),
    .sel        (alu_src0_sel   ),
    .res        (alu_src1       )
);

MUX my_src2 (
    .src0       (rf_rd1         ),
    .src1       (imm            ),
    .sel        (alu_src1_sel   ),
    .res        (alu_src2       )
);

ALU my_alu (
    .alu_op     (alu_op     ),
    .alu_src1   (alu_src1   ),
    .alu_src2   (alu_src2   ),
    .alu_result (alu_result )
);

SLU my_slu(
    .addr       (alu_result ),
    .dmem_access(dmem_access),
    .rd_in      (dmem_rdata ),
    .wd_in      (rf_rd1     ),
    .rd_out     (rd_out     ),
    .wd_out     (wd_out     )  
);

RF_WD_MUX my_rfmux (
    .pc_add4    (pc_add4    ),
    .alu_res    (alu_result ),
    .dmem_rdata (rd_out     ),
    .rf_wd_sel  (rf_wd_sel  ),  
    .rf_wd      (rf_wd      )
);

endmodule

