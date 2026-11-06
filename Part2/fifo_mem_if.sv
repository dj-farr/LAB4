interface fifo_mem_if #(
	parameter int DSIZE = 8,
	parameter int ASIZE = 4
) (
	input logic wclk
); 
   logic [DSIZE-1:0] rdata, wdata;
   logic [ASIZE-1:0] raddr, waddr;
   logic 	     wclken, wfull;

   modport wr  (output waddr, wdata, wfull, wclken);
   modport rd  (output raddr, input rdata);
   modport mem (output rdata, input wdata, waddr, raddr, wclken, wfull, wclk);

endinterface
