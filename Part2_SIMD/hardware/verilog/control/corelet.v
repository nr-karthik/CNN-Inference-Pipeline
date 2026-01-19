/*
corelet.v is just a wrapper that includes all blocks you designed so far (L0/Input
FIFO, OFIFO, MAC Array, SFP?).    
*/

module corelet (clk, reset, in, out, inst, valid, ofifo_rd, o_sram_in, sfu_en, relu);
parameter bw = 2;
parameter b_bw = 4;
parameter psum_bw = 32;
parameter col = 8;
parameter row = 8;

input  clk, reset;
input [4:0] inst; // [wr][mode][exec][weightload]
input [row*bw*2-1:0] in; // from input sram
output [psum_bw*col-1:0] out; // to output sram
output valid;
input ofifo_rd;
input [psum_bw*col-1:0] o_sram_in; // o_sram_in for SFU 
input sfu_en;
input relu;
// ofifo_out + o_sram_in -> SFU

wire l0_wr;
wire l0_rd;
wire exec;
wire weightload;
wire mode;

// wire ofifo_valid;

assign valid = o_valid; // ofifo_ready_delay;
reg ofifo_ready_delay_2;
always @(posedge clk) begin
	if (reset)
		ofifo_ready_delay_2 <= 0;
	else
		ofifo_ready_delay_2 <= ofifo_ready_delay;
end

assign l0_rd = inst[4]; // from l0 to mac array
assign l0_wr = inst[3]; // from SRAM to l0
assign mode = inst[2];
assign exec = inst[1];
assign weightload = inst[0];

/*
	input (from sram) -> input fifo -> mac array -> output fifo -> output
*/

reg [psum_bw*col-1:0] in_n;

wire [psum_bw*col-1:0] mac_out;
wire [bw*row*2-1:0] wire_a; // input fifo to mac array
wire [col-1:0] mac_valid; // mac array to output fifo

wire ofifo_rd;

always @(posedge clk) begin
	if (reset)
		in_n <= 0;
end

// l0 fifo l0 (clk, in, out, rd, wr, o_full, reset, o_ready);
// wr = write into l0 (from sram)
// rd = read from l0 (into mac)
// o_ready = l0 is ready to accept new data from sram

l0 #(.row(row), .bw(bw*2)) l0_instance (
	.clk(clk),
	.reset(reset),
	.in(in),            // connect to input sram
	.out(wire_a),       // connect to mac array
	.rd(l0_rd),          // 
	.wr(l0_wr),          // connect to input sram
	.o_full(),          // not needed
	.o_ready());        // not needed

// mode must be externally given
// RD from input fifo when exec|weightload|other??
// inst_w[2:0] : [mode][exec][weightload]
mac_array #(.bw(bw), .b_bw(b_bw), .psum_bw(psum_bw), .col(col), .row(row)) mac_array_instance (
	.clk(clk),
	.reset(reset),
	.out_s(mac_out),// connect to ofifo
	.in_w(wire_a),  // connect to input fifo
	.in_n(in_n),        // connect to persistent 0?
	.inst_w({mode, exec, weightload}),      // connect to input fifo
	.valid(mac_valid));

// wr = write into ofifo (from mac array)
// rd = read from ofifo (into sram)
// ofifo (clk, in, out, rd, wr, o_full, reset, o_ready, o_valid);

reg [col-1:0] mac_out_ready;
always @(posedge clk) begin
	if (reset)
		mac_out_ready <= 0;
	else
		mac_out_ready <= mac_valid;
end


reg ofifo_ready_delay;
always @(posedge clk) begin
	if (reset)
		ofifo_ready_delay <= 0;
	else
		ofifo_ready_delay <= ofifo_rd;
end

wire o_valid;
reg o_valid_q;

ofifo #(.col(col), .bw(psum_bw)) ofifo_instance (
	.clk(clk),
	.reset(reset),
	.in(mac_out),      // connect to mac array
	.out(ofifo_out), // connect to sram
	.rd(ofifo_rd),   // ofifo_rd       // can start reading the moment o_valid is high
	.wr(mac_valid),      // connect to mac array
	.o_full(),      // not needed
	.o_ready(),     // not needed
	.o_valid(o_valid));    // valid if ALL col have output (1 whole row). but this is already checked in ofifo?

// ignore sfu for now.

// ofifo must be delayed 2


wire [psum_bw * col - 1:0] sfu_out;
wire [psum_bw * col - 1:0] ofifo_out;
reg [psum_bw * col - 1:0] ofifo_out_q;
reg [psum_bw * col - 1:0] ofifo_out_qq;
reg sfu_en_q;
reg sfu_en_qq;
reg sfu_en_qqq;
always @(posedge clk) begin
	if (reset)
		ofifo_out_q <= 0;
	else
		ofifo_out_q <= ofifo_out;
		ofifo_out_qq <= ofifo_out_q;
		sfu_en_q <= sfu_en;
		sfu_en_qq <= sfu_en_q;
		sfu_en_qqq <= sfu_en_qq;
		o_valid_q <= o_valid;
end


sfu_bank #(.col(col), .psum_bw(psum_bw)) sfu_bank_instance (
	.clk(clk),
	.psum_in(ofifo_out_q),
	.psum_mem(o_sram_in),
	.valid(o_valid_q),
	.psum_out(sfu_out),
	.relu(relu)
);

// sfu enable then sfu_out is output, else use ofifo out
// note sfu output will be delayed 1 more than ofifo out.
// eg. cycle 1 ofifo_out + sram_in -> cycle 2 = sfu_out

// SRAM READ (0)

// OFIFO_OUT produced (1)
// SRAM_IN arrives 

// SFU_OUT exits (2), must be written to same index SRAM on diff bank.
assign out = sfu_en_qqq ? sfu_out : ofifo_out_qq;

endmodule