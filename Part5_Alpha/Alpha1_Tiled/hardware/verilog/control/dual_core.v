module dual_core (
	clk, reset, inst, ofifo_valid, D_xmem, sfp_out, mode, sel, tile, relu
);

// core holds 1 sram per act file (nij x rows), 1 (input) sram per weights file (rows x cols), 
// 1 corelet (rows x cols), 2 output sram (cols x nij?)

/*
	.clk(clk), 
	.inst(inst_q),
	.ofifo_valid(ofifo_valid),
	.D_xmem(D_xmem_q), 
	.sfp_out(sfp_out), 
	.reset(reset)); 
*/

input clk, reset;
input [33:0] inst;
output ofifo_valid;
input [b_bw*row-1:0] D_xmem;
output [psum_bw*col-1:0] sfp_out;
input mode; // 0: 2-bit mode, 1: 4-bit mode
input sel; // output sram selector.
input [1:0] tile;
input relu;


parameter bw = 2;
parameter b_bw = 4;
parameter psum_bw = 16;
parameter col = 2;
parameter row = 2;

/*
assign inst_q[33] = acc_q;              accumulate mode 
assign inst_q[32] = CEN_pmem_q;         pmem cen (low active, will not read/write when high)
assign inst_q[31] = WEN_pmem_q;         pmem wen (low active)
assign inst_q[30:20] = A_pmem_q;        pmem address
assign inst_q[19]   = CEN_xmem_q;       xmem cen (low active, will not read/write when high)
assign inst_q[18]   = WEN_xmem_q;       xmem wen (low active)
assign inst_q[17:7] = A_xmem_q;         xmem address
assign inst_q[6]   = ofifo_rd_q;        ofifo read enable (ofifo -> sram)
assign inst_q[5]   = ififo_wr_q;        ififo write enable? ignore
assign inst_q[4]   = ififo_rd_q;        ififo rd enable? ignore
	CHANGE inst_q[4] = SEL (SELECT SRAM OUTPUT BANK)
assign inst_q[3]   = l0_rd_q;           l0 read enable
assign inst_q[2]   = l0_wr_q;           l0 write enable
assign inst_q[1]   = execute_q;         load and execute activations
assign inst_q[0]   = load_q;            load weights
*/
reg acc_q;
reg cen_pmem_q;
reg wen_pmem_q;
reg [10:0] a_pmem_q;
reg cen_xmem_q;
reg wen_xmem_q;
reg [10:0] a_xmem_q;
reg ofifo_rd_q;
reg [4:0] inst_corelet_q;
reg sel_q;
reg wen_pmem_qq;
reg wen_pmem_qqq;
reg cen_pmem_qq;
reg cen_pmem_qqq;
reg sel_qq;
reg sel_qqq;
reg [10:0] a_pmem_qq;
reg [10:0] a_pmem_qqq;
reg [1:0] tile_q;
reg [1:0] tile_qq;
reg [1:0] tile_qqq;
reg relu_q;


reg [31:0] D_xmem_q;
// no ififo	

always @(posedge clk) begin
	if (reset) begin
		acc_q        <= 0;
		cen_pmem_q   <= 1;
		wen_pmem_q   <= 1;
		a_pmem_q     <= 0;
		cen_xmem_q   <= 1;
		wen_xmem_q   <= 1;
		a_xmem_q     <= 0;
		ofifo_rd_q   <= 0;
		inst_corelet_q <= 0;
		D_xmem_q    <= 0;
		sel_q <= 0;
		tile_q <= 0;
		relu_q <= 0;
	end

	else begin
		acc_q        <= inst[33];
		cen_pmem_q   <= inst[32];
		wen_pmem_q   <= inst[31];
		a_pmem_q     <= inst[30:20];
		cen_xmem_q   <= inst[19];
		wen_xmem_q   <= inst[18];
		a_xmem_q     <= inst[17:7];
		ofifo_rd_q   <= inst[6];
		inst_corelet_q <= {inst[3:2], mode, inst[1:0]};
		inst_corelet_qq <= inst_corelet_q;
		D_xmem_q    <= D_xmem;
		sel_q <= sel;
		
		sel_qq <= sel_q;
		sel_qqq <= sel_qq;
		wen_pmem_qq <= wen_pmem_q;
		wen_pmem_qqq <= wen_pmem_qq;
		cen_pmem_qq <= cen_pmem_q;
		cen_pmem_qqq <= cen_pmem_qq;
		a_pmem_qq <= a_pmem_q;
		a_pmem_qqq <= a_pmem_qq;
		tile_q <= tile;
		tile_qq <= tile_q;
		tile_qqq <= tile_qq;
		relu_q <= relu;
		
	end
end

wire [psum_bw*col-1:0] sfp_out;
reg [4:0] inst_corelet_qq;

/*
	differences in corelets:
		- same xmem set (in)
		- different output pmem set (out)
		- same ofifo valid time
		- same ofifo rd time
		- different o_sram_in
		- same sfu_en
		- different INST for l0 write and l0 read?
		- same exec
		- different INST for weightload
*/
corelet #(.bw(bw), .b_bw(b_bw), .psum_bw(psum_bw), .col(col), .row(row)) corelet_instance0 (
	.clk(clk),						
	.reset(reset),					
	.in(o_xmem),            		
	.out(o_corelet0),  				
	.inst({inst_corelet_qq[4:3] & {2{tile_qq[0]}}, inst_corelet_qq[2:1], inst_corelet_qq[0] & tile_qq[0]}),	
	.ofifo_rd(ofifo_rd_q),			
	.valid(ofifo_valid),		
	.o_sram_in(o_sram_corelet0), 	
	.sfu_en(acc_q),					
	.relu(relu_q)

);


corelet #(.bw(bw), .b_bw(b_bw), .psum_bw(psum_bw), .col(col), .row(row)) corelet_instance1 (
	.clk(clk),
	.reset(reset),
	.in(o_xmem),            
	.out(o_corelet1),      
	.inst({inst_corelet_qq[4:3] & {2{tile_qq[1]}}, inst_corelet_qq[2:1], inst_corelet_qq[0] & tile_qq[1]}),			// TODO
	.ofifo_rd(ofifo_rd_q),
	.valid(),
	.o_sram_in(o_sram_corelet1), 
	.sfu_en(acc_q),
	.relu(relu_q)

);

wire [psum_bw*col-1:0] o_corelet;
wire [psum_bw*col-1:0] o_corelet0;
wire [psum_bw*col-1:0] o_corelet1;

// corelet output set TODO
// corelet instruction set TODO

// xmem: activation memory
// write to xmem when wen_xmem_q = 0 and cen_xmem_q = 0
// should be unaffected by tiling
sram_32b_w2048 sram_x (
	.CLK(clk),
	.WEN(wen_xmem_q),
	.CEN(cen_xmem_q),
	.D(D_xmem_q),
	.A(a_xmem_q),
	.Q(o_xmem)
);

wire [31:0] o_xmem;
wire [psum_bw*col-1:0] o_pmem_even0;
wire [psum_bw*col-1:0] o_pmem_odd0;
wire [psum_bw*col-1:0] o_pmem_even1;
wire [psum_bw*col-1:0] o_pmem_odd1;

wire wen_pmem_even_qqq;
wire wen_pmem_odd_qqq;

// need to delay 2 cycles,

assign wen_pmem_even_qqq = !(!sel_qqq & !wen_pmem_qqq);
assign wen_pmem_odd_qqq = !(sel_qqq & !wen_pmem_qqq);

wire [psum_bw*col-1:0] sfp_out0;
wire [psum_bw*col-1:0] sfp_out1;


assign sfp_out0 = (sel_qqq ? o_pmem_odd0 : o_pmem_even0);
assign sfp_out1 = (sel_qqq ? o_pmem_odd1 : o_pmem_even1);



assign sfp_out = tile_qq[0] ? sfp_out0 : sfp_out1;

// acc_q, cen, wen, sel
// SEL = bank to write to (delay 2 cycles?)
// !SEL = bank to read from

wire [psum_bw*col-1:0] o_sram_corelet0;
wire [psum_bw*col-1:0] o_sram_corelet1;
// the "other" bank goes to corelet
assign o_sram_corelet0 = sel ? o_pmem_even0 : o_pmem_odd0;
assign o_sram_corelet1 = sel ? o_pmem_even1 : o_pmem_odd1;

// tile 0
sram_bank_32b_w2048 #(.col(col), .psum_bw(psum_bw)) sram_o_even0 (
	.CLK(clk ),
	.WEN(wen_pmem_even_qqq),
	.CEN(wen_pmem_even_qqq ? cen_pmem_q: cen_pmem_qqq),
	.D(o_corelet0),
	.A(wen_pmem_even_qqq ? a_pmem_q: a_pmem_qqq),
	.Q(o_pmem_even0)
);

sram_bank_32b_w2048 #(.col(col), .psum_bw(psum_bw)) sram_o_odd0 (
	.CLK(clk),
	.WEN(wen_pmem_odd_qqq),
	.CEN(wen_pmem_odd_qqq ? cen_pmem_q: cen_pmem_qqq),
	.D(o_corelet0),
	.A(wen_pmem_odd_qqq ? a_pmem_q: a_pmem_qqq),
	.Q(o_pmem_odd0)
);

// tile 1;
sram_bank_32b_w2048 #(.col(col), .psum_bw(psum_bw)) sram_o_even1 (
	.CLK(clk),
	.WEN(wen_pmem_even_qqq),
	.CEN(wen_pmem_even_qqq ? cen_pmem_q: cen_pmem_qqq),
	.D(o_corelet1),
	.A(wen_pmem_even_qqq ? a_pmem_q: a_pmem_qqq),
	.Q(o_pmem_even1)
);

sram_bank_32b_w2048 #(.col(col), .psum_bw(psum_bw)) sram_o_odd1 (
	.CLK(clk),
	.WEN(wen_pmem_odd_qqq),
	.CEN(wen_pmem_odd_qqq ? cen_pmem_q: cen_pmem_qqq),
	.D(o_corelet1),
	.A(wen_pmem_odd_qqq ? a_pmem_q: a_pmem_qqq),
	.Q(o_pmem_odd1)
);
endmodule