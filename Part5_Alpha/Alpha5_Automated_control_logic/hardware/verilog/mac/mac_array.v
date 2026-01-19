// Created by prof. Mingu Kang @VVIP Lab in UCSD ECE department
// Please do not spread this code without permission 
module mac_array (clk, reset, out_s, in_w, in_n, inst_w, valid);

  parameter bw = 4;
  parameter psum_bw = 16;
  parameter col = 8;
  parameter row = 8;

  input  clk, reset;
  output [psum_bw*col-1:0] out_s;
  input  [row*bw-1:0] in_w; // inst[1]:execute, inst[0]: kernel loading
  input  [1:0] inst_w;
  input  [psum_bw*col-1:0] in_n;
  output [col-1:0] valid;

  wire [row*col-1:0] temp_vld;
  wire [(row+1)*col*psum_bw-1:0] temp;

  reg [2*row-1:0] temp_instw;

  assign temp[col*psum_bw-1:0] = in_n;
  assign valid[col-1:0] = temp_vld[row*col-1: (row-1)*col];
  assign out_s = temp[(psum_bw*col*9)-1:psum_bw*col*8];

  genvar i;
  for (i=1; i < row+1 ; i=i+1) begin : row_num
      mac_row #(.bw(bw), .psum_bw(psum_bw)) mac_row_instance (
      .clk(clk),
      .out_s(temp[(i+1)*col*psum_bw-1:(i)*col*psum_bw]),
      .in_n(temp[i*col*psum_bw-1:(i-1)*col*psum_bw]),
      .in_w(in_w[bw*i-1:bw*(i-1)]),
      .valid(temp_vld[i*col-1:(i-1)*col]),
      .inst_w(temp_instw[2*i-1:2*(i-1)]),
      .reset(reset)
      );
  end

  always @ (posedge clk) begin
	// inst_w flows to row0 to row7
	temp_instw[1:0] <= inst_w;
	temp_instw[3:2] <= temp_instw[1:0];
	temp_instw[5:4] <= temp_instw[3:2];
	temp_instw[7:6] <= temp_instw[5:4];
	temp_instw[9:8] <= temp_instw[7:6];
	temp_instw[11:10] <= temp_instw[9:8];
	temp_instw[13:12] <= temp_instw[11:10];
	temp_instw[15:14] <= temp_instw[13:12];

  end

endmodule
