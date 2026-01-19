module l0_all_rows #(
    parameter row = 8,
    parameter bw  = 4
)(
    input clk,
    input wr,
    input rd,
    input reset,
    input  [row*bw-1:0] in,
    output [row*bw-1:0] out,
    output o_full,
    output o_ready
);

    wire [row-1:0] empty;
    wire [row-1:0] full;
    reg  [row-1:0] rd_en;

    // Ready = all FIFOs not full
    assign o_ready = ~(|full);
    assign o_full  =  |full;

    genvar i;
    generate
        for (i = 0; i < row; i = i + 1) begin : fifo_rows
            fifo_depth64 #(.bw(bw)) fifo_inst (
                .rd_clk(clk),
                .wr_clk(clk),
                .rd(rd_en[i]),
                .wr(wr),
                .o_empty(empty[i]),
                .o_full(full[i]),
                .in(in[(i+1)*bw-1 : i*bw]),
                .out(out[(i+1)*bw-1 : i*bw]),
                .reset(reset)
            );
        end
    endgenerate


    // VERSION-1 LOGIC
    always @(posedge clk) begin
        if (reset) begin
            rd_en <= 0;
        end else if (rd) begin
            // READ ALL NON-EMPTY ROWS IN PARALLEL
            for (int k = 0; k < row; k++)
                rd_en[k] <= !empty[k];
        end else begin
            rd_en <= 0;
        end
    end

endmodule
