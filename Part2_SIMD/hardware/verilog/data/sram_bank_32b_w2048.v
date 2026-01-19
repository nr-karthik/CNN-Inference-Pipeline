// wrapper for sram bank

module sram_bank_32b_w2048 (
    CLK, D, Q, CEN, WEN, A
);

input  CLK;
input  WEN;
input  CEN;
input  [psum_bw*col-1:0] D;
input  [10:0] A;
output [psum_bw*col-1:0] Q;
parameter num = 64; // 2048
parameter col = 8;
parameter psum_bw = 32;

genvar i;
for (i=0; i < col; i=i+1) begin : col_num
	sram_32b_w2048 #(.num(num), .psum_bw(psum_bw)) sram_instance (
        .CLK(CLK),
        .WEN(WEN),
        .CEN(CEN),
        .D(D[psum_bw*(i+1)-1:psum_bw*i]),
        .A(A),
        .Q(Q[psum_bw*(i+1)-1:psum_bw*i])
    );
end
endmodule