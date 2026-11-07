interface even_odd_if #(parameter DSIZE = 8) (
    input logic clk, rst, w_en, r_en,
    input logic [DSIZE-1:0] din, dout
);
    default clocking @(posedge clk); endclocking
    default disable iff (rst);

    a_even_path: assert property (
        w_en && !din[0] && !even_odd_alt_tb.DUT.e_full |-> even_odd_alt_tb.DUT.e_winc
    ) else $error("even write did not go to even FIFO");
endinterface