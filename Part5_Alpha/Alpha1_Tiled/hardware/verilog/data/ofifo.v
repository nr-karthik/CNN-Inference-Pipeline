// Created by prof. Mingu Kang @VVIP Lab in UCSD ECE department
// Please do not spread this code without permission 
module ofifo (clk, in, out, rd, wr, o_full, reset, o_ready, o_valid);

parameter col  = 8;
parameter bw = 4;

input  clk;
input  [col-1:0] wr;
input  rd;
input  reset;
input  [bw*col-1:0] in;
output [bw*col-1:0] out;
output o_full;
output o_ready;
output o_valid;

wire [col-1:0] empty;
wire [col-1:0] full;
reg  rd_en;

genvar i;

assign o_ready = ~o_full;
assign o_full  = |full;
assign o_valid = !rempty;

wire rempty;
assign rempty = |empty;

generate
for (i=0; i<col ; i=i+1) begin : col_num
	fifo_depth64 #(.bw(bw)) fifo_instance (
		.rd_clk(clk),
		.wr_clk(clk),
		.rd(rd_en),
		.wr(wr[i]),
		.o_empty(empty[i]),
		.o_full(full[i]),
		.in(in[(i+1)*bw-1:bw*i]),
		.out(out[(i+1)*bw-1:bw*i]),
		.reset(reset));
end
endgenerate


always @ (posedge clk) begin
	if (reset)
		rd_en <= 0;
	else
		rd_en <= rd && o_valid;

end


endmodule
