module mult (out, a, b);

parameter a_bw = 2;
parameter b_bw = 4;
parameter out_bw = 6;

output signed [out_bw-1:0] out;
input signed  [a_bw-1:0] a;  // activation
input signed  [b_bw-1:0] b;  // weight
wire signed [out_bw-1:0] product;
wire signed [a_bw:0] a_pad;

assign a_pad = {1'b0, a}; // force to be unsigned number
assign product = a_pad * b;
assign out = product;

endmodule