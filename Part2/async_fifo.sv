module async_fifo #(
    parameter DSIZE = 8, // data width
    parameter ASIZE = 4 // address width
) (
    output  logic [DSIZE-1:0] rdata, 
    output  logic wfull, // in the write clock domain
    output  logic rempty, // in the read clock domain
    output  logic almost_full, // in the write clock domain
    output  logic almost_empty, // in the read clock domain
    input   logic [DSIZE-1:0] wdata,
    input   logic winc, wclk, wrst_n, 
    input   logic rinc, rclk, rrst_n
);
    logic [ASIZE-1:0] wptr, rptr; // gray pointers
    logic [ASIZE-1:0] rptr_afset, rptr_afclr; // pointers for the almost thresholds
    logic [ASIZE-1:0] wptr_aeset, wptr_aeclr;
    logic aempty_n, afull_n;
    logic aalmost_empty_n, aalmost_full_n;

    fifo_mem_if #(DSIZE, ASIZE) mem_if (.*);

    fifo_mem #(DSIZE, ASIZE) fifomem (.*);

    assign mem_if.waddr = wptr;
    assign mem_if.raddr = rptr;
    assign mem_if.wdata = wdata;
    assign mem_if.wclken = winc;
    assign mem_if.wfull = wfull;
    assign rdata = mem_if.rdata;

    async_cmp #(ASIZE) async_cmp (.*);

    rptr_empty #(ASIZE) rptr_empty (.*, .ralmost_empty(almost_empty));

    wptr_full #(ASIZE) wptr_full (.*, .walmost_full(almost_full)); 

endmodule