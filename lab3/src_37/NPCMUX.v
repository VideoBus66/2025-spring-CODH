module NPCMUX (
    input           [ 1: 0]     npc_sel,
    input           [31: 0]     pc_add4,
    input           [31: 0]     pc_offs,
    input           [31: 0]     pc_j,
    output reg      [31: 0]     npc
);
    always @(*) begin
        case (npc_sel)
            2'b00:npc = pc_add4;
            2'b01:npc = pc_offs;
            2'b10:npc = pc_j;
            default:npc = pc_add4;
        endcase
    end
endmodule