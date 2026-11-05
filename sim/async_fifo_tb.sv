`timescale 1ns/1ps
module async_fifo_tb;

    localparam DSIZE = 8; // word size
    localparam ASIZE = 4; // addr size

    // outputs
    logic [DSIZE-1:0] rdata;
    logic wfull;
    logic rempty;
    logic almost_full;
    logic almost_empty;

    // inputs
    logic [DSIZE-1:0] wdata;
    logic winc, wrst_n; 
    logic rinc, rrst_n;
    
    logic rclk = 0;
    logic wclk = 0;

    integer scenario_num;
    integer errors = 0;
    logic [DSIZE-1:0] expected; // next value we expect to read

    // clock gen for read and write
    always #8 wclk = ~wclk;
    always #5 rclk = ~rclk;

    // instantiate DUT
    async_fifo #(DSIZE, ASIZE) DUT (.*);
    async_fifo_checker #(DSIZE, ASIZE) CHECKER (.*);


    // drop settings
    integer drop_n = 0;
    integer write_count = 0;

    initial begin
        void'($value$plusargs("drop_n=%d", drop_n));
    end

    // Drop every Nth write without changing the FIFO
    always @(negedge wclk) begin
        #1; // Let the testbench update winc first

        release DUT.mem_if.wclken;

        if (!wrst_n) begin
            write_count = 0;
        end
        else if (winc && !wfull) begin
            write_count++;

            if (drop_n > 0 && write_count % drop_n == 0) begin
                force DUT.mem_if.wclken = 1'b0;
                $display("BUG: Dropping write %0d at %0t",
                        write_count, $time);
            end
        end
    end


    always @(posedge wclk) // fill FIFO with incrementing numbers for each write
        if (winc && !wfull) wdata <= wdata + 1;
    
    always @(posedge rclk) begin // check each read val, make sure it matches expected
        if (rinc && !rempty) begin
            if (rdata !== expected) begin
                $display("Error at %0t: read %0d, expected %0d", $time, rdata, expected);
                errors = errors + 1;
            end
            expected <= expected + 1;
        end
    end

    //reset both clock domains
    task reset();
        winc = 0;
        rinc = 0;
        wdata = 1;
        expected = 1;
        wrst_n = 0;
        rrst_n = 0;
        repeat (3) @(negedge wclk); // hold reset (was giving me errors when i didn't before)
        wrst_n = 1;
        @(negedge rclk);
        rrst_n = 1;
        repeat (3) @(negedge wclk);
    endtask

    // holds winc high for n write clock cycles
    task write(input integer n); 
        @(negedge wclk);
        winc = 1;
        repeat (n) @(negedge wclk);
        winc = 0;
    endtask

    // holds rinc high for n read clock cyles
    task read(input integer n);
        @(negedge rclk);
        rinc = 1;
        repeat (n) @(negedge rclk);
        rinc = 0;
    endtask

    // if a flag doesn't match expected then prints an error with the name of the flag
    task flag_check(input logic actual_val, input logic expected_val, input [8*20:1] flag_name);
        if (actual_val !== expected_val) begin
            $display("Error at %0t: %0s = %b, expected %b", $time, flag_name, actual_val, expected_val);
            errors = errors + 1;
        end
    endtask

    // scenario 1 = FIFO empty then filled, then FIFO full then emptied
    task scenario1();
        reset();
        flag_check(rempty, 1, "rempty");
        flag_check(wfull, 0, "wfull");

        write(16); // fills FIFO with data from 1 to 16
        repeat (3) @(negedge rclk); // wait for synchronizer
        flag_check(rempty, 0, "rempty");
        flag_check(wfull, 1, "wfull");

        write(1); // if FIFO is full then this write should be ignored
        flag_check(wfull, 1, "wfull");

        read(16); // empty the FIFO
        flag_check(rempty, 1, "rempty");
        repeat (3) @(negedge wclk); // wait for synchronizer
        flag_check(wfull, 0, "wfull");
    endtask  
    
    // scenario 2 = almost_empty turns on at 4 words, almost_full turns on at 12 words
    task scenario2();
        reset();
        flag_check(almost_empty, 1, "almost_empty"); // 0 words

        write(4);
        repeat (3) @(negedge rclk); // 4 words
        flag_check(almost_empty, 1, "almost_empty");

        write(1);
        repeat (3) @(negedge rclk); // 5 words
        flag_check(almost_empty, 0, "almost_empty");

        write(6); // 11 words
        flag_check(almost_full, 0, "almost_full");

        write(1); // 12 words
        flag_check(almost_full, 1, "almost_full");
        
        read(1); // 11 words
        repeat (3) @(negedge wclk);
        flag_check(almost_full, 0, "almost_full");

        read(6); // 5 words
        flag_check(almost_empty, 0, "almost_empty");

        read(1); // 4 words
        flag_check(almost_empty, 1, "almost_empty");
    endtask 

    // scenario 3 = read and write at the same time on different clocks
    task scenario3();
        reset();
        winc = 1; // start reading and writing together
        rinc = 1;
        repeat (50) @(negedge wclk); // do this 50 times
        winc = 0;
        repeat (10) @(negedge rclk); // keep reading until empty
        rinc = 0;
        flag_check(rempty, 1, "rempty");
        if (expected !== wdata) begin // if any word was written but not read out, print an error
            $display("Error: wrote up to %0d but read up to %0d", wdata - 1, expected - 1);
            errors = errors + 1;
        end
    endtask

    initial begin 
        if (!$test$plusargs("test")) begin
            //test not provided on the command line
            $display("No test provided. Exiting");
            $finish;
        end 

        $value$plusargs("test=%d",scenario_num);

        if (scenario_num == 1)      scenario1();
        else if (scenario_num == 2) scenario2();
        else if (scenario_num == 3) scenario3();
        else begin
            $display("Invalid test case. Exiting"); 
            $finish;
        end

        if (errors == 0 && CHECKER.errors == 0) $display("SCENARIO %0d PASSED", scenario_num);
        else             $display("SCENARIO %0d FAILED with %0d errors", scenario_num, errors + CHECKER.errors);
        $finish;
    end  
    
    //dump waveform
    initial begin
        $fsdbDumpvars;
    end
endmodule
