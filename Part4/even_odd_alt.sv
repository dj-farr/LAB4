module even_odd_alt #(
    parameter DSIZE = 8, // data width
    parameter ASIZE = 4 // address width
) (
    input  logic  clk, rst, w_en, r_en,
    input  logic  [DSIZE-1:0] din,
    output logic  [DSIZE-1:0] dout
);
    logic [DSIZE-1:0] e_rdata, o_rdata;
    logic e_winc, o_winc;
    logic e_rinc, o_rinc;
    logic e_empty, o_empty;
    logic e_full, o_full;

    // flag
    typedef enum logic [1:0] {
		INIT,
		ODD,
		EVEN
    } next_t;

    next_t next;

    // toggle winc for either fifos if there data in din and its first bit
    // location
    always_comb begin
		e_winc = 1'b0;
		o_winc = 1'b0;

		if (w_en) begin
		// the first bit tell use if the current number is even or odd
			if (din[0] == 1'b0 && !e_full)
				e_winc = 1'b1;
			else if (din[0] == 1'b1 && !o_full)
				o_winc = 1'b1;
		end
    end
    
    // toggle rinc for either fifos depending the incoming number 
    // value in appropriate fifo
    always_comb begin
		e_rinc = 1'b0;
		o_rinc = 1'b0;

		if (r_en) begin
			if (next == EVEN && !e_empty)
				e_rinc = 1'b1;
			else if (next == ODD && !o_empty)
				o_rinc = 1'b1;
		end
    end

    always_ff @(posedge clk or posedge rst) begin
		if(rst) begin
			next <= INIT;
			dout <= '0;
		end
		else begin
			case (next)
				INIT: begin
					// if first write is enabled, we start with even
					// otherwise odd
					if(w_en) begin
						if (e_winc)
							next <= EVEN;
						else if (o_winc)
							next <= ODD;
						end
				end
				// alternating even and odd after each and set dout or din
				EVEN: begin
					if (e_rinc) begin 
						dout <= e_rdata;
						next <= ODD;
					end
				end
				ODD:  begin
					if (o_rinc) begin 
						dout <= o_rdata;
						next <= EVEN;
					end
				end
			endcase
        end
    end

    // even fifo
    async_fifo #(
	    .DSIZE(DSIZE),
	    .ASIZE(ASIZE)
    ) even_fifo (
		.rdata(e_rdata),
		.wdata(din),
		.rclk(clk),
		.wclk(clk),
		.winc(e_winc),
		.rinc(e_rinc),
		.wrst_n(~rst),
		.rrst_n(~rst),
		.wfull(e_full),
		.rempty(e_empty),
		.almost_full(),
		.almost_empty()
    );

    // odd fifo
    async_fifo #(
	    .DSIZE(DSIZE),
	    .ASIZE(ASIZE)
    ) odd_fifo (
		.rdata(o_rdata),
		.wdata(din),
		.rclk(clk),
		.wclk(clk),
		.winc(o_winc),
		.rinc(o_rinc),
		.wrst_n(~rst),
		.rrst_n(~rst),
		.wfull(o_full),
		.rempty(o_empty),
		.almost_full(),
		.almost_empty()
    );
endmodule