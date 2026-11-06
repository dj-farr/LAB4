// Compares Gray code pointers form both clock domains and holds 3 SR latches
module async_cmp #(
    parameter ADDRSIZE = 4
) (
    output logic aempty_n, 
    output logic afull_n, 
    output logic aalmost_empty_n,
    output logic aalmost_full_n,
    input  logic [ADDRSIZE-1:0] wptr, rptr, 
    input  logic [ADDRSIZE-1:0] rptr_afset, rptr_afclr,
    input  logic [ADDRSIZE-1:0] wptr_aeset, wptr_aeclr,
    input  logic wrst_n
);
    localparam N = ADDRSIZE-1;

    logic dirset_n, dirclr_n;
    logic afset_n, afclr_n; // active low set and clear inputs to latches
    logic aeset_n, aeclr_n; // active low set and clear inputs to latches
    logic almost_full_r, almost_empty_r, direction; // latch states
    
    // quadrant detection logic (see Cummings paper #2 page 4)
    // top two Gray bits tell which quadrant of address space a pointer is in
    assign dirset_n = ~( (wptr[N]^rptr[N-1]) & ~(wptr[N-1]^rptr[N])); // goes low when wptr is one quadrant behind rptr = FIFO filling
    assign dirclr_n = ~((~(wptr[N]^rptr[N-1]) & (wptr[N-1]^rptr[N])) |  // goes low when wptr is one quadrant ahead of rptr = FIFO draining (or reset)
    ~wrst_n);

    assign afset_n = ~(wptr == rptr_afset); // set almost_full at 3/4 
    assign afclr_n = ~((wptr == rptr_afclr) | ~wrst_n); // clear almost_full at one less or reset
    assign aeset_n = ~((rptr == wptr_aeset) | ~wrst_n); // set almost_empty at 1/4 or reset
    assign aeclr_n = ~(rptr == wptr_aeclr); // clear almost_empty at one more

    // SR latches (see Cummings paper #2 page 4)
    always_latch 
        if (!dirclr_n) direction = 1'b0;
        else if (!dirset_n) direction = 1'b1;

    always_latch
        if (!afclr_n) almost_full_r = 1'b0;
        else if (!afset_n) almost_full_r = 1'b1;

    always_latch
        if (!aeclr_n) almost_empty_r = 1'b0;
        else if (!aeset_n) almost_empty_r = 1'b1;
    
    assign aempty_n         = ~((wptr == rptr) && !direction); // ptrs equal and direction = draining
    assign afull_n          = ~((wptr == rptr) && direction);  // ptrs equal and direction = filling
    assign aalmost_full_n   = ~(almost_full_r);  // latch state inverted to active low
    assign aalmost_empty_n  = ~(almost_empty_r); // latch state inverted to active low

endmodule