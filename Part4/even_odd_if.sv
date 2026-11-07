interface even_odd_if #(parameter DSIZE = 8) (
    input logic clk, rst, w_en, r_en,
    input logic [DSIZE-1:0] din, dout
);
    default clocking @(posedge clk); endclocking
    default disable iff (rst);

    a_even_path: assert property (
        w_en && !din[0] && !even_odd_alt_tb.DUT.e_full |-> 
            even_odd_alt_tb.DUT.e_winc && !even_odd_alt_tb.DUT.o_winc
    ) else $error("even write did not only go to even FIFO");
    
    a_odd_path: assert property (
        w_en && din[0] && !even_odd_alt_tb.DUT.o_full |-> 
            even_odd_alt_tb.DUT.o_winc && !even_odd_alt_tb.DUT.e_winc
    ) else $error ("odd write did not only go to odd FIFO");

    a_even_then_odd: assert property (
        even_odd_alt_tb.DUT.e_rinc |=> even_odd_alt_tb.DUT.next == even_odd_alt_tb.DUT.ODD
    ) else $error("next read didn't switch to odd after an even read");

    a_dout_hold: assert property (
        !(even_odd_alt_tb.DUT.e_rinc || even_odd_alt_tb.DUT.o_rinc) |=> $stable(dout)
    ) else $error("dout changed without a successful read");

    a_even_empty_rptr: assert property (
        r_en && even_odd_alt_tb.DUT.e_empty |=> $stable(even_odd_alt_tb.DUT.even_fifo.rptr)
    ) else $error("even read pointer moved while the FIFO was empty");
endinterface