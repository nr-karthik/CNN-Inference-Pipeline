// Created by prof. Mingu Kang @VVIP Lab in UCSD ECE department
// Please do not spread this code without permission 
module accumulator_sfu (clk,reset, psum_stored_q,out, Relu_en,acc_q);

parameter psum_bw = 16;

input clk;
input reset;
//input signed [psum_bw-1:0] oc_nij;
input signed  [psum_bw-1:0] psum_stored_q; 
input acc_q;
output signed [psum_bw-1 :0] out ;
input Relu_en;
reg [psum_bw -1 :0] sum_q;



assign out = sum_q;

always@(posedge clk)
begin
    if(reset)
    sum_q <= 0;
    else
	    if(!Relu_en)
	    begin
		    if(acc_q)
		    sum_q <= psum_stored_q + sum_q;
	            else 
	            sum_q <= 0;
	    end
	    else
	    begin
		    if(sum_q[psum_bw-1] == 1'b1)
			    sum_q <= 0;
		    else
			    sum_q <= sum_q;
	    end

end



endmodule
