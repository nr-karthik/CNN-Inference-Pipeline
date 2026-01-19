// ===============================================================
// Created by (your name) based on modules from Prof. Mingu Kang
// VVIP Lab - UCSD ECE Department
// Corelet Module: Integrates L0 → MAC Array → SFU → OFIFO
// ===============================================================

module corelet #(
    parameter bw        = 4,    // weight bitwidth
    parameter psum_bw   = 32,   // psum bitwidth
    parameter row       = 8,    // number of MAC rows
    parameter col       = 8     // number of MAC cols
)(
    input                       clk,
    input                       reset,
    input [3:0]                inst,
    input [bw*row-1:0]          D_xmem, //goes to L0
    input [psum_bw*col-1:0] mem_read_psum, //input from memory
    output [psum_bw*col-1:0] sfu_out_flat,
    output o_ready_l0,
    output reg wr_mem,
    output reg rd_ofifo

);

  wire load      = inst[0];
  wire execute   = inst[1]; 
  wire l0_wr     = inst[2];
  wire l0_rd     = inst[3];


    wire [bw*row-1:0] act_wgt_out;
    wire l0_full;

    l0 #(
        .bw(bw),
        .row(row)
    ) L0_inst (
        .clk(clk),
        .in(D_xmem),
        .out(act_wgt_out),
        .rd(l0_rd),          // fr
        .wr(l0_wr),
        .o_full(l0_full), //connect
        .reset(reset), //connect
        .o_ready(o_ready_l0) //connect
    );


wire [psum_bw*col-1:0] psum_array_out;
//reg [psum_bw*col-1:0] fifo_in_reg;
/*
always @(posedge clk) begin
    if (reset)
        fifo_in_reg <= 0;
    else
        fifo_in_reg <= psum_array_out; // latch MAC output
end
*/

wire [psum_bw*col-1:0] in_n_bus;
assign in_n_bus = {psum_bw*col{1'b0}};

wire [col-1:0] mac_valid;
  mac_array #(
    .bw      (bw),
    .psum_bw (psum_bw),
    .col     (col),
    .row     (row)
  ) mac_array_inst (
    .clk    (clk),
    .reset  (reset),
    .out_s  (psum_array_out),
    .in_w   (act_wgt_out),         // weights from L0
    .in_n   (in_n_bus),              //(placeholder)
    .inst_w ({execute, load}),       // inst_w[1]=execute, [0]=kernel load
    .valid  (mac_valid)     //connect
  );

wire ofifo_ready;
wire [col-1:0] wr_fifo;
wire ofifo_full;
wire ofifo_valid;
wire [psum_bw*col-1:0] out_vector;
assign wr_fifo = mac_valid & {col{ofifo_ready}};

    ofifo #(
        .col(col),
        .psum_bw(psum_bw)
    ) OFIFO_inst (
        .clk(clk),
        .in(psum_array_out),
        .out(out_vector),
        .rd(rd_ofifo), //check
        .wr(wr_fifo),     
        .o_full(ofifo_full),
        .reset(reset),
        .o_ready(ofifo_ready), //used
        .o_valid(ofifo_valid)
    );


reg psum_valid;
always @(posedge clk) begin
    if (reset)begin
        rd_ofifo <= 1'b0;
        psum_valid <= 1'b0;

    end
    else begin
        rd_ofifo <= ofifo_valid;   // read whenever data is valid
        psum_valid <= rd_ofifo;

    end
end

always @(posedge clk) begin
    if (psum_valid)
        wr_mem <= 1'b1;
    else
        wr_mem <= 1'b0;
end


  genvar c;
  generate
    for (c = 0; c < col; c = c + 1) begin : GEN_SFU_COL
      sfu #(
        .psum_bw(psum_bw),
        .bw     (bw)
      ) u_sfu (
        .clk(clk),
        .psum_buf(out_vector[(c+1)*psum_bw-1 : c*psum_bw]),
        .psum_mem(mem_read_psum[(c+1)*psum_bw-1 : c*psum_bw]),
        .psum_out(sfu_out_flat[(c+1)*psum_bw-1 : c*psum_bw]),
        .valid(psum_valid)
      );

    end
  endgenerate


endmodule
