// Created by prof. Mingu Kang @VVIP Lab in UCSD ECE department
// Please do not spread this code without permission 
module mac_row (clk, out_s, in_w0, in_w1, in_n, valid, inst_w, reset);

parameter bw = 2;
parameter b_bw = 4;
parameter psum_bw = 32;
parameter col = 8;


input  clk, reset;
// out_s for dual psum output
output [psum_bw*col-1:0] out_s;
output [col-1:0] valid;
input  [bw-1:0] in_w0; 
input  [bw-1:0] in_w1; 
input  [2:0] inst_w; // inst[1]:execute, inst[0]: kernel loading
input  [psum_bw*col-1:0] in_n;

wire  [(col+1)*bw-1:0] temp0;
wire  [(col+1)*bw-1:0] temp1;

wire  [(col+1)*3-1:0] inst;

assign temp0[bw-1:0] = in_w0;
assign temp1[bw-1:0] = in_w1;

assign inst[2:0] = inst_w[2:0];

/*
mac_tile (clk, reset
	out_s0, out_s1, in_w0, in_w1, 
	out_e0, out_e1, in_n0, in_n1, 
	inst_w, inst_e, );
*/

/*
	// inst_w/e[2] = mode. 1 = 4bit mode, 0 = 2bit mode
	// inst_w/e[1] = exec
	// inst_w/e[0] = weightload
*/

genvar i;
generate
for (i=0; i < col; i=i+1) begin : col_num
	mac_tile #(.bw(bw), .b_bw(b_bw), .psum_bw(psum_bw)) mac_tile_instance (
		.clk(clk),
		.reset(reset),
		.in_w0(temp0[bw*(i+1)-1:bw*i]),
		.in_w1(temp1[bw*(i+1)-1:bw*i]),
		.out_e0(temp0[bw*(i+2)-1:bw*(i+1)]),
		.out_e1(temp1[bw*(i+2)-1:bw*(i+1)]),

		// fix below? is this fine??
		// in this manner, we can have entire psum row output right???
		.in_n(in_n[psum_bw*(i+1)-1:psum_bw*i]),
		.out_s(out_s[psum_bw*(i+1)-1:psum_bw*i]),
		
		// this is fine
		.inst_w(inst[3*(i+1)-1:3*i]),
		.inst_e(inst[3*(i+2)-1:3*(i+1)]));
		// valid is the exec bit passing through. -1 = mode -2 = exec
	// valid flag when the dual psum is ready.
	assign valid[i] = inst[3*(i+2)-2];
end
endgenerate

endmodule
