// Created by prof. Mingu Kang @VVIP Lab in UCSD ECE department
// Please do not spread this code without permission 
module mac (out, a, b, c, mode);

parameter bw = 4;
parameter psum_bw = 16;

output signed [psum_bw-1:0] out;
input signed  [bw-1:0] a;  // activation
input signed  [bw-1:0] b;  // weight
input signed  [psum_bw-1:0] c;
input mode; //0- WS 1-OS


wire signed [2*bw:0] product;
reg signed [psum_bw-1:0] psum;
wire signed [bw:0]   a_pad;

assign a_pad = {1'b0, a}; // force to be unsigned number
assign product = a_pad * b;
always@(*)
begin
if(mode == 1'b0)
psum = product + c;
else
psum = psum + product;
end


assign out = psum;
endmodule
