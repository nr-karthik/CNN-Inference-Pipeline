module core #(
    parameter bw        = 4,    // weight bitwidth
    parameter psum_bw   = 32,   // psum bitwidth
    parameter row       = 8,    // number of MAC rows
    parameter col       = 8,     // number of MAC cols
    parameter len_nij   = 16
)
(
    input                      clk,
    input                      reset,
    input [6:0]                inst, //inst[4] is final read from mem
    //rchip is inst[5]


    input  wen_act_wgt,
    input  cen_act_wgt,
    input  [31:0] din_act_wgt,
    input  [10:0] addr_act_wgt,
    output [psum_bw*col-1:0] final_psum_vector

);


wire [bw*row-1:0] qread_act;
wire [psum_bw*col-1:0] psum_to_sfu;


//reg [psum_bw*col-1:0] psum_to_sfu_q;   // already used but not declared?

sram_32b #(.num(2000)) sram_acts_wgts (
    .CLK(clk),
    .WEN(wen_act_wgt),
    .CEN(cen_act_wgt),     
    .D(din_act_wgt), 
    .A(addr_act_wgt),       
    .Q(qread_act)    //connect
  );

// control for psum memories
// changed here
reg      cen_out_mem1, cen_out_mem2;
reg     wen_out_mem1, wen_out_mem2;
reg [10:0] out_addr_mem1, out_addr_mem2;
// SFU outputs from corelet
wire [psum_bw*col-1:0] sfu_out_flat;

// =======================================================
//  Generate 8 psum SRAMs for MEM1 and MEM2
//  Each stores 32 bits from sfu_out_flat
// =======================================================

genvar oc;
generate
    for (oc = 0; oc < 8; oc = oc + 1) begin : gen_psum_srams

        // -------------------------------
        // MEM1 SRAMs (rchip = 1 output bank)
        // -------------------------------
        sram_32b #(.num(32)) sram_psum_mem1 (
            .CLK(clk),
            .D( sfu_out_flat[(32*oc + 31) : (32*oc)] ),
            .Q( psum_stored_mem1[oc] ),     // <-- use an array for cleaner code
            .CEN( cen_out_mem1 ),
            .WEN( wen_out_mem1 ),
            .A( out_addr_mem1 )
        );

        // -------------------------------
        // MEM2 SRAMs (rchip = 0 output bank)
        // -------------------------------
        sram_32b #(.num(32)) sram_psum_mem2 (
            .CLK(clk),
            .D( sfu_out_flat[(32*oc + 31) : (32*oc)] ),
            .Q( psum_stored_mem2[oc] ),     // <-- use an array for cleaner code
            .CEN( cen_out_mem2 ),
            .WEN( wen_out_mem2 ),
            .A( out_addr_mem2 )
        );

    end
endgenerate

// Concatenate read psums from each chip
wire [31:0] psum_stored_mem1 [0:7];
wire [31:0] psum_stored_mem2 [0:7];
wire [255:0] psum_to_sfu_mem1;
wire [255:0] psum_to_sfu_mem2;

assign psum_to_sfu_mem1 = {
    psum_stored_mem1[7],
    psum_stored_mem1[6],
    psum_stored_mem1[5],
    psum_stored_mem1[4],
    psum_stored_mem1[3],
    psum_stored_mem1[2],
    psum_stored_mem1[1],
    psum_stored_mem1[0]
};

assign psum_to_sfu_mem2 = {
    psum_stored_mem2[7],
    psum_stored_mem2[6],
    psum_stored_mem2[5],
    psum_stored_mem2[4],
    psum_stored_mem2[3],
    psum_stored_mem2[2],
    psum_stored_mem2[1],
    psum_stored_mem2[0]
};

// mem select
wire  rchip;  // 0 -> read mem1 / write mem2, 1 -> read mem2 / write mem1
assign rchip = inst[5];

assign psum_to_sfu = rchip ? psum_to_sfu_mem2 : psum_to_sfu_mem1;

wire o_ready_l0;
wire wr_mem;       // from corelet: write-enable for psum SRAM phase
wire rd_ofifo;     // from corelet: OFIFO read → psum read phase
wire wr_ofifo;


corelet #(
    .bw(bw),
    .psum_bw(psum_bw),
    .row(row),
    .col(col)
) CORELET_inst (
    .clk           (clk),
    .reset         (reset),
    .inst          (inst[3:0]),
    .D_xmem        (qread_act),
    .mem_read_psum (psum_to_sfu),
    .sfu_out_flat  (sfu_out_flat),
    .o_ready_l0    (o_ready_l0),
    .wr_mem        (wr_ofifo),
    .rd_ofifo      (rd_ofifo)
);



reg [10:0] rd_ptr, wr_ptr;
wire [10:0] max_rptr;
wire [10:0] max_wptr;
wire rd_mem;

assign max_rptr = len_nij;
assign max_wptr = len_nij;

assign rd_mem = (inst[4] == 1'b1) ? (rd_ptr < max_rptr) : rd_ofifo;
assign wr_mem = (inst[6] == 1'b1) ? (wr_ptr < max_wptr) : wr_ofifo;



always @* begin
    if (!rchip) begin
        // read mem1, write mem2
        out_addr_mem1 = rd_ptr;
        out_addr_mem2 = wr_ptr;
    end else begin
         // read mem2, write mem1
        out_addr_mem1 = wr_ptr;
        out_addr_mem2 = rd_ptr;
    end
 end

// CEN/WEN control for psum SRAMs
always @* begin
    // defaults: disabled
    cen_out_mem1 = 1'b1;
    wen_out_mem1 = 1'b1;
    cen_out_mem2 = 1'b1;
    wen_out_mem2 = 1'b1;

    if (!rchip) begin
        // rchip = 0: read mem1, write mem2
        if (rd_mem) begin
            cen_out_mem1 = 1'b0; // active
            wen_out_mem1 = 1'b1; // read
        end
        if (wr_mem) begin
            cen_out_mem2 = 1'b0; // active
            wen_out_mem2 = 1'b0; // write
        end
        end else begin
            // rchip = 1: read mem2, write mem1
            if (rd_mem) begin
                cen_out_mem2 = 1'b0;
                wen_out_mem2 = 1'b1; // read
            end
            if (wr_mem) begin
                cen_out_mem1 = 1'b0;
                wen_out_mem1 = 1'b0; // write
            end
        end
end


always @(posedge clk) begin
    if (reset) begin
        rd_ptr <= 0;
        wr_ptr <= 0;
    end

    else begin

        // ---------------------------
        // NORMAL ACCUMULATION MODE inst[4] = 0
        // ---------------------------
        if (!inst[4]) begin      
            if (rd_mem && (rd_ptr < max_rptr)) begin
                rd_ptr <= rd_ptr + 1;
            end
        end
        else begin      //output dump mode           
            if (rd_mem && (rd_ptr < max_rptr)) begin
                rd_ptr <= rd_ptr + 1;           
            end
        end

        if (wr_mem && (wr_ptr < max_wptr)) begin
            wr_ptr <= wr_ptr + 1;
        end
    end
end




assign final_psum_vector = rchip ? psum_to_sfu_mem1 : psum_to_sfu_mem2;

endmodule
