module fifo_mem #(
	parameter int DSIZE = 8,
	parameter int ASIZE = 4
) (
	fifo_mem_if.mem mem_if
);
   `ifdef VENDORRAM
	vendor_ram mem (
		.dout(mem_if.rdata),
		.din(mem_if.wdata),
		.waddr(mem_if.waddr),
		.raddr(mem_if.raddr),
		.wclken(mem_if.wclken),
		.wclken_n(mem_if.wfull),
		.clk(mem_if.wclk)
	);
   `else
	localparam DEPTH = 1<<ASIZE; // depth = 2^(address width)
	logic [DSIZE-1:0] mem [DEPTH]; // DEPTH elements each of DSIZE bits

	// synch write to wclk, iff when requested and not full
	always_ff @(posedge mem_if.wclk)
	    if(mem_if.wclken && !mem_if.wfull)
		mem[mem_if.waddr] <= mem_if.wdata;
	// a combinational read
	assign mem_if.rdata = mem[mem_if.raddr];
   `endif
   endmodule 
