// Everything in this module lives in the write clock domain.
// The only async inputs are afull_n and aalmost_full_n which
// come in from async_cmp.
module wptr_full #(
    parameter ADDRSIZE = 4
) (
    output  logic wfull, 
    output  logic [ADDRSIZE-1:0] wptr,
    output  logic [ADDRSIZE-1:0] wptr_aeset, 
    output  logic [ADDRSIZE-1:0] wptr_aeclr,
    output  logic walmost_full,
    input   logic aalmost_full_n,
    input   logic afull_n, 
    input   logic winc, wclk, wrst_n
);
    localparam DEPTH = 1 << ADDRSIZE;
    localparam AE_SET = DEPTH - DEPTH/4; // when rptr = gray(wbin + AE_SET), FIFO holds 1/4 of words, almost_empty turns on
    localparam AE_CLR = AE_SET - 1; // almost_empty turns off

    logic [ADDRSIZE-1:0] wbin;
    logic wfull2, walmost_full2;
    logic [ADDRSIZE-1:0] wgnext, wbnext;


    function automatic logic [ADDRSIZE-1:0] bin2gray ( // converts an ADDRSIZE bit input and returns gray code
        input logic [ADDRSIZE-1:0] binary_value
    );
        return binary_value ^ (binary_value >> 1);
    endfunction

    //---------------------------------------------------------------
    // GRAYSTYLE2 pointer
    //---------------------------------------------------------------
    always_ff @(posedge wclk or negedge wrst_n)
        if (!wrst_n) begin
            wbin <= 0;
            wptr <= 0;
            wptr_aeset <= bin2gray(AE_SET);
            wptr_aeclr <= bin2gray(AE_CLR);
        end
        else begin
            wbin <= wbnext;
            wptr <= wgnext;
            wptr_aeset <= bin2gray(wbnext + AE_SET);
            wptr_aeclr <= bin2gray(wbnext + AE_CLR);
        end
    //---------------------------------------------------------------
    // increment the binary count if not full
    //---------------------------------------------------------------
    assign wbnext = !wfull ? wbin + winc : wbin;
    assign wgnext = bin2gray(wbnext); // binary-to-gray conversion

    always_ff @(posedge wclk or negedge wrst_n or negedge afull_n) // full flag w/ two flop synchronizer
        if (!wrst_n ) {wfull,wfull2} <= 2'b00; 
        else if (!afull_n) {wfull,wfull2} <= 2'b11; 
        else {wfull,wfull2} <= {wfull2,~afull_n}; 

    always_ff @(posedge wclk or negedge wrst_n or negedge aalmost_full_n) // same as above but for almost full flag
        if (!wrst_n ) {walmost_full,walmost_full2} <= 2'b00;
        else if (!aalmost_full_n) {walmost_full,walmost_full2} <= 2'b11;
        else {walmost_full,walmost_full2} <= {walmost_full2,~aalmost_full_n};
endmodule