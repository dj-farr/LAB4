// Read-side FIFO signals, sampled just before the read clock edge.
interface fifo_read_if #(parameter DSIZE = 8) (input logic rclk);
    logic rrst_n;
    logic rinc;
    logic [DSIZE-1:0] rdata;
    logic rempty;
    logic almost_empty;

    clocking mon_cb @(posedge rclk);
        default input #1step;
        input rrst_n, rinc, rdata, rempty, almost_empty;
    endclocking
endinterface
