// Everything in this module lives in the read clock domain.
// The only async inputs are aempty_n and aalmost_empty_n which
// come in from async_cmp.
module rptr_empty #(
    parameter ADDRSIZE = 4
) (
    output  logic rempty, 
    output  logic [ADDRSIZE-1:0] rptr, 
    output  logic ralmost_empty,
    output  logic [ADDRSIZE-1:0] rptr_afset, 
    output  logic [ADDRSIZE-1:0] rptr_afclr, 
    input   logic aalmost_empty_n,
    input   logic aempty_n, 
    input   logic rinc, rclk, rrst_n
);
    localparam DEPTH = 1 << ADDRSIZE; // mem depth = 2^(addr size)
    localparam AF_SET = DEPTH - DEPTH/4; // 3/4 of mem depth, almost_full turns on
    localparam AF_CLR = AF_SET - 1; // almost_full turns off

    logic [ADDRSIZE-1:0] rbin; // rbin = binary count, rptr is the gray code version that crosses clock domains
    logic rempty2, ralmost_empty2; // first stage of the two flop synchronizers
    logic [ADDRSIZE-1:0] rgnext, rbnext; // next state vals

    function automatic logic [ADDRSIZE-1:0] bin2gray ( // converts an ADDRSIZE bit input and returns gray code
        input logic [ADDRSIZE-1:0] binary_value
    );
        return binary_value ^ (binary_value >> 1);
    endfunction

    //---------------------------------------------------------------
    // GRAYSTYLE2 pointer
    //---------------------------------------------------------------
    always_ff @(posedge rclk or negedge rrst_n)
        if (!rrst_n) begin
            rbin <= 0;
            rptr <= 0;
            rptr_afset <= bin2gray(AF_SET); 
            rptr_afclr <= bin2gray(AF_CLR);
        end
        else begin
            rbin <= rbnext;
            rptr <= rgnext;
            rptr_afset <= bin2gray(rbnext + AF_SET); // when wptr = rptr_afset, exactly AF_SET (3/4) words are in the FIFO
            rptr_afclr <= bin2gray(rbnext + AF_CLR); 

        end
    //---------------------------------------------------------------
    // increment the binary count if not empty
    //---------------------------------------------------------------
    assign rbnext = !rempty ? rbin + rinc : rbin; 
    assign rgnext = bin2gray(rbnext); // binary-to-gray conversion

    always_ff @(posedge rclk or negedge aempty_n) // empty flag w/ two flop synchronizer
        if (!aempty_n) {rempty,rempty2} <= 2'b11; 
        else {rempty,rempty2} <= {rempty2,~aempty_n}; 

    always_ff @(posedge rclk or negedge aalmost_empty_n) // same as above but for almost empty flag
        if (!aalmost_empty_n) {ralmost_empty,ralmost_empty2} <= 2'b11;
        else {ralmost_empty,ralmost_empty2} <= {ralmost_empty2,~aalmost_empty_n};
endmodule