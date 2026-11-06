interface fifo_if #(
    parameter DSIZE = 8
);
    logic [DSIZE-1:0] wdata, rdata;

    logic winc, wclk, wrst_n;
    logic rinc, rclk, rrst_n;

    logic wfull, rempty;

    logic almost_full, almost_empty;

    // writer
    modport producer (
	input wdata,
	input winc,
	input wclk,
	input wrst_n,
	input rinc,
	input rclk,
	input rrst_n,

	output rdata,
	output wfull,
	output rempty,
	output almost_full,
	output almost_empty,
    );
    // reader
    modport consumer (
	output wdata,
	output winc,
	output wclk,
	output wrst_n,
	output rinc,
	output rclk,
	output rrst_n,

	input rdata,
	input wfull,
	input rempty,
	input almost_full,
	input almost_empty,
    );
