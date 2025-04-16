module BRANCH (
    input       [ 3: 0]     br_type     ,
    input       [31: 0]     br_src0     ,
    input       [31: 0]     br_src1     ,
    output reg  [ 1: 0]     npc_sel
);
localparam Jal    = 4'b1000;
localparam Jalr   = 4'b1001;
localparam Beq    = 4'b0000;
localparam Bne    = 4'b0001;
localparam Blt    = 4'b0100;
localparam Bge    = 4'b0101;
localparam Bltu   = 4'b0110;
localparam Bgeu   = 4'b0111;
localparam None   = 4'b1111;

localparam PC_ADD4 = 2'B00;
localparam PC_OFFS = 2'B01;
localparam PC_JALR = 2'B10;

wire [31:0] adder_result;
wire [ 0:0] adder_cout;
wire [ 0:0] eq_result;
wire [ 0:0] slt_result;
wire [ 0:0] sltu_result;

assign eq_result[0]                 = (br_src0 == br_src1);  
assign {adder_cout, adder_result}   = br_src0 + {~br_src1} + {32'b1};
assign slt_result[0]                = (br_src0[31] & ~br_src1[31]) | ((br_src0[31] ~^ br_src1[31]) & adder_result[31]);
assign sltu_result[0]               = ~adder_cout;

always @(*) begin
    case (br_type)
        Jal : begin
            npc_sel = PC_OFFS;            
        end
        Jalr: begin
            npc_sel = PC_JALR;
        end
        Beq : begin
            npc_sel = eq_result ? PC_OFFS : PC_ADD4;
        end
        Bne : begin
            npc_sel = ~eq_result ? PC_OFFS : PC_ADD4;
        end
        Blt : begin
            npc_sel = slt_result ? PC_OFFS : PC_ADD4;
        end
        Bge : begin
            npc_sel = ~slt_result ? PC_OFFS : PC_ADD4;
        end
        Bltu: begin
            npc_sel = sltu_result ? PC_OFFS : PC_ADD4;
        end
        Bgeu: begin
            npc_sel = ~sltu_result ? PC_OFFS : PC_ADD4;
        end
        None: begin
            npc_sel = PC_ADD4;
        end
        default: begin
            npc_sel = PC_ADD4;
        end
    endcase
end
endmodule