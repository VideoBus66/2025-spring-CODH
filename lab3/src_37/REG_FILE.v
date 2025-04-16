module REG_FILE(
    input                   [ 0 : 0]            clk,

    input                   [ 4 : 0]            rf_ra0,
    input                   [ 4 : 0]            rf_ra1,
    input                   [ 4 : 0]            rf_wa,
    input                   [ 0 : 0]            rf_we,
    input                   [31 : 0]            rf_wd,

    output                  [31 : 0]            rf_rd0,
    output                  [31 : 0]            rf_rd1,
    input                   [ 4 : 0]            debug_reg_ra,
    output                  [31 : 0]            debug_reg_rd
    );
reg [31 : 0] rf [ 0:31];

integer i;
initial begin
    for (i = 0; i < 32; i = i + 1)
        rf[i] = 0; 
end

assign rf_rd0 = rf[rf_ra0];    // 读操作
assign rf_rd1 = rf[rf_ra1];
assign debug_reg_rd = rf[debug_reg_ra];
always  @(posedge clk)
    if (rf_we & (rf_wa != 5'b0))  
        rf[rf_wa] <= rf_wd;   // 写操作
endmodule