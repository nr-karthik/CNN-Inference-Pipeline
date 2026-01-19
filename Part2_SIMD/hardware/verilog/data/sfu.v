// Created by prof. Mingu Kang @VVIP Lab in UCSD ECE department
// Please do not spread this code without permission 
module sfu (clk, psum_in, psum_mem, valid, psum_out, relu);
// if (MAC) output is valid, accumulate the psums.
// psum_in directly from MAC
// psum_mem read from DRAM

parameter psum_bw = 32;

input clk;
input signed  [psum_bw-1:0] psum_in; 
input signed [psum_bw-1:0] psum_mem;
input valid;
output reg signed [psum_bw-1:0] psum_out;
input relu;

always @(posedge clk) begin
	if (valid) begin
		if (relu)
			psum_out <= ((psum_in + psum_mem) < 0) ? 0 : (psum_in + psum_mem);
		else
			psum_out <= psum_in + psum_mem;
	end

end

endmodule