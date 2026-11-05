
`timescale 1ns/1ps

module async_fifo_checker #(
    parameter DSIZE = 8,
    parameter ASIZE = 4
)(
    input logic [DSIZE-1:0] wdata,
    input logic [DSIZE-1:0] rdata,
    input logic winc, wclk, wrst_n, wfull,
    input logic rinc, rclk, rrst_n, rempty
);

    import "DPI-C" function void fifo_init();
    import "DPI-C" function int push(input int data);
    import "DPI-C" function int pop();
    import "DPI-C" function int is_empty();
    import "DPI-C" function int is_full();

    int expected_data;
    int errors = 0;

    // Reset the golden model
    always @(negedge wrst_n) begin
        fifo_init();
    end

    // Check accepted writes
    always @(posedge wclk) begin
        if (wrst_n && winc && !wfull) begin
            if (!push(int'(wdata))) begin
                $error("Golden model rejected an accepted write");
                errors++;
            end
        end
    end

    // Check accepted reads
    always @(posedge rclk) begin
        if (rrst_n && rinc && !rempty) begin
            expected_data = pop();

            if (expected_data < 0) begin
                $error("Golden model underflow");
                errors++;
            end
            else if (rdata !== DSIZE'(expected_data)) begin
                $error("FIFO mismatch at %0t: DUT=%0d, expected=%0d",
                       $time, rdata, expected_data);
                errors++;
            end
        end
    end
    // Check empty flag
    // Updates occurs at the rising edge, so we check at the falling edge.
    // rempty and takes 2 clock cycles to go low, so we only check when
    // the golden model is empty and rempty should be high.
    always @(negedge rclk) begin
        if (rrst_n && wrst_n) begin
            if (is_empty() && !rempty) begin
                $error("EMPTY FLAG ERROR: Golden model is empty, but rempty = 0");
                errors++;
            end
        end
    end

    // Check full flag
    // wfull takes 2 wclk cycles to go low, so we only check when
    // the golden model is full and wfull should be high.
    always @(negedge wclk) begin
        if (wrst_n && rrst_n) begin
            if (is_full() && !wfull) begin
                $error("FULL FLAG ERROR: Golden model is full, but wfull = 0");
                errors++;
            end
        end
    end
endmodule

