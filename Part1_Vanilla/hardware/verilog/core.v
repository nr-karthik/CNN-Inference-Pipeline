module core (clk, inst,ofifo_valid,D_xmem, sfp_out, reset,Relu_en);

parameter row = 8;
parameter col = 8;
parameter bw = 4;
parameter psum_bw_ofifo = 16;
parameter psum_bw_mac = 16;
parameter sram_act_size = 8192;

input clk;
input [33:0] inst;
input Relu_en;
output ofifo_valid;
input signed [row*bw-1:0] D_xmem;
wire signed [col*psum_bw_ofifo-1:0] input_sfp_out;
output reg signed [col*psum_bw_ofifo-1:0] sfp_out;
input reset;
input [2:0] sram_sel_fifo;
input [2:0] sram_sel_output;


wire [col*psum_bw_mac -1 :0] out_ofifo;
wire o_valid;
wire [row*bw-1:0] output_act;


wire [psum_bw_ofifo-1:0] psum_stored_1;
wire [psum_bw_ofifo-1:0] psum_stored_2;
wire [psum_bw_ofifo-1:0] psum_stored_3;
wire [psum_bw_ofifo-1:0] psum_stored_4;
wire [psum_bw_ofifo-1:0] psum_stored_5;
wire [psum_bw_ofifo-1:0] psum_stored_6;
wire [psum_bw_ofifo-1:0] psum_stored_7;
wire [psum_bw_ofifo-1:0] psum_stored_8;
wire [col*psum_bw_ofifo-1:0] psum_stored_mem;
reg [col*psum_bw_ofifo-1:0] temp_out_ofifo;
wire [col*psum_bw_ofifo-1:0] temp_out_psum;

wire [psum_bw_ofifo-1:0] psum_stored_out_1;
wire [psum_bw_ofifo-1:0] psum_stored_out_2;
wire [psum_bw_ofifo-1:0] psum_stored_out_3;
wire [psum_bw_ofifo-1:0] psum_stored_out_4;
wire [psum_bw_ofifo-1:0] psum_stored_out_5;
wire [psum_bw_ofifo-1:0] psum_stored_out_6;
wire [psum_bw_ofifo-1:0] psum_stored_out_7;
wire [psum_bw_ofifo-1:0] psum_stored_out_8;
reg [psum_bw_ofifo-1:0] psum_stored_sfp;

corelet #(.row(row),.col(col),.bw(bw),.psum_bw_ofifo(psum_bw_ofifo),.psum_bw_mac(psum_bw_mac)) corelet_1 (.clk(clk), .reset(reset), .psum_stored_mem(psum_stored_mem),.in_lfifo(output_act),.out_ofifo(out_ofifo), .inst_q(inst), .Relu_en(Relu_en), .o_valid(o_valid),.sfp_out(input_sfp_out));

always@(posedge clk)
begin
	if(reset)
		temp_out_ofifo <= 0;
	else
		if(o_valid) begin
			temp_out_ofifo[15:0] <= out_ofifo[15:0];
			temp_out_ofifo[31:16] <= out_ofifo[31:16];
			temp_out_ofifo[47:32] <= out_ofifo[47:32];
			temp_out_ofifo[63:48] <= out_ofifo[63:48];
			temp_out_ofifo[79:64] <= out_ofifo[79:64];
			temp_out_ofifo[95:80] <= out_ofifo[95:80];
			temp_out_ofifo[111:96] <= out_ofifo[111:96];
			temp_out_ofifo[127:112] <= out_ofifo[127:112];
		end
end


sram_32b_w2048 sram_activation (.CLK(clk), .D(D_xmem), .Q(output_act), .CEN(inst[19]), .WEN(inst[18]), .A(inst[17:7]));

sram_16b_w2048  sram_psum_oc1 (.CLK(clk), .D(temp_out_ofifo[15:0]), .Q(psum_stored_1), .CEN(inst[32]), .WEN(inst[31]), .A(inst[30:20]));
sram_16b_w2048  sram_psum_oc2 (.CLK(clk), .D(temp_out_ofifo[31:16]), .Q(psum_stored_2), .CEN(inst[32]), .WEN(inst[31]), .A(inst[30:20]));
sram_16b_w2048  sram_psum_oc3 (.CLK(clk), .D(temp_out_ofifo[47:32]), .Q(psum_stored_3), .CEN(inst[32]), .WEN(inst[31]), .A(inst[30:20]));
sram_16b_w2048  sram_psum_oc4 (.CLK(clk), .D(temp_out_ofifo[63:48]), .Q(psum_stored_4), .CEN(inst[32]), .WEN(inst[31]), .A(inst[30:20]));
sram_16b_w2048  sram_psum_oc5 (.CLK(clk), .D(temp_out_ofifo[79:64]), .Q(psum_stored_5), .CEN(inst[32]), .WEN(inst[31]), .A(inst[30:20]));
sram_16b_w2048  sram_psum_oc6 (.CLK(clk), .D(temp_out_ofifo[95:80]), .Q(psum_stored_6), .CEN(inst[32]), .WEN(inst[31]), .A(inst[30:20]));
sram_16b_w2048  sram_psum_oc7 (.CLK(clk), .D(temp_out_ofifo[111:96]), .Q(psum_stored_7), .CEN(inst[32]), .WEN(inst[31]), .A(inst[30:20]));
sram_16b_w2048  sram_psum_oc8 (.CLK(clk), .D(temp_out_ofifo[127:112]), .Q(psum_stored_8), .CEN(inst[32]), .WEN(inst[31]), .A(inst[30:20]));

assign psum_stored_mem = (inst[33])?({psum_stored_8,psum_stored_7,psum_stored_6,psum_stored_5,psum_stored_4,psum_stored_3,psum_stored_2,psum_stored_1}):0;


always@(posedge clk)
begin
	if(reset)
	begin
                sfp_out <= 0;
	end
	else
		begin
	if(inst[33]== 1'b1) 

		sfp_out <= input_sfp_out ;

	end


end


endmodule
