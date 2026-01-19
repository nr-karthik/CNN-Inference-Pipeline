// Created by prof. Mingu Kang @VVIP Lab in UCSD ECE department
// Please do not spread this code without permission 
module mac_array (clk, reset, out_s, in_a, in_n, inst_w, valid, mode, flush);

  parameter bw = 4;
  parameter psum_bw = 16;
  parameter col = 8;
  parameter row = 8;

  input  clk, reset;
  output [psum_bw*col-1:0] out_s;
  input  [row*bw-1:0] in_a; // inst[1]:execute, inst[0]: kernel loading
  input  [1:0] inst_w;
  input  [col*bw -1:0] in_n;
  output [col-1:0] valid;
  input mode,flush;


  reg    [2*row-1:0] inst_w_temp;
  wire   [psum_bw*col*(row+1)-1:0] temp;
  wire   [row*col-1:0] valid_temp;


  genvar i;
 
  assign out_s = temp[psum_bw*col*9-1:psum_bw*col*8];
  assign temp[psum_bw*col*1-1:psum_bw*col*0] = 0;
  assign valid = valid_temp[row*col-1:row*col-8];

  for (i=1; i < col+1 ; i=i+1) begin : col_num
      mac_row #(.bw(bw), .psum_bw(psum_bw)) mac_row_instance (
         .clk(clk),
         .reset(reset),
	 .in_a(in_a[bw*i-1:bw*(i-1)]),
	 .inst_w(inst_w_temp[2*i-1:2*(i-1)]),
	 .in_n(in_n[bw*i-1:bw*(i-1)]),
         .valid(valid_temp[col*i-1:col*(i-1)]),
	 .mode(mode),
	 .flush(flush),
	 .out_s(temp[psum_bw*(i+1)-1:psum_bw*(i)]));
  end

  always @ (posedge clk) begin


    //valid <= valid_temp[row*col-1:row*col-8];
    inst_w_temp[1:0]   <= inst_w; 
    inst_w_temp[3:2]   <= inst_w_temp[1:0]; 
    inst_w_temp[5:4]   <= inst_w_temp[3:2]; 
    inst_w_temp[7:6]   <= inst_w_temp[5:4]; 
    inst_w_temp[9:8]   <= inst_w_temp[7:6]; 
    inst_w_temp[11:10] <= inst_w_temp[9:8]; 
    inst_w_temp[13:12] <= inst_w_temp[11:10]; 
    inst_w_temp[15:14] <= inst_w_temp[13:12]; 
  end



endmodule
