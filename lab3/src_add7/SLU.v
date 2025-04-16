module SLU (
    input       [31: 0]     addr        ,
    input       [ 3: 0]     dmem_access ,
    input       [31: 0]     rd_in       ,
    input       [31: 0]     wd_in       ,

    output reg  [31: 0]     rd_out      ,
    output reg  [31: 0]     wd_out  
);
    always @(*) begin
        case (dmem_access)
            4'b0000:begin
                wd_out = wd_in;
                if (addr[1:0]==2'b00) begin
                    rd_out = {{24{rd_in[7]}},rd_in[7:0]}; 
                end
                else if (addr[1:0]==2'b01) begin
                    rd_out = {{24{rd_in[15]}},rd_in[15:8]}; 
                end
                else if (addr[1:0]==2'b10) begin
                    rd_out = {{24{rd_in[23]}},rd_in[23:16]}; 
                end
                else begin
                    rd_out = {{24{rd_in[31]}},rd_in[31:24]}; 
                end
            end
            4'b0001:begin
                wd_out = wd_in;
                if (addr[1:0]==2'b00) begin
                    rd_out = {{16{rd_in[15]}},rd_in[15:0]}; 
                end
                else if (addr[1:0]==2'b10) begin
                    rd_out = {{16{rd_in[31]}},rd_in[31:16]}; 
                end
                else begin
                    rd_out = rd_in; 
                end
            end
            4'b0100:begin
                wd_out = wd_in;
                if (addr[1:0]==2'b00) begin
                    rd_out = {{24'b0},rd_in[7:0]}; 
                end
                else if (addr[1:0]==2'b01) begin
                    rd_out = {{24'b0},rd_in[15:8]}; 
                end
                else if (addr[1:0]==2'b10) begin
                    rd_out = {{24'b0},rd_in[23:16]}; 
                end
                else begin
                    rd_out = {{24'b0},rd_in[31:24]}; 
                end
            end
            4'b0101:begin
                wd_out = wd_in;
                if (addr[1:0]==2'b00) begin
                    rd_out = {{16'b0},rd_in[15:0]}; 
                end
                else if (addr[1:0]==2'b10) begin
                    rd_out = {{16'b0},rd_in[31:16]}; 
                end
                else begin
                    rd_out = rd_in; 
                end
            end
            4'b1000:begin
                rd_out = rd_in;
                if (addr[1:0]==2'b00) begin
                    wd_out = {rd_in[31:8],wd_in[7:0]}; 
                end
                else if (addr[1:0]==2'b01) begin
                    wd_out = {rd_in[31:16],wd_in[7:0],rd_in[7:0]}; 
                end
                else if (addr[1:0]==2'b10) begin
                    wd_out = {rd_in[31:24],wd_in[7:0],rd_in[15:0]}; 
                end
                else begin
                    wd_out = {wd_in[7:0],rd_in[23:0]}; 
                end
            end
            4'b1001:begin
                rd_out = rd_in;
                if (addr[1:0]==2'b00) begin
                    wd_out = {rd_in[31:16],wd_in[15:0]}; 
                end
                else if (addr[1:0]==2'b10) begin
                    wd_out = {wd_in[15:0],rd_in[15:0]}; 
                end
                else begin
                    wd_out = wd_in; 
                end
            end
            default:begin
                rd_out = rd_in;
                wd_out = wd_in; 
            end
        endcase
    end
endmodule