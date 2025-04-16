module RF_WD_MUX (
    input           [31: 0]     pc_add4     ,
    input           [31: 0]     alu_res     ,
    input           [31: 0]     dmem_rdata  ,
    input           [ 1: 0]     rf_wd_sel   ,  
    output          [31: 0]     rf_wd
);
assign rf_wd = rf_wd_sel[0] ? pc_add4       :
               rf_wd_sel[1] ? dmem_rdata    : 
                              alu_res       ;
endmodule