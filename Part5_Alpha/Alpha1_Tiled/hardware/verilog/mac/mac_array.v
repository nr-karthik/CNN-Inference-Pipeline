// Created by prof. Mingu Kang @VVIP Lab in UCSD ECE department
// Please do not spread this code without permission 
module mac_array (clk, reset, out_s, in_w, in_n, inst_w, valid);

parameter bw = 2;
parameter b_bw = 4;
parameter psum_bw = 32;
parameter col = 8;
parameter row = 8;

input  clk, reset;

output [psum_bw*col-1:0] out_s;
output [col-1:0] valid;

input  [row*bw*2-1:0] in_w; // 2 inputs per row
input  [2:0] inst_w;
input  [psum_bw*col-1:0] in_n;

wire [row*col-1:0] temp_vld;
wire [(row+1)*col*psum_bw-1:0] temp_psum;

reg [3*row-1:0] temp_instw;

assign temp_psum[col*psum_bw-1:0] = in_n; // top row psum input
assign valid[col-1:0] = temp_vld[row*col-1: (row-1)*col]; // last row valid = array valid
assign out_s = temp_psum[(psum_bw*col*(row+1))-1:psum_bw*col*row]; // last row psum output

genvar i;
generate
for (i=0; i < row ; i=i+1) begin : row_num
	mac_row #(.bw(bw), .b_bw(b_bw), .psum_bw(psum_bw), .col(col)) mac_row_instance (
	.clk(clk),
	.out_s(temp_psum[(i+2)*col*psum_bw-1:(i+1)*col*psum_bw]),
	.in_n(temp_psum[(i+1)*col*psum_bw-1:(i)*col*psum_bw]),
	.in_w0(in_w[bw*(2*i+1)-1:bw*(2*i)]),
	.in_w1(in_w[bw*(2*i+2)-1:bw*(2*i+1)]),
	.valid(temp_vld[(i+1)*col-1:(i)*col]),
	.inst_w(temp_instw[3*(i+1)-1:3*(i)]),
	.reset(reset)
	);
end
endgenerate

always @ (posedge clk) begin
	// inst_w flows to row0 to row7
	temp_instw[2:0] <= inst_w;
	temp_instw[3*(row)-1:3] <= temp_instw[3*(row-1)-1:0]; 
end

endmodule
