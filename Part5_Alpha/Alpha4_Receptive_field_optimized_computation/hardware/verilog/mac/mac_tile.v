// Created by prof. Mingu Kang @VVIP Lab in UCSD ECE department
// Please do not spread this code without permission 
module mac_tile (clk, out_s, in_w, out_e, in_n, inst_w, inst_e, reset);

parameter bw = 4;
parameter psum_bw = 16;

output [psum_bw-1:0] out_s;
input  [bw-1:0] in_w; // inst[1]:execute, inst[0]: kernel loading
output [bw-1:0] out_e; 
input  [1:0] inst_w;
output [1:0] inst_e;
input  [psum_bw-1:0] in_n;
input  clk;
input  reset;

reg [bw-1:0] a_q;
reg [bw-1:0] b_q;
reg [psum_bw-1:0] c_q;
reg [1:0] inst_q;
reg load_ready_q;
wire [psum_bw-1:0] mac_output;

assign out_e[bw-1:0] = a_q[bw-1:0];
assign inst_e[1:0] = inst_q[1:0];
assign out_s[psum_bw-1:0] = mac_output[psum_bw-1:0];

mac #(.bw(bw), .psum_bw(psum_bw)) mac_instance (
        .a(a_q), 
        .b(b_q),
        .c(c_q),
	.out(mac_output)
); 

always@(posedge clk)
begin
	if(reset==1'b1)
	begin
		a_q <= 0;
		b_q <= 0;
		c_q <= 0;
		inst_q <= 2'b00;
		load_ready_q <= 1'b1; //weight not loaded yet
	end
	else
	begin
		inst_q[1] <= inst_w[1];// each cycle forward the execute bit
		c_q[psum_bw-1:0] <= in_n[psum_bw-1:0]; // psum from previous mac used as c in a*b +c
		if (inst_w!=2'b00)//no kernel loading and no execute //check
			a_q<=in_w;
	 	if ((inst_w[0] == 1'b1) && (load_ready_q == 1'b1))
		begin
			b_q<=in_w;	// weight is b_q		
			load_ready_q <=0;
		end
		else if(load_ready_q == 1'b0)//weight loaded then instruction
			inst_q[0] <= inst_w[0];
	end
end
endmodule

