class fifo_read_monitor #(parameter DSIZE = 8);
    typedef fifo_transaction#(DSIZE) txn_t;
    virtual fifo_read_if#(DSIZE) vif;
    mailbox #(txn_t) txn_mail;

    int logger;

    function new(virtual fifo_read_if#(DSIZE) vif, mailbox #(txn_t) txn_mail, int logger = 0);
        this.vif = vif;
        this.txn_mail = txn_mail;
        this.logger = logger;
    endfunction

    function void log_txn(txn_t txn);
        if (logger == 1)
            $display("[READ MON] transaction at %0t", txn.timestamp);
        else if (logger == 2)
            $display("[READ MON] time=%0t op=%s data=%0h request=%b rempty=%b almost_empty=%b rrst_n=%b accepted=%b",
                     txn.timestamp, txn.op.name(), txn.data, txn.request,
                     txn.flag, txn.almost_flag, txn.reset_n, txn.accepted);
    endfunction

    task sample_clocks();
        txn_t txn;
        forever begin
            @(vif.mon_cb);
            txn = new();
            txn.op = FIFO_READ;
            txn.timestamp = $time;
            // Clocking block input #1step captures pre-edge rdata and rempty.
            txn.data = vif.mon_cb.rdata;
            txn.request = vif.mon_cb.rinc;
            txn.flag = vif.mon_cb.rempty;
            txn.almost_flag = vif.mon_cb.almost_empty;
            txn.reset_n = vif.mon_cb.rrst_n;
            txn.accepted = (txn.reset_n === 1'b1 &&
                            txn.request === 1'b1 && txn.flag === 1'b0);
            txn_mail.put(txn);
            log_txn(txn);
        end
    endtask

    task watch_reset();
        txn_t txn;
        forever begin
            @(negedge vif.rrst_n);
            txn = new();
            txn.op = FIFO_RESET;
            txn.timestamp = $time;
            txn_mail.put(txn);
            log_txn(txn);
        end
    endtask

    task run();
        fork
            sample_clocks();
            watch_reset();
        join
    endtask
endclass

class fifo_write_monitor #(parameter DSIZE = 8);
    typedef fifo_transaction#(DSIZE) txn_t;
    virtual fifo_write_if#(DSIZE) vif;
    mailbox #(txn_t) txn_mail;

    int logger;
    
    function new(virtual fifo_write_if#(DSIZE) vif, mailbox #(txn_t) txn_mail, int logger = 0);
        this.vif = vif;
        this.txn_mail = txn_mail;
        this.logger = logger;
    endfunction

    function void log_txn(txn_t txn);
        if (logger == 1)
            $display("[WRITE MON] transaction at %0t", txn.timestamp);
        else if (logger == 2)
            $display("[WRITE MON] time=%0t op=%s data=%0h request=%b wfull=%b almost_full=%b wrst_n=%b accepted=%b",
                     txn.timestamp, txn.op.name(), txn.data, txn.request,
                     txn.flag, txn.almost_flag, txn.reset_n, txn.accepted);
    endfunction

    task sample_clocks();
        txn_t txn;
        forever begin
            @(vif.mon_cb);
            txn = new();
            txn.op = FIFO_WRITE;
            txn.timestamp = $time;
            txn.data = vif.mon_cb.wdata;
            txn.request = vif.mon_cb.winc;
            txn.flag = vif.mon_cb.wfull;
            txn.almost_flag = vif.mon_cb.almost_full;
            txn.reset_n = vif.mon_cb.wrst_n;
            txn.accepted = (txn.reset_n === 1'b1 &&
                            txn.request === 1'b1 && txn.flag === 1'b0);
            txn_mail.put(txn);
            log_txn(txn);
        end
    endtask

    task watch_reset();
        txn_t txn;
        forever begin
            @(negedge vif.wrst_n);
            txn = new();
            txn.op = FIFO_RESET;
            txn.timestamp = $time;
            txn_mail.put(txn);
            log_txn(txn);
        end
    endtask

    task run();
        fork
            sample_clocks();
            watch_reset();
        join
    endtask
endclass
