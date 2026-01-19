module corelet (clk, reset,in_lfifo,out_ofifo, psum_stored_mem, inst_q, Relu_en, o_valid,sfp_out);

parameter row = 8;
parameter col = 8;
parameter bw = 4;
parameter psum_bw_ofifo = 16;
parameter psum_bw_mac = 16;

input clk;
input reset;
input Relu_en;
input [col*psum_bw_ofifo-1:0] psum_stored_mem;
input [33:0] inst_q;
input [row*bw-1:0] in_lfifo;
output [col*psum_bw_mac -1 :0] out_ofifo;
output   o_valid ;
output signed [col*psum_bw_ofifo-1:0] sfp_out;
wire [col*psum_bw_ofifo -1 :0] temp_out_psum;
wire wr_en_lfifo; //review logic required
wire rd_en_lfifo; //review logic required

wire [row*bw-1:0] out_lfifo;
wire o_full_lfifo;
wire o_ready_lfifo;
wire [psum_bw_mac*col-1:0] out_s;
wire [psum_bw_mac*col-1:0] in_n;//psum value from 
wire [col-1:0] valid_mac_array;

//wire [psum_bw_mac*col-1:0] out_ofifo;
wire o_full_ofifo, o_ready_ofifo, o_valid_ofifo;
wire [col-1:0] valid_ofifo;

//assign wr_en_lfifo = (inst_q > 2'b0 && (o_ready_lfifo)) ? 1'b1 : 1'b0;
////alpha
//assign rd_en_lfifo = (inst_q > 2'b0) ? 1'b1 : 1'b0;
//alpha
assign valid_ofifo = (o_ready_ofifo)? valid_mac_array : 8'b0 ; 

l0 #(.bw(bw), .row(row)) l0_fifo (
	.clk(clk), 
	.in(in_lfifo), 
	.out(out_lfifo), 
	.rd(inst_q[3]), .wr(inst_q[2]), .o_full(o_full), .reset(reset) , .o_ready(o_ready));


mac_array #(.bw(bw), .psum_bw(psum_bw_mac), .col(col), .row(row)) mac_array_design(
	.clk(clk), 
	.reset(reset),
       	.out_s(out_s), .in_w(out_lfifo), .in_n(128'b0), .inst_w(inst_q[1:0]), .valid (valid_mac_array));

ofifo #(.psum_bw(psum_bw_mac),.col(col)) o_fifo (.clk(clk), .in(out_s), .out(out_ofifo), .rd(inst_q[6]), .wr(valid_ofifo), .o_full(o_full), .reset(reset), .o_ready(o_ready_ofifo), .o_valid(o_valid));

genvar i;

for (i=0 ; i<col; i=i+1) begin : sfu_col


	accumulator_sfu #(.psum_bw(psum_bw_ofifo)) sfu_instance(
		.clk(clk),
		.reset(reset), 
		.psum_stored_q(psum_stored_mem[(i+1)*psum_bw_ofifo -1 : i*psum_bw_ofifo]), 
		.out(sfp_out[(i+1)*psum_bw_ofifo -1 : i*psum_bw_ofifo]),
		.Relu_en(Relu_en),
	        .acc_q(inst_q[33]));
	
	
end





endmodule


	




