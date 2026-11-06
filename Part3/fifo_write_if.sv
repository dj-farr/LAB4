// Write-side FIFO signals, sampled just before the write clock edge.
interface fifo_write_if #(parameter DSIZE = 8) (input logic wclk);
    logic wrst_n;
    logic winc;
    logic [DSIZE-1:0] wdata;
    logic wfull;
    logic almost_full;

    clocking mon_cb @(posedge wclk);
        default input #1step;
        input wrst_n, winc, wdata, wfull, almost_full;
    endclocking
endinterface
