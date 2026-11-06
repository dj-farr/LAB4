module sych_r2w #(
	parameter ASIZE = 4
) (
	output logic [ASIZE:0] wq2_rpt;
	input  logic [ASIZE:0] rptr;
	input  logic 	       wclk, wrst_n;
);
	always_ff @(posedge wclk or negedge wrst_n)
		if 	(!wrst_n) {wq2_rptr, wq1_rptr} <= 0;
		else 		  {wq2_rptr, wq1_rptr} <= {wq1_rptr, rtpr};
endmodule
