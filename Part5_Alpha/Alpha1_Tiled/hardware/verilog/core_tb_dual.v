// Created by prof. Mingu Kang @VVIP Lab in UCSD ECE department
// Please do not spread this code without permission 
`timescale 1ns/1ps

module core_tb_dual;

parameter bw = 4;
parameter psum_bw = 16;
parameter len_kij = 9;
parameter len_onij = 16;
parameter col = 8;
parameter row = 8;
parameter len_nij = 36; 
parameter nij_sz = 6;
parameter onij_sz = 4;
parameter htiles = 2;

reg clk = 0;
reg reset = 1;

wire [33:0] inst_q; 

reg [1:0]  inst_w_q = 0; 
reg [bw*row-1:0] D_xmem_q = 0;
reg CEN_xmem = 1;
reg WEN_xmem = 1;
reg [10:0] A_xmem = 0;
reg CEN_xmem_q = 1;
reg WEN_xmem_q = 1;
reg [10:0] A_xmem_q = 0;
reg CEN_pmem = 1;
reg WEN_pmem = 1;
reg [10:0] A_pmem = 0;
reg CEN_pmem_q = 1;
reg WEN_pmem_q = 1;
reg [10:0] A_pmem_q = 0;
reg ofifo_rd_q = 0;
reg ififo_wr_q = 0;
reg ififo_rd_q = 0;
reg l0_rd_q = 0;
reg l0_wr_q = 0;
reg execute_q = 0;
reg load_q = 0;
reg acc_q = 0;
reg acc = 0;
reg mode;
reg mode_q = 0;
reg sel = 0;
reg sel_q = 0;
reg [1:0] tile;
reg [1:0] tile_q;

reg [1:0]  inst_w; 
reg [bw*row-1:0] D_xmem;
reg [psum_bw*col-1:0] answer;

reg relu;
reg relu_q;


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

integer x_file, x_scan_file ; // file_handler
integer w_file, w_scan_file ; // file_handler
integer acc_file, acc_scan_file ; // file_handler
integer out_file, out_scan_file ; // file_handler
integer captured_data; 
integer t, i, j, k, kij;
integer error;

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

reg [col-1:0][psum_bw-1:0] sfp_out_q; // just for testing
reg ofifo_valid_q;

function integer calc_index;
	input integer a;
	begin
		calc_index = (a/onij_sz)*nij_sz + a%onij_sz;
	end
endfunction

dual_core  #(.col(col), .row(row), .psum_bw(psum_bw)) core_instance (
	.clk(clk), 
	.inst(inst_q),
	.ofifo_valid(ofifo_valid),
	.D_xmem(D_xmem_q), 
	.sfp_out(sfp_out), 
	.mode(mode_q),
	.reset(reset),
	.sel(sel_q),
	.tile(tile_q),
	.relu(relu)); 


initial begin 

	inst_w   = 0; 
	D_xmem   = 0;
	CEN_xmem = 1;
	WEN_xmem = 1;
	A_xmem   = 0;
	ofifo_rd = 0;
	ififo_wr = 0;
	ififo_rd = 0;
	l0_rd    = 0;
	l0_wr    = 0;
	execute  = 0;
	load     = 0;
	mode	 = 0;
	acc 	 = 0;
	tile = 2'b01;
	relu = 0;

	$dumpfile("core_tb_dual.vcd");
	$dumpvars(0,core_tb_dual);

	x_file = $fopen("../datafiles/act_tile0.txt", "r");
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
		#0.5 clk = 1'b0;  x_scan_file = $fscanf(x_file,"%32b", D_xmem); 
		WEN_xmem = 0; CEN_xmem = 0; 
		if (t>0) A_xmem = A_xmem + 1;
		#0.5 clk = 1'b1;   
	end

	#0.5 clk = 1'b0;  WEN_xmem = 1;  CEN_xmem = 1; A_xmem = 0;
	#0.5 clk = 1'b1; 

	$fclose(x_file);
	/////////////////////////////////////////////////


	for (kij=0; kij<9; kij=kij+1) begin  // kij loop
		$display(kij);
		case(kij)
			0: w_file_name = "../datafiles/w_i0_o0_kij0.txt";
			1: w_file_name = "../datafiles/w_i0_o0_kij1.txt";
			2: w_file_name = "../datafiles/w_i0_o0_kij2.txt";
			3: w_file_name = "../datafiles/w_i0_o0_kij3.txt";
			4: w_file_name = "../datafiles/w_i0_o0_kij4.txt";
			5: w_file_name = "../datafiles/w_i0_o0_kij5.txt";
			6: w_file_name = "../datafiles/w_i0_o0_kij6.txt";
			7: w_file_name = "../datafiles/w_i0_o0_kij7.txt";
			8: w_file_name = "../datafiles/w_i0_o0_kij8.txt";
		endcase
		

		w_file = $fopen(w_file_name, "r");
		// Following three lines are to remove the first three comment lines of the file
		w_scan_file = $fscanf(w_file,"%s", captured_data);
		w_scan_file = $fscanf(w_file,"%s", captured_data);
		w_scan_file = $fscanf(w_file,"%s", captured_data);

		#0.5 clk = 1'b0;   reset = 1;
		#0.5 clk = 1'b1; 

		/*
		for (i=0; i<10 ; i=i+1) begin
			#0.5 clk = 1'b0;
			#0.5 clk = 1'b1;  
		end
		*/

		#0.5 clk = 1'b0;   reset = 0;
		#0.5 clk = 1'b1; 

		#0.5 clk = 1'b0;   
		#0.5 clk = 1'b1;   

		/////// Kernel data writing to memory ///////
		// must modify for 2b as kernel is twice sized (2col)

		for (j=0; j < htiles; j=j+1) begin
			A_xmem = 11'b10000000000;
			tile = (1'b1 << j);

			for (t=0; t<2*col; t=t+1) begin  
				#0.5 clk = 1'b0;  w_scan_file = $fscanf(w_file,"%32b", D_xmem); 
				WEN_xmem = 0; CEN_xmem = 0; if (t>0) A_xmem = A_xmem + 1; 
				#0.5 clk = 1'b1;  
			end

			#0.5 clk = 1'b0;  WEN_xmem = 1;  CEN_xmem = 1; A_xmem = 0;
			#0.5 clk = 1'b1; 

			/////// Kernel loading to PEs, simultaneous with kernel data writing to L0///////
			// only 8 (#col) number of "loads" need to be sent
			// but it's fine if we send more as they just won't be used.
			// must modify for 2b as kernel is twice sized (2col)
			
			// must start L0 writing at 1 cycle before L0 reading

			A_xmem = 11'b10000000000;
			#0.5 clk = 0;
			l0_wr = 1;
			CEN_xmem = 0;
			#0.5 clk = 1;

			for (t=0; t<row+col*2; t=t+1) begin
				#0.5 clk = 0;

				// only allow kernel data write to L0 for col*2 cycles
				if (t >= 0) A_xmem = A_xmem + 1;
				if (t >= col*2-1) begin
					l0_wr = 0;
					CEN_xmem = 1;
				end

				// kernel loading to PE simultaneous out of L0
				mode = 0;
				if (t >= col*2) begin
					l0_rd = 1;
					load = 0;
				end else begin
					l0_rd = 1;
					load = 1;
				end
				#0.5 clk = 1;
			end


			////// provide some intermission to clear up the kernel loading ///
			#0.5 clk = 1'b0;  load = 0; l0_rd = 0;
			#0.5 clk = 1'b1;  

		end


		/////// Activation data writing to L0 ///////
		A_xmem = 11'b00000000000;
		tile = 2'b11;

		for (t=0; t<len_nij; t=t+1) begin
			#0.5 clk = 0;
			l0_wr = 1;
			CEN_xmem = 0;
			if (t>0) A_xmem = A_xmem + 1;
			#0.5 clk = 1;
		end
		
		// 16 cycles

		#0.5 clk = 1'b0;  
		CEN_xmem = 1; A_xmem = 0;
		l0_wr = 0;
		#0.5 clk = 1'b1; 

		/////////////////////////////////////



		/////// Execution ///////
		// enable operations for nij cycles
		// simultaneously, enable l0_rd for nij+col cycles.
		for (t=0; t<len_nij+col*2; t=t+1) begin
			#0.5 clk = 0;
			if (t < len_nij) 
				execute = 1;		
			else 
				execute = 0;
			l0_rd = 1;
			mode = 0;
			#0.5 clk = 1;
		end

		#0.5 clk = 1'b0;  
		l0_rd = 0;
		mode = 0;
		execute = 0;
		#0.5 clk = 1'b1; 

		// #20;
		/////////////////////////////////////



		//////// OFIFO READ ////////
		// Ideally, OFIFO should be read while execution, but we have enough ofifo
		// depth so we can fetch out after execution.
		


		// must enable ofifo reading ONE cycle early to match timings
		// extra ofifo reads (> len_nij) does not affect process,
		// extra acc reads does not affect process.
		
		#0.5 clk = 0;
		ofifo_rd = 1;
		sel = kij[0];
		if (kij > 0)
			acc = 1;
		if (kij == 8)
			relu = 1;
		

		// we are offsetting A_pmem to align the SFU write to the correct place
		A_pmem = 11'b00000000000 - (kij % 3 + (kij / 3) * nij_sz) ;
		#0.5 clk = 1;


		for (t=0; t<len_nij; t=t+1) begin  
			#0.5 clk = 1'b0; 
			
			WEN_pmem = 0; CEN_pmem = 0; 
			if (t>0) A_pmem = A_pmem + 1; 
			#0.5 clk = 1'b1;  
		end


		#0.5 clk = 1'b0;  
		WEN_pmem = 1;  CEN_pmem = 1; A_pmem = 0; ofifo_rd = 0;
		acc = 0;
		#0.5 clk = 1'b1; 
		
		// needs the minimum 2 cycles before reset
		// or else reset literally destroys everything.
		
		#0.5 clk = 1'b0;  
		#0.5 clk = 1'b1;		
		#0.5 clk = 1'b0;  
		#0.5 clk = 1'b1;

	end  // end of kij loop

	// dump tile0
	tile = 2'b01;

	// after sending signal, we need to wait 4 cycles before we
	// receive it

	for (t=0; t<len_onij+4; t=t+1) begin
		#0.5 clk = 0;
		A_pmem = calc_index(t); //(t/onij_sz)*nij_sz + t%onij_sz;
		

		CEN_pmem = 0;
		$display("psum outputs: %0d %0d", t, calc_index(t-4));
		for (j = 0; j < col; j = j + 1) begin
			$display("out_s[%0d]: %0d", j, $signed(sfp_out_q[j]));
		end
		$display("-----------------------");
		#0.5 clk = 1;
	end

	
	#0.5 clk = 1'b0;  
	#0.5 clk = 1'b1;
	#0.5 clk = 1'b0;  
	#0.5 clk = 1'b1;
	#0.5 clk = 1'b0;  
	#0.5 clk = 1'b1;
	
	// dump tile1
	tile = 2'b10;
	A_pmem = 0;
	
	/*
	#0.5 clk = 1'b0;  
	#0.5 clk = 1'b1;
	#0.5 clk = 1'b0;  
	#0.5 clk = 1'b1;*/
	// +4 useless cycles for it to propagate back to our visual 
	for (t=0; t<len_onij+4; t=t+1) begin
		#0.5 clk = 0;
		A_pmem = calc_index(t);
		

		CEN_pmem = 0;
		$display("psum outputs: %0d %d", t, calc_index (t-4));
		for (j = 0; j < col; j = j + 1) begin
			$display("out_s[%0d]: %0d", j, $signed(sfp_out_q[j]));
		end
		$display("-----------------------");
		#0.5 clk = 1;
	end

	
	#0.5 clk = 1'b0;  
	#0.5 clk = 1'b1;
	#0.5 clk = 1'b0;  
	#0.5 clk = 1'b1;
	#0.5 clk = 1'b0;  
	#0.5 clk = 1'b1;

	
	CEN_pmem = 1;
	out_file = $fopen("../datafiles/out.txt", "r");  

	// Following three lines are to remove the first three comment lines of the file
	out_scan_file = $fscanf(out_file,"%s", answer); 
	out_scan_file = $fscanf(out_file,"%s", answer); 
	out_scan_file = $fscanf(out_file,"%s", answer); 

	error = 0;

	$display("############ Verification Start #############"); 
	A_pmem = 0;

	
	// +4 useless cycles for it to propagate back to our visual 
	// need to alternate loading 
	for (t=0; t<(len_onij*htiles)+4; t=t+1) begin
		#0.5 clk = 0;
		A_pmem = ((t/htiles)/onij_sz)*nij_sz + (t/htiles)%onij_sz;
		tile = (1'b1 << (t%2)); // load LSB tile first (0) then load MSB tile (1)
		// because that's how our data is stored.
		CEN_pmem = 0;
		if (t>=4) begin
			out_scan_file = $fscanf(out_file,"%128b", answer); // reading from out file to answer
			if (sfp_out_q == answer)
				$display("%2d-th output featuremap Data matched! :D idx %0d tile %2b", 
					(t-4)/htiles, calc_index((t-4)/htiles), tile); 
			else begin
				$display("%2d-th output featuremap Data ERROR!! idx %0d tile %2b", (t-4)/htiles, 
					calc_index((t-4)/htiles), tile); 
				$display("sfpout: %128b", sfp_out_q);
				$display("answer: %128b", answer);
				error = 1;
			 end
		$display("-----------------------");
		end
		#0.5 clk = 1;
	end

	
	if (error == 0) begin
		$display("############ No error detected ##############"); 
		$display("########### Project Completed !! ############"); 

	end
	$finish;

end

always @ (posedge clk) begin
	inst_w_q   <= inst_w; 
	D_xmem_q   <= D_xmem;
	CEN_xmem_q <= CEN_xmem;
	WEN_xmem_q <= WEN_xmem;
	A_pmem_q   <= A_pmem;
	CEN_pmem_q <= CEN_pmem;
	WEN_pmem_q <= WEN_pmem;
	A_xmem_q   <= A_xmem;
	ofifo_rd_q <= ofifo_rd;
	acc_q      <= acc;
	ififo_wr_q <= ififo_wr;
	ififo_rd_q <= ififo_rd;
	l0_rd_q    <= l0_rd;
	l0_wr_q    <= l0_wr ;
	execute_q  <= execute;
	load_q     <= load;
	mode_q 	<= mode;
	sfp_out_q <= sfp_out;
	ofifo_valid_q <= ofifo_valid;
	sel_q <= sel;
	tile_q <= tile;
	relu_q <= relu;
end


endmodule