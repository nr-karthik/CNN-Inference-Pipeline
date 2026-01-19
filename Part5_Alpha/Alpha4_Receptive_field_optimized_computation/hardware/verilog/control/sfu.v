// Created by prof. Mingu Kang @VVIP Lab in UCSD ECE department
// Please do not spread this code without permission 
module sfu (clk, psum_buf, psum_mem, valid, psum_out);

parameter psum_bw = 32;
parameter bw = 4;

input                       clk;
input signed  [psum_bw-1:0] psum_buf; 
input signed [psum_bw-1:0] psum_mem;
input valid;
output reg signed [psum_bw-1:0] psum_out;



always @(posedge clk) begin
    if (valid) begin
        psum_out <= psum_buf + psum_mem;
    end
    else
	psum_out <= 0;

end

endmodule
