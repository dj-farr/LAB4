
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

    // track each time golden becomes empty or full
    // to avoid counting old delay after a brief transition
    int empty_event = 0;
    int full_event = 0;
    int seen_empty_event = 0;
    int seen_full_event = 0;
    int empty_wait = 0;
    int full_wait = 0;
    bit empty_reported = 0;
    bit full_reported = 0;

    // Reset the golden model
    always @(negedge wrst_n) begin
        fifo_init();
        empty_event = 0;
        full_event = 0;
    end

    // Check accepted writes
    always @(posedge wclk) begin
        if (wrst_n && winc && !wfull) begin
            if (!push(int'(wdata))) begin
                $error("Golden model rejected an accepted write");
                errors++;
            end
            else if (is_full()) begin
                full_event++;
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
            if (is_empty())
                empty_event++;
        end
    end
    // Check that rempty is high when the golden model is empty.
    // Check at the falling edge to let the signals update.
    always @(negedge rclk) begin
        if (!rrst_n && !wrst_n) begin
            empty_wait = 0;
            empty_reported = 0;
            seen_empty_event = empty_event;
        end 
        else begin
            if (seen_empty_event != empty_event) begin 
                empty_wait = 0;
                empty_reported = 0;
                seen_empty_event = empty_event;
            end
            if (is_empty()) begin
                empty_wait = 0;
                empty_reported = 0;
                if (rempty !== 1'b1) begin
                    $error("EMPTY FLAG ERROR: Golden model is empty, but rempty = 0");
                    errors++;
                end
            end
            else if (rempty !== 1'b0) begin
                empty_wait++;
                if (empty_wait > 3 && !empty_reported) begin
                    $error("EMPTY FLAG ERROR: rempty stayed high too long");
                    errors++;
                    empty_reported = 1;
                end 
            end 
            else begin
                empty_wait = 0;
                empty_reported = 0;
            end 
        end
    end
    // Check that wfull is high when the golden model is full.
    // Check at the falling edge to let the signals update.
    always @(negedge wclk) begin
        if (!wrst_n || !rrst_n) begin
            full_wait = 0;
            full_reported = 0;
            seen_full_event = full_event;
        end
        else begin
            if (seen_full_event != full_event) begin
                full_wait = 0;
                full_reported = 0;
                seen_full_event = full_event;
            end
            if (is_full()) begin
                full_wait = 0;
                full_reported = 0;
                if (wfull !== 1'b1) begin
                    $error("FULL FLAG ERROR: Golden model is full, but wfull = %b", wfull);
                    errors++;
                end
            end
            else if (wfull !== 1'b0) begin
                full_wait++;
                if (full_wait > 3 && !full_reported) begin
                    $error("FULL FLAG ERROR: wfull stayed high too long");
                    errors++;
                    full_reported = 1;
                end
            end
            else begin
                full_wait = 0;
                full_reported = 0;
            end
        end
    end
endmodule
