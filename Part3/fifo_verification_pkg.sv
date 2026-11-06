package fifo_verification_pkg;
    typedef enum bit [1:0] {FIFO_WRITE, FIFO_READ, FIFO_RESET} fifo_op_t;

    `include "fifo_transaction.svh"
    `include "fifo_monitor.svh"
    `include "fifo_scoreboard.svh"
endpackage


