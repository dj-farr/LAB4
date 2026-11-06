class fifo_scoreboard #(parameter DSIZE = 8, parameter ASIZE = 4);
    typedef fifo_transaction#(DSIZE) txn_t;
    mailbox #(txn_t) txn_mail;
    
    localparam int DEPTH = 1 << ASIZE;
    logic [DSIZE-1:0] q[$]; // SystemVerilog reference FIFO

    int errors = 0;
    int accepted_writes = 0;
    int accepted_reads = 0;

    function new(mailbox #(txn_t) txn_mail);
        this.txn_mail = txn_mail;
    endfunction

    task run();
        txn_t txn;
        logic [DSIZE-1:0] expected;

        forever begin
            txn_mail.get(txn);

            if (txn.op == FIFO_RESET || txn.reset_n !== 1'b1) begin
                q.delete();
                accepted_writes = 0;
                accepted_reads = 0;
            end
            else if (txn.op == FIFO_WRITE) begin
                // Check the OLD occupancy at the sampled edge. On the
                // 16th accepted write, the full flag changes AFTER it.
                if (q.size() == DEPTH && txn.flag !== 1'b1) begin
                    $error("[SB] %0t expected wfull=1 for %0d words, got %b", txn.timestamp, DEPTH, txn.flag);
                    errors++;
                end
                if (txn.accepted) begin
                    if (q.size() >= DEPTH) begin
                        $error("[SB] %0t accepted WRITE while model is full", txn.timestamp);
                        errors++;
                    end
                    else begin
                        q.push_back(txn.data);
                        accepted_writes++;
                    end
                end
            end
            else if (txn.op == FIFO_READ) begin
                // This DUT exposes the memory head combinationally.
                // Only validate rdata when rempty is deasserted.
                if (txn.flag === 1'b0 && !txn.accepted) begin
                    if (q.size() == 0) begin
                        $error("[SB] %0t rempty=0 but reference FIFO is empty", txn.timestamp);
                        errors++;
                    end
                    else if (txn.data !== q[0]) begin
                        $error("[SB] %0t head mismatch: DUT=%0h expected=%0h", txn.timestamp, txn.data, q[0]);
                        errors++;
                    end
                end
                else if (q.size() == 0 && txn.flag !== 1'b1) begin
                    $error("[SB] %0t expected rempty=1, got %b", txn.timestamp, txn.flag);
                    errors++;
                end

                if (txn.accepted) begin
                    if (q.size() == 0) begin
                        $error("[SB] %0t accepted READ while reference FIFO is empty", txn.timestamp);
                        errors++;
                    end
                    else begin
                        expected = q.pop_front();
                        accepted_reads++;
                        if (txn.data !== expected) begin
                            $error("[SB] %0t read mismatch: DUT=%0h expected=%0h", txn.timestamp, txn.data, expected);
                            errors++;
                        end
                    end
                end
            end
        end
    endtask

    // Called by the testbench after stimulus has stopped.
    function void report(bit require_empty = 1);
        if (accepted_writes != accepted_reads + q.size()) begin
            $error("[SB] accounting mismatch: writes=%0d reads=%0d remaining=%0d", accepted_writes, accepted_reads, q.size());
            errors++;
        end

        if (require_empty && q.size() != 0) begin
            $error("[SB] final drain incomplete: %0d words remain", q.size());
            errors++;
        end

        if (txn_mail.num() != 0) begin
            $error("[SB] %0d unprocessed monitor transaction(s) at end of test", txn_mail.num());
            errors++;
        end

        $display("[SB] writes=%0d reads=%0d remaining=%0d errors=%0d", accepted_writes, accepted_reads, q.size(), errors);
    endfunction
endclass
