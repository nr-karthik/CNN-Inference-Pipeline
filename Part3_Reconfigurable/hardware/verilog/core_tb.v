// Created by prof. Mingu Kang @VVIP Lab in UCSD ECE department
// Please do not spread this code without permission 
`timescale 1ns/1ps

module core_tb;

parameter bw = 4;
parameter psum_bw = 16;
parameter len_kij = 9; // 9;
parameter len_onij = 16;// 32;
parameter col = 8;
parameter row = 8;
parameter len_nij = 36; //1156;

reg clk = 0;
reg reset = 1;

wire [48:0] inst_q; 
wire Relu_en_c;

reg [1:0]  inst_w_q = 0; 
reg [bw*row-1:0] D_xmem_q = 0;
reg [bw*col-1:0] D_wmem_q =0;
reg CEN_wmem = 1;
reg WEN_wmem = 1;
reg CEN_xmem = 1;
reg WEN_xmem = 1;
reg [10:0] A_xmem = 0;
reg [10:0] A_wmem = 0;
reg CEN_xmem_q = 1;
reg WEN_xmem_q = 1;
reg [10:0] A_xmem_q = 0;
reg CEN_pmem = 1;
reg WEN_pmem = 1;
reg CEN_pmem_out = 1;
reg WEN_pmem_out = 1;
reg [10:0] A_pmem = 0;
reg [9:0] A_pmem_out = 0;
reg CEN_pmem_q = 1;
reg WEN_pmem_q = 1;
reg CEN_wmem_q =1;
reg WEN_wmem_q = 1;
reg [10:0] A_wmem_q = 0;
reg CEN_pmem_out_q = 1;
reg WEN_pmem_out_q = 1;
reg [10:0] A_pmem_q = 0;
reg [9:0] A_pmem_out_q = 0;
reg ofifo_rd_q = 0;
reg ififo_wr_q = 0;
reg ififo_rd_q = 0;
reg l0_rd_q = 0;
reg l0_wr_q = 0;
reg execute_q = 0;
reg load_q = 0;
reg acc_q = 0;
reg Relu_en_q = 0;
reg acc = 0;
reg mode = 0;
reg flush = 0;

reg [1:0]  inst_w; 
reg [bw*row-1:0] D_xmem;
reg [bw*row-1:0] D_wmem;
reg [psum_bw*col-1:0] answer;

reg flush_q;
reg mode_q;
reg ofifo_rd;
reg ififo_wr;
reg ififo_rd;
reg l0_rd;
reg l0_wr;
reg execute;
reg load;
reg [8*30:1] stringvar;
reg [8*30:1] w_file_name;
wire ofifo_valid;
wire [col*psum_bw-1:0] sfp_out;
reg [2:0] sram_sel_fifo;
reg [2:0] sram_sel_output;
reg Relu_en;

integer x_file, x_scan_file ; // file_handler
integer w_file, w_scan_file ; // file_handler
integer acc_file, acc_scan_file ; // file_handler
integer out_file, out_scan_file ; // file_handler
integer captured_data; 
integer t, i, j, k, kij,l,onij;
integer error;

assign inst_q[36] = CEN_wmem_q;
assign inst_q[37] = WEN_wmem_q;
assign inst_q[48:38] = A_wmem_q;
assign inst_q[34] = mode_q;
assign inst_q[35] = flush_q;
assign inst_q[33] = acc_q;
assign inst_q[32] = CEN_pmem_q;
assign inst_q[31] = WEN_pmem_q;
assign inst_q[30:20] = A_pmem_q;
assign inst_q[19]   = CEN_xmem_q;
assign inst_q[18]   = WEN_xmem_q;
assign inst_q[17:7] = A_xmem_q;
assign inst_q[6]   = ofifo_rd_q;
assign inst_q[5]   = ififo_wr_q;
assign inst_q[4]   = ififo_rd_q;
assign inst_q[3]   = l0_rd_q;
assign inst_q[2]   = l0_wr_q;
assign inst_q[1]   = execute_q; 
assign inst_q[0]   = load_q;
assign Relu_en_c   = Relu_en_q;

 integer index;

    //==============================
    // Task: get SFP flattened memory index
    //==============================
    task get_sfp_index;
        input integer out_row;      // output pixel row (0..31)
        input integer out_col;      // output pixel column (0..31)
        input integer kernel_num;   // kernel index (0..8)
        input integer padded_width; // 34
        input integer step;         // 1157
        output integer flat_idx;    // resulting memory index
    begin
        // Compute base index for this output pixel
        flat_idx = out_row * padded_width + out_col + kernel_num * step;
    end
    endtask



core  #(.bw(bw), .col(col), .row(row)) core_instance (
	.clk(clk), 
	.inst(inst_q),
	.ofifo_valid(ofifo_valid),
        .D_xmem(D_xmem_q), 
        .sfp_out(sfp_out),
        .Relu_en (Relu_en_c),	
	.reset(reset),.mode(mode_q),.flush(flush_q),.D_wmem(D_wmem_q)); 


initial begin 

  inst_w   = 0; 
  D_xmem   = 0;
  D_wmem   = 0;
  CEN_pmem = 1; //added
  WEN_pmem = 1;
  CEN_pmem_out = 1;
  WEN_pmem_out = 1;
  A_pmem   = 0;
  A_pmem_out   = 0;
  CEN_xmem = 1;
  CEN_wmem = 1;
  WEN_xmem = 1;
  WEN_wmem = 1;
  A_xmem   = 0;
  A_wmem   = 0;
  ofifo_rd = 0;
  ififo_wr = 0;
  ififo_rd = 0;
  l0_rd    = 0;
  l0_wr    = 0;
  execute  = 0;
  load     = 0;
  sram_sel_output = 0; //added
  sram_sel_fifo = 0; //added
  Relu_en = 0; //added

  $dumpfile("core_tb.vcd");
  $dumpvars(0,core_tb);

  x_file = $fopen("../datafiles/act_t.txt", "r");
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
  /////////////////////////

  /////// Activation data writing to memory ///////
  for (t=0; t<len_nij; t=t+1) begin  
    #0.5 clk = 1'b0;  x_scan_file = $fscanf(x_file,"%32b", D_xmem); WEN_xmem = 0; CEN_xmem = 0; if (t>0) A_xmem = A_xmem + 1;
    #0.5 clk = 1'b1;   
  end

  #0.5 clk = 1'b0;  WEN_xmem = 1;  CEN_xmem = 1; A_xmem = 0;
  #0.5 clk = 1'b1; 

  $fclose(x_file);
  /////////////////////////////////////////////////


  for (kij=0; kij<9; kij=kij+1) begin  // kij loop

    case(kij)
     0: w_file_name = "../datafiles/weight_kij0.txt";
     1: w_file_name = "../datafiles/weight_kij1.txt";
     2: w_file_name = "../datafiles/weight_kij2.txt";
     3: w_file_name = "../datafiles/weight_kij3.txt";
     4: w_file_name = "../datafiles/weight_kij4.txt";
     5: w_file_name = "../datafiles/weight_kij5.txt";
     6: w_file_name = "../datafiles/weight_kij6.txt";
     7: w_file_name = "../datafiles/weight_kij7.txt";
     8: w_file_name = "../datafiles/weight_kij8.txt";
    endcase
    

    w_file = $fopen(w_file_name, "r");
    // Following three lines are to remove the first three comment lines of the file
    w_scan_file = $fscanf(w_file,"%s", captured_data);
    w_scan_file = $fscanf(w_file,"%s", captured_data);
    w_scan_file = $fscanf(w_file,"%s", captured_data);

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





    /////// Kernel data writing to memory ///////

    A_wmem = 11'b00000000000;

    for (t=0; t<col; t=t+1) begin  
      #0.5 clk = 1'b0;  w_scan_file = $fscanf(w_file,"%32b", D_wmem); WEN_wmem = 0; CEN_wmem = 0; if (t>0) A_wmem = A_wmem + 1; 
      #0.5 clk = 1'b1;  
    end

    #0.5 clk = 1'b0;  WEN_wmem = 1;  CEN_wmem = 1; A_wmem = 0;
    #0.5 clk = 1'b1; 
    /////////////////////////////////////
    for (i=0; i<10 ; i=i+1) begin
      #0.5 clk = 1'b0;
      #0.5 clk = 1'b1;  
    end



    /////// Kernel data writing to i0 ///////
          
    A_wmem = 11'b00000000000;

    #0.5 clk = 1'b0; WEN_wmem = 1; CEN_wmem = 0; 
    #0.5 clk = 1'b1;


    
    for (j=0 ; j<col ; j++) begin
	    #0.5 clk = 1'b0; ififo_wr = 1'b1; A_wmem = A_wmem + 1;
	    #0.5 clk = 1'b1;
             
    end
    /////////////////////////////////////

    
    #0.5 clk = 1'b0;  WEN_wmem = 1;  CEN_wmem = 1; A_wmem = 0; ififo_wr = 1'b0;
    #0.5 clk = 1'b1; //wr

    for (i=0; i<20 ; i=i+1) begin
      #0.5 clk = 1'b0;
      #0.5 clk = 1'b1;  
    end  // time for writing to L0 FIFO properly
 
  
    /////// Kernel loading to PEs ///////
    for( l=0; l<col ; l++) begin
	    #0.5 clk = 1'b0; ififo_rd = 1'b1; load = 1'b1;
	    #0.5 clk = 1'b1;
    end
    
    /////////////////////////////////////

   // for (i=0; i<3 ; i=i+1) begin
   //   #0.5 clk = 1'b0;
   //   #0.5 clk = 1'b1;  
   // end

   // #0.5 clk = 1'b0;  load = 0; l0_rd = 0;
   // #0.5 clk = 1'b1;  
 


    ////// provide some intermission to clear up the kernel loading ///
   
    for (i=0; i<20 ; i=i+1) begin
      #0.5 clk = 1'b0;
      #0.5 clk = 1'b1; 
         end
    /////////////////////////////////////
     #0.5 clk = 1'b0;  load = 0; ififo_rd = 0;
    #0.5 clk = 1'b1; 

    for (i=0; i<20 ; i=i+1) begin
      #0.5 clk = 1'b0;
      #0.5 clk = 1'b1; 
         end



 
   
    /////// Activation data writing to L0 ///////
      A_xmem = 11'b00000000000;

    fork
      begin
	  #0.5 clk = 1'b0 ; WEN_xmem = 1; CEN_xmem = 0;
          #0.5 clk = 1'b1 ;


         for (j=0 ; j<len_nij ; j++) begin
	    #0.5 clk = 1'b0; WEN_xmem = 1; CEN_xmem = 0; l0_wr = 1'b1; if(j>0) A_xmem = A_xmem + 1;
	    #0.5 clk = 1'b1;
         end

	 

      end
    /////////////////////////////////////

    /////// Execution ///////
      begin
           for (i=0; i<30 ; i=i+1) begin
             #0.5 clk = 1'b0;
             #0.5 clk = 1'b1;  
          end

          // reading the activation data from LO to mac 
          for( l=0; l<col ; l++) begin
	    #0.5 clk = 1'b0; l0_rd = 1'b1; execute = 1'b1;
	    #0.5 clk = 1'b1;
          end
      end

           

    
    /////////////////////////////////////

    //////// OFIFO READ ////////
    // Ideally, OFIFO should be read while execution, but we have enough ofifo
    // depth so we can fetch out after execution.
      begin
           for (i=0; i<70 ; i=i+1) begin
             #0.5 clk = 1'b0;
             #0.5 clk = 1'b1;  
           end

	   #0.5 clk = 1'b0; ofifo_rd = 1'b1;
	    #0.5 clk = 1'b1;

	    #0.5 clk = 1'b0;
	    #0.5 clk = 1'b1; 

	    #0.5 clk = 1'b0;
	    #0.5 clk = 1'b1;
 

            for( l=0; l<len_nij ; l++) begin
	    #0.5 clk = 1'b0;  WEN_pmem = 0; CEN_pmem = 0;  if(l>0 || kij >0) A_pmem = A_pmem + 1;
	    #0.5 clk = 1'b1; 
              
           end

            #0.5 clk = 1'b0;  WEN_pmem = 1; CEN_pmem = 1;  ofifo_rd = 1'b0;
	    #0.5 clk = 1'b1; 

         
      end
   join 

    #0.5 clk = 1'b0; WEN_pmem = 1; CEN_pmem = 1; ofifo_rd = 1'b0; l0_rd = 1'b0; execute = 1'b0;l0_wr = 0; A_xmem = 0;
    #0.5 clk = 1'b1; 


    
    /////////////////////////////////////


  end  // end of kij loop


  #0.5 clk = 1'b0; A_pmem = 11'b0;
  #0.5 clk = 1'b1;



  #0.5 clk = 1'b0; WEN_pmem = 1; CEN_pmem = 1;  A_pmem = 0; A_pmem_out = 0;
  #0.5 clk = 1'b1;


  ////////// Accumulation /////////
  out_file = $fopen("../datafiles/relu.txt", "r"); 
  acc_file = $fopen("../datafiles/acc_final.txt","r"); 

  // Following three lines are to remove the first three comment lines of the file
  out_scan_file = $fscanf(out_file,"%s", answer); 
  out_scan_file = $fscanf(out_file,"%s", answer); 
  out_scan_file = $fscanf(out_file,"%s", answer); 

  error = 0;



  $display("############ Verification Start during accumulation #############"); 

  for (i=0; i<len_onij+1; i=i+1) begin 

    #0.5 clk = 1'b0; 
    #0.5 clk = 1'b1; 

    if (i>0) begin
     out_scan_file = $fscanf(out_file,"%128b", answer); // reading from out file to answer
       if (sfp_out == answer)
         $display("%2d-th output featuremap Data matched! :D", i); 
       else begin
         $display("%2d-th output featuremap Data ERROR!!", i); 
         $display("sfpout: %128b", sfp_out);
         $display("answer: %128b", answer);
         error = 1;
       end
    end
   
 
    #0.5 clk = 1'b0; reset = 1;
    #0.5 clk = 1'b1;  
    #0.5 clk = 1'b0; reset = 0; 
    #0.5 clk = 1'b1;  

    for (j=0; j<len_kij+1; j=j+1) begin 

      #0.5 clk = 1'b0;   
        if (j<len_kij) begin CEN_pmem = 0; WEN_pmem = 1; acc_scan_file = $fscanf(acc_file,"%11b", A_pmem); end
                       else  begin CEN_pmem = 1; WEN_pmem = 1; end

        if (j>0)  acc = 1; 	
      #0.5 clk = 1'b1;   
    end
    #0.5 clk = 1'b0; acc = 1; Relu_en = 1;
    #0.5 clk = 1'b1 ;

    #0.5 clk = 1'b0; 
    #0.5 clk = 1'b1 ;
     

    #0.5 clk = 1'b0; acc = 0; Relu_en = 0;
    #0.5 clk = 1'b1; 
  end


  if (error == 0) begin
  	$display("############ No error detected ##############"); 
  	$display("########### Project Completed !! ############"); 

  end

  $fclose(acc_file);
  //////////////////////////////////

  for (t=0; t<10; t=t+1) begin  
    #0.5 clk = 1'b0;  
    #0.5 clk = 1'b1;  
  end

  #10 $finish;

end

always @ (posedge clk) begin
   inst_w_q   <= inst_w; 
   D_xmem_q   <= D_xmem;
   D_wmem_q   <= D_wmem;
   CEN_xmem_q <= CEN_xmem;
   WEN_xmem_q <= WEN_xmem;
   A_pmem_q   <= A_pmem;
   A_wmem_q   <= A_wmem;
   CEN_pmem_q <= CEN_pmem;
   CEN_wmem_q <= CEN_wmem;
   WEN_pmem_q <= WEN_pmem;
   WEN_wmem_q <= WEN_wmem;
   A_xmem_q   <= A_xmem;
   ofifo_rd_q <= ofifo_rd;
   acc_q      <= acc;
   ififo_wr_q <= ififo_wr;
   ififo_rd_q <= ififo_rd;
   l0_rd_q    <= l0_rd;
   l0_wr_q    <= l0_wr ;
   execute_q  <= execute;
   load_q     <= load;
   Relu_en_q  <= Relu_en;
   CEN_pmem_out_q <= CEN_pmem_out;
   WEN_pmem_out_q <= WEN_pmem_out;
   A_pmem_out_q <= A_pmem_out;
   mode_q <= mode;
   flush_q <= flush;
end


endmodule




