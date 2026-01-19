// =====================
// Instantiate CORE
// =====================

`timescale 1ns/1ps


module core_tb;

  // parameters
  parameter bw      = 4;
  parameter psum_bw = 32;
  parameter row     = 8;
  parameter col     = 8;
  parameter M = 6;
  parameter K = 3;
  parameter len_nij = 16;
  parameter M_sqr =36;
 
  // Clock / reset
  reg clk   = 0;
  reg reset = 1;

  reg         wen_act_wgt = 1; //WEN_xmem
  reg         cen_act_wgt = 1; //CEN_xmem
  reg  [31:0] din_act_wgt; //D_xmem
  reg  [10:0] addr_act_wgt = 0; //A_xmem

  reg         wen_act_wgt_q = 1; //WEN_xmem_q
  reg         cen_act_wgt_q = 1; //CEN_xmem
  reg  [31:0] din_act_wgt_q = 0; //D_xmem_q
  reg  [10:0] addr_act_wgt_q = 0; //A_xmem_q

  // psum memory interface (not really used by your core logic;
  // core drives its own internal cen_out_mem/wen_out_mem)

  wire [psum_bw*col-1:0] final_psum_vector; //sfp_out

wire[6:0] inst_q;

reg load_q = 0;
reg execute_q =0;
reg l0_rd_q = 0;
reg l0_wr_q = 0;
reg rchip_q = 0;
reg final_mem_read_q =0;
reg mem_write_q = 0;

reg load;
reg execute;
reg l0_rd;
reg l0_wr;
reg rchip;
reg final_mem_read;
reg mem_write;

integer x_file, x_scan_file ; // file_handler
integer w_file, w_scan_file ; // file_handler
integer acc_file, acc_scan_file ; // file_handler
integer out_file, out_scan_file ; // file_handler
integer captured_data; 
integer t, i, j, k, kij;
integer error;
integer oy, ox;
integer ki, kj;

assign inst_q[0] = load_q;
assign inst_q[1] = execute_q;
assign inst_q[2] = l0_wr_q;
assign inst_q[3] = l0_rd_q;
assign inst_q[4] = final_mem_read_q;
assign inst_q[5] = rchip_q;
assign inst_q[6] = mem_write_q;

core #(
    .bw      (bw),
    .psum_bw (psum_bw),
    .row     (row),
    .col     (col),
    .len_nij (len_nij)
  ) dut (
    .clk          (clk),
    .reset        (reset),
    .inst         (inst_q),
    .wen_act_wgt  (wen_act_wgt_q),
    .cen_act_wgt  (cen_act_wgt_q),
    .din_act_wgt  (din_act_wgt_q),
    .addr_act_wgt (addr_act_wgt_q),
    .final_psum_vector(final_psum_vector)
  );

reg [8*30:1] w_file_name;

initial begin 

load = 0;
execute =0;
l0_rd = 0;
l0_wr = 0;
rchip = 1;
final_mem_read = 0;
mem_write = 0;

wen_act_wgt = 1; //WEN_xmem
cen_act_wgt = 1; //CEN_xmem
din_act_wgt = 0; //D_xmem
addr_act_wgt = 0; //A_xmem


$dumpfile("core_tb.vcd");
$dumpvars(0,core_tb);
    x_file  = $fopen("../datafiles/act_t.txt", "r");
    if (x_file == 0) begin
        $display("ERROR: could not open input.txt");
        $finish;
    end
  // Following three lines are to remove the first three comment lines of the file
  x_scan_file = $fscanf(x_file,"%s", captured_data);
  x_scan_file = $fscanf(x_file,"%s", captured_data);
  x_scan_file = $fscanf(x_file,"%s", captured_data);
 
 
  //////// Reset /////////
  #0.5 clk = 1'b0;   reset = 1;
  #0.5 clk = 1'b1; 

  for (i=0; i<10 ; i=i+1) begin
    #0.5 clk = 1'b0;
    #0.5 clk = 1'b1;  
  end

  #0.5 clk = 1'b0;   reset = 0;
  #0.5 clk = 1'b1; 

  #0.5 clk = 1'b0;   
  #0.5 clk = 1'b1;

  for (t=0; t<len_nij+2; t=t+1) begin  
    #0.5 clk = 1'b0; mem_write = 1;
    #0.5 clk = 1'b1;   
  end
  #0.5 clk = 1'b0;   reset = 1;
  #0.5 clk = 1'b1;
  #0.5 clk = 1'b0;
  #0.5 clk = 1'b1;

  #0.5 clk = 1'b0;  mem_write =0;
  #0.5 clk = 1'b1; 


  for (i=0; i<10 ; i=i+1) begin
    #0.5 clk = 1'b0;
    #0.5 clk = 1'b1;  
  end

  #0.5 clk = 1'b0;   reset = 0;
  #0.5 clk = 1'b1; 

  #0.5 clk = 1'b0;   
  #0.5 clk = 1'b1;

// addr activation is 0
    /////// Activation data writing to memory ///////
  for (t=0; t<M_sqr; t=t+1) begin  
    #0.5 clk = 1'b0;  x_scan_file = $fscanf(x_file,"%32b", din_act_wgt); wen_act_wgt = 0; cen_act_wgt = 0; if (t>0) addr_act_wgt = addr_act_wgt + 1;
    #0.5 clk = 1'b1;   
  end

  #0.5 clk = 1'b0;  wen_act_wgt = 1;  cen_act_wgt = 1; addr_act_wgt = 0;
  #0.5 clk = 1'b1; 

  $fclose(x_file); 

// Loop over all kij
for (kij = 0; kij < K*K; kij = kij + 1) begin

case (kij)
  0: w_file_name = "../datafiles/weight_kij0.txt";
  1: w_file_name = "../datafiles/weight_kij1.txt";
  2: w_file_name = "../datafiles/weight_kij2.txt";
  3: w_file_name = "../datafiles/weight_kij3.txt";
  4: w_file_name = "../datafiles/weight_kij4.txt";
  5: w_file_name = "../datafiles/weight_kij5.txt";
  6: w_file_name = "../datafiles/weight_kij6.txt";
  7: w_file_name = "../datafiles/weight_kij7.txt";
  8: w_file_name = "../datafiles/weight_kij8.txt";
  default: begin
      $display("ERROR: Invalid kij=%0d", kij);
      $finish;
  end
endcase

  w_file = $fopen(w_file_name, "r");
    // Following three lines are to remove the first three comment lines of the file
  w_scan_file = $fscanf(w_file,"%s", captured_data);
  w_scan_file = $fscanf(w_file,"%s", captured_data);
  w_scan_file = $fscanf(w_file,"%s", captured_data);

  #0.5 clk = 1'b0;   rchip=kij%2;
  #0.5 clk = 1'b1;
  #0.5 clk = 1'b0;
  #0.5 clk = 1'b1;
  #0.5 clk = 1'b0;   reset = 1;
  #0.5 clk = 1'b1; 

    for (i=0; i<5 ; i=i+1) begin
      #0.5 clk = 1'b0;
      #0.5 clk = 1'b1;  
    end

    #0.5 clk = 1'b0;   reset = 0;
    #0.5 clk = 1'b1; 

    #0.5 clk = 1'b0;   
    #0.5 clk = 1'b1;   

        /////// Kernel data writing to memory ///////

    addr_act_wgt= 11'b10000000000;

    for (t=0; t<col; t=t+1) begin  
      #0.5 clk = 1'b0;  w_scan_file = $fscanf(w_file,"%32b", din_act_wgt); wen_act_wgt  = 0; cen_act_wgt  = 0; if (t>0) addr_act_wgt= addr_act_wgt + 1; 
      #0.5 clk = 1'b1;  
    end

    #0.5 clk = 1'b0;  wen_act_wgt  = 1;  cen_act_wgt  = 1; addr_act_wgt = 0;
    #0.5 clk = 1'b1;
    for (i=0; i<5 ; i=i+1) begin
      #0.5 clk = 1'b0;
      #0.5 clk = 1'b1;  
    end


    /////// Kernel data writing to L0 ///////
    /////////////////////////////////////
    addr_act_wgt= 11'b10000000000;

    #0.5 clk = 1'b0;  wen_act_wgt  = 1;  cen_act_wgt  = 0; l0_wr = 1'b0;
    #0.5 clk = 1'b1;

     for (t=0; t<col; t=t+1) begin 
    	#0.5 clk = 1'b0;  l0_wr = 1'b1;  addr_act_wgt= addr_act_wgt + 1; 
    	#0.5 clk = 1'b1;
     end
 
    #0.5 clk = 1'b0;  wen_act_wgt  = 1;  cen_act_wgt  = 1; addr_act_wgt = 0; l0_wr = 1'b0;
    #0.5 clk = 1'b1;

    for (i=0; i<5 ; i=i+1) begin
      #0.5 clk = 1'b0;
      #0.5 clk = 1'b1;  
    end


    /////// Kernel data loading from L0 to PE ///////
    /////////////////////////////////////

     for (t=0; t<col; t=t+1) begin 
    	#0.5 clk = 1'b0;  l0_rd = 1'b1; load = 1'b1; 
    	#0.5 clk = 1'b1;
     end

    #0.5 clk = 1'b0;  l0_rd = 1'b0; load = 1'b0; 
    #0.5 clk = 1'b1;

    for (i=0; i<20 ; i=i+1) begin
      #0.5 clk = 1'b0;
      #0.5 clk = 1'b1;  
    end
/*
    /////////////////////////////////////

   ///////  data writing to L0 ///////
    /////////////////////////////////////
    addr_act_wgt= 11'b00000000000;

    #0.5 clk = 1'b0;  wen_act_wgt  = 1;  cen_act_wgt  = 0; l0_wr = 1'b0;
    #0.5 clk = 1'b1;

     for (t=0; t<len_nij; t=t+1) begin 
    	#0.5 clk = 1'b0;  l0_wr = 1'b1;  addr_act_wgt= addr_act_wgt + 1; 
    	#0.5 clk = 1'b1;
     end
 
    #0.5 clk = 1'b0;  wen_act_wgt  = 1;  cen_act_wgt  = 1; addr_act_wgt = 0; l0_wr = 1'b0;
    #0.5 clk = 1'b1;

    for (i=0; i<5 ; i=i+1) begin
      #0.5 clk = 1'b0;
      #0.5 clk = 1'b1;  
    end

  */

///////  KIJ-AWARE ACTIVATION WRITING TO L0 ///////
//////////////////////////////////////////////////

	addr_act_wgt = 11'b00000000000;

	#0.5 clk = 1'b0;
	wen_act_wgt  = 1;
	cen_act_wgt  = 0;
	l0_wr        = 0;
	#0.5 clk = 1'b1;

	// Loop over all kij
	ki = kij / K;
	kj = kij % K;

    // Loop over valid output window
	for (oy = 0; oy < (M-K+1); oy = oy + 1) begin
 		for (ox = 0; ox < (M-K+1); ox = ox + 1) begin            		

			addr_act_wgt = (ki + oy)*M + (kj + ox);
            		#0.5 clk = 1'b0;
           		l0_wr = 1'b1;
            		#0.5 clk = 1'b1;

        	end
    	end

    #0.5 clk = 1'b0;  wen_act_wgt  = 1;  cen_act_wgt  = 1; addr_act_wgt = 0; l0_wr = 1'b0;
    #0.5 clk = 1'b1;

    for (i=0; i<5 ; i=i+1) begin
      #0.5 clk = 1'b0;
      #0.5 clk = 1'b1;  
    end
 

    /////// Kernel data loading from L0 to PE ///////
    /////////////////////////////////////

     for (t=0; t<len_nij; t=t+1) begin 
    	#0.5 clk = 1'b0;  l0_rd = 1'b1; execute = 1'b1; 
    	#0.5 clk = 1'b1;
     end

    #0.5 clk = 1'b0;  l0_rd = 1'b0; execute = 1'b0; 
    #0.5 clk = 1'b1;

    for (i=0; i<100 ; i=i+1) begin
      #0.5 clk = 1'b0;
      #0.5 clk = 1'b1;  
    end

    /////////////////////////////////////

end
end

always @ (posedge clk) begin

   din_act_wgt_q   <= din_act_wgt;
   cen_act_wgt_q <= cen_act_wgt;
   wen_act_wgt_q <= wen_act_wgt;
   addr_act_wgt_q <= addr_act_wgt;
   l0_rd_q    <= l0_rd;
   l0_wr_q    <= l0_wr ;
   execute_q  <= execute;
   load_q     <= load;
   rchip_q <= rchip;
   final_mem_read_q <= final_mem_read;
   mem_write_q <= mem_write;

end



endmodule
