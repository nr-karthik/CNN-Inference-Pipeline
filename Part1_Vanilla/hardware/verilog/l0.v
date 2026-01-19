// Created by prof. Mingu Kang @VVIP Lab in UCSD ECE department
// Please do not spread this code without permission 
module l0 (clk, in, out, rd, wr, o_full, reset, o_ready);

  parameter row  = 8;
  parameter bw = 4;

  input  clk;
  input  wr;
  input  rd;
  input  reset;
  input  [row*bw-1:0] in;
  output [row*bw-1:0] out;
  output o_full;
  output o_ready;

  wire [row-1:0] empty;
  wire [row-1:0] full;
  reg [row-1:0] rd_en;
  
  genvar i;

  assign o_ready = !o_full ;
  assign o_full  = full[0] | full[1] | full[2] | full[3] | full[4] | full[5] | full[6] | full[7] ;


  for (i=0; i<row ; i=i+1) begin : row_num
      fifo_depth64 #(.bw(bw)) fifo_instance (
	 .rd_clk(clk),
	 .wr_clk(clk),
	 .rd(rd_en[i]),
	 .wr(wr),
         .o_empty(empty[i]),
         .o_full(full[i]),
	 .in(in[((i+1)*bw)-1:i*bw]),
	 .out(out[((i+1)*bw)-1:i*bw]),
         .reset(reset));
  end


  always @ (posedge clk) begin
   if (reset) begin
      rd_en <= 8'b00000000;
   end
   else

      /////////////// version1: read all row at a time ////////////////
      //if (empty == 8'b00000000 && rd == 1'b1)
      //begin
      //	      rd_en <= 8'b11111111 ;
      //end
      ///////////////////////////////////////////////////////



      //////////////// version2: read 1 row at a time /////////////////

      if (rd == 1'b1)
      begin
             // if(empty[0] == 1'b0)
		      rd_en[0] <= 1'b1 ;
	      //if(empty[1] == 1'b0 & rd_en[0] == 1'b1 )
		      rd_en[1] <= rd_en[0] ;
            //  if(empty[2] == 1'b0 & rd_en[1] == 1'b1)
		      rd_en[2] <= rd_en[1] ;
            //  if(empty[3] == 1'b0 & rd_en[2] == 1'b1)
		      rd_en[3] <= rd_en[2] ;
            //  if(empty[4] == 1'b0 & rd_en[3] == 1'b1)
		      rd_en[4] <= rd_en[3];
           //   if(empty[5] == 1'b0 & rd_en[4] == 1'b1)
	 	      rd_en[5] <= rd_en[4] ;
          //    if(empty[6] == 1'b0 & rd_en[5] == 1'b1)
		      rd_en[6] <= rd_en[5] ;
	  //    if(empty[7] == 1'b0 & rd_en[6] == 1'b1)
		      rd_en[7] <= rd_en[6] ;

      end
      else
      begin
	      rd_en[0] <= 1'b0 ;
	      rd_en[1] <= rd_en[0] ;
	      rd_en[2] <= rd_en[1] ;
	      rd_en[3] <= rd_en[2] ;
	      rd_en[4] <= rd_en[3] ;
	      rd_en[5] <= rd_en[4] ;
	      rd_en[6] <= rd_en[5] ;
	      rd_en[7] <= rd_en[6] ;


      end

    end

endmodule
