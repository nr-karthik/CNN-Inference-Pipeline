module adder (out, in, psum);

parameter in_bw = 8; 
parameter psum_bw = 32;

output signed [psum_bw-1:0] out;
input signed  [in_bw-1:0] in;
input signed  [psum_bw-1:0] psum;

assign out = in + psum;

endmodule