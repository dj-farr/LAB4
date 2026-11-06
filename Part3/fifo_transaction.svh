class fifo_transaction #(parameter DSIZE = 8);
    fifo_op_t op;
    logic [DSIZE-1:0] data;
    logic request;
    logic flag;          // wfull on WRITE; rempty on READ
    logic almost_flag;   // almost_full / almost_empty
    logic reset_n;
    logic accepted;
    time timestamp;

    function new();
        op = FIFO_RESET;
        data = '0;
        request = 0;
        flag = 0;
        almost_flag = 0;
        reset_n = 0;
        accepted = 0;
        timestamp = 0;
    endfunction
endclass
