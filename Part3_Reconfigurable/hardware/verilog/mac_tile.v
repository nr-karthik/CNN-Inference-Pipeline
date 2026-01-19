// Created by prof. Mingu Kang @VVIP Lab in UCSD ECE department
// Please do not spread this code without permission 
module mac_tile (clk, out_s, in_a, out_e, in_n, inst_w, inst_e, reset,mode , flush);

parameter bw = 4;
parameter psum_bw = 16;

output reg [psum_bw-1:0] out_s; //PSUM output for this particular tile
//input  [bw-1:0] in_a; // inst[1]:execute, inst[0]: kernel loading
output [bw-1:0] out_e; 
input  [1:0] inst_w;
output [1:0] inst_e;
input  [psum_bw-1:0] in_n;
input  [bw-1:0] in_a;
input  clk;
input  reset;
input mode; //0 - WS 1- OS


reg [bw-1:0] b_q; //weight
reg [bw-1:0] a_q; //activation
reg [psum_bw-1:0] c_q; //psum
reg [1:0] inst_q ;
reg load_ready_q;
input flush;
wire [psum_bw - 1: 0] mac_out;

assign out_e = a_q;
assign inst_e = inst_q;

always@(posedge clk)
begin
	if(reset)
         begin
 	        b_q <= 0;
        	a_q <= 0;
        	c_q <= 0;
        	inst_q <= 2'b0;
         	load_ready_q <= 1'b1;
         end
	else
	 begin
                 c_q <= in_n; //psum in from previous tile
		 inst_q[1] <= inst_w[1] ; 

		 if (inst_w > 2'b0) //Activation load
			 a_q <= in_a;

		 if (((inst_w == 2'b01) || (inst_w == 2'b11)) && (load_ready_q == 1'b1)) // Weight load
		 begin
			 b_q <= in_n;
			 load_ready_q <= 0;
	         end

		 if (load_ready_q == 1'b0)			 
			 inst_q[0] <= inst_w[0];

   	 end

end




mac #(.bw(bw), .psum_bw(psum_bw)) mac_instance (
        .a(a_q), 
        .b(b_q),
        .c(c_q),
	.mode(mode),
	.out(mac_out)
);
always @(*)
begin
if(mode == 0)
out_s = mac_out;
else begin
	if(!flush)
	out_s = in_n;
else 
        out_s = mac_out;
end
end

endmodule
