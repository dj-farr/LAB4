`timescale 1ns/1ps
module even_odd_alt_tb;

    localparam DSIZE = 8; // word size

    localparam ASIZE = 5; // addr size

    logic clk = 0;
    logic rst;
    logic w_en;
    logic r_en;

    logic [DSIZE-1:0] din;
    logic [DSIZE-1:0] dout;
    //previous output
    logic [DSIZE-1:0] prev_dout;

    // data of size 80
    logic [DSIZE-1:0] data_80 [0:79];

    // data of size 120 for fifo calc sol
    logic [DSIZE-1:0] data_120 [0:119];

    // data of size 160 for fifo calc sol
    logic [DSIZE-1:0] data_160 [0:159];

    // to check if the current value and last value are of the same class
    logic prev_read;


    // checks base case for last read
    logic first_read;

	// index for data
    integer r_count;
    integer r_req;
    integer r_missed;

    integer w_index;

    integer t;
    integer errors;

    // clock gen
    always #5 clk = ~clk;

    // instantiate DUT
    even_odd_alt  #(DSIZE, ASIZE) DUT (.*);
	even_odd_if #(DSIZE) eo_if (.*);

    always @(posedge clk) begin
		if (w_en) begin
			if(din[0] == 1'b0 && DUT.e_full)
			$display("EVEN FIFO IS FULL: could not write %0d", din);	
			if(din[0] == 1'b1 && DUT.o_full)
			$display("ODD FIFO IS FULL: could not write %0d", din);
		end

		if (r_en) begin
			// number of requests
			r_req = r_req + 1;

			if(DUT.e_rinc || DUT.o_rinc) begin
				// count number of reads
				r_count = r_count + 1;

				// AI found this
				// because we use <= in the even_odd_alt design,
				// dout updates after the posedge, so we add #`
				// the updated value
				#1

				if(!first_read) begin
					if(dout[0] == prev_read) begin
						$display("ERROR: output did not alternate, dout = %0d", dout);
						errors = errors + 1;
					end
				end

				// save the current even odd bit to check againt the next one
				prev_read = dout[0];
				first_read = 1'b0;
			end
			else begin
			//fifo was empty 
			r_missed = r_missed + 1;
			end
		end
	end

    // found a bug with my design impl here
    // AI helped with this
    // if a read is requested but the requested fifo is empty
    // dout should keep its previous value
    property dout_hold;
		@(posedge clk)
		disable iff (rst)
		(r_en && !DUT.e_rinc && !DUT.o_rinc) |=> $stable(dout);
    endproperty

    assert property (dout_hold)
    else begin
		$display("Error: dout change while fifo was empty");
		errors = errors + 1;
    end

    task reset;
		begin
			rst = 1'b1;
			w_en = 1'b0;
			r_en = 1'b0;

			@(negedge clk);

			r_count = 0;
			r_req = 0;
			r_missed = 0;

			w_index = 0;

			errors = 0;

			first_read = 1'b1;
			prev_read = 1'b0;

			repeat (2) @(posedge clk);

			@(negedge clk);
			rst = 1'b0;
		end
    endtask

    task gen_data(
		inout logic [DSIZE-1:0] data[],
		input int size
	);
		begin
			// fill the data with size/2 even numbers
			for(int i = 0; i < size/2; ++i)
				data[i] = $urandom_range(0, 63) * 2;

			// fill the data with size/2 odd numbers
			for(int i = size/2; i < size; ++i)
				data[i] = ($urandom_range(0, 63) * 2) + 1;

			// shuffle the data
			data.shuffle();
		end 
    endtask

    task print_fifo_status;
		begin
			$display("\nEven Fifo status:");
			$display("empty: %s", DUT.e_empty ? "Yes" : "No");
			$display("full:  %s", DUT.e_full ? "Yes" : "No");
			$display("Odd Fifo status:");
			$display("empty: %s", DUT.o_empty ? "Yes" : "No");
			$display("full:  %s", DUT.o_full ? "Yes" : "No");
		end
    endtask

    task print_results(
		input string title
    );
		begin
			$display("\n----------------------------");
			$display("EVEN/ODD ALT TEST -- %s", title);
			$display("Number of write attempts: %0d", w_index);
			$display("Number of successful reads : %0d", r_count);
			$display("Number of read requests: %0d", r_req);
			$display("Number missed requests: %0d", r_missed);
		end
    endtask

    task r_idle(
		input int cycles,
		input int r_active,
		input int idle,
		inout logic [DSIZE-1:0] data[]
	);
		repeat (cycles) begin
			// read only dont 
			repeat (r_active) begin
				@(negedge clk);
				w_en = 1'b0;
				r_en = 1'b1;
			end
			// idle
			repeat (idle) begin
				@(negedge clk);
				w_en = 1'b0;
				r_en = 1'b0;
			end
		end
    endtask

    task rw(
		input int cycles,
		input int rw_active,
		input int w_active,
		inout logic [DSIZE-1:0] data[]
    );
		repeat (cycles) begin
			// read and write
			repeat (rw_active) begin
				@(negedge clk);
				w_en = 1'b1;
				r_en = 1'b1;

				din = data[w_index];
				w_index = w_index +1;
			end
			// write only
			repeat (w_active) begin
				@(negedge clk);
				w_en = 1'b1;
				r_en = 1'b0;

				din = data[w_index];
				w_index = w_index +1;
			end
		end
    endtask
    
    task normal_fifo(
		inout logic [DSIZE-1:0] data[]
    );
		begin
			w_index = 0;
			// Data will be read from this design at a rate of 8 data items per 10 clock cycles.
			repeat (10) begin
				// read and write 
				repeat (8) begin
					@(negedge clk);
					
					w_en = 1'b1;
					r_en = 1'b1;

					din = data[w_index];

					w_index = w_index + 1;
				end
				// idle
				repeat (2) begin
					@(negedge clk);

					w_en = 1'b0;
					r_en = 1'b0;
				end
			end

			@(negedge clk);
			
			w_en = 1'b0;
			r_en = 1'b0;
		end
    endtask
    // FIFO calc sol cases

	// Case 9.4 - Worst-case write pattern
	// Starts with 20 cycles with no writes, followed by 160 continuous writes,
	// then ends with another 20 cycles with no writes. Reads continue throughout at
	// a rate of 8 reads every 10 cycles. The maximum write data rate and is used to
	// determine the required FIFO depth.
    task case_9_4(
		inout logic [DSIZE-1:0] data[]
    );
    	begin
			// first 20 cycles no write
			r_idle(2, 8, 2, data);
			// 160 writes
			rw(16, 8, 2, data);
			// last 20 cycles no write
			r_idle(2, 8, 2, data);
		end
    endtask

	// Case 8 - repeats a sequence of simultaneous read/write, idle, write only,
	// and idle operations. Writes happens every 2 cycles while reads at every 4 cycles.
	// This should crowed the FIFOs mem gradually.
    task case_8(
		inout logic [DSIZE-1:0] data[]
    );
    	begin
			repeat (60) begin
			// read and write
			@(negedge clk);
			w_en = 1'b1;
			r_en = 1'b1;

			din = data[w_index];
			w_index = w_index + 1;

			// idle
			@(negedge clk);
			w_en = 1'b0;
			r_en = 1'b0;

			// write only
			@(negedge clk);
			w_en = 1'b1;
			r_en = 1'b0;

			din = data[w_index];
			w_index = w_index + 1;

			// idle
			@(negedge clk);
			w_en = 1'b0;
			r_en = 1'b0;
			end
		end
    endtask

    task t_normal;
		gen_data(data_80, 80);

		reset();

		$display("----------------------------");
		$display("Errors caught from always block for the test below:");
		normal_fifo(data_80);

		repeat (2) @(posedge clk);

		print_results("normal case");

		print_fifo_status();

		if (errors == 0)
			$display("TEST PASSED");
		else
			$display("TEST FAILED: %0d errors", errors);

		$display("END\n\n");
    endtask

    task t_case94;
		gen_data(data_160, 160);

		reset();

		$display("Errors caught from always block for the test below:");

		case_9_4(data_160);

		repeat (2) @(posedge clk);

		print_results("Case 9.4");

		print_fifo_status();

		if (errors == 0)
			$display("TEST PASSED");
		else
			$display("TEST FAILED: %0d errors", errors);

		$display("END\n\n");
    endtask

    task t_case8;

		gen_data(data_120, 120);

		reset();

		$display("Errors caught from always block for the test below:");

		case_8(data_120);

		repeat (2) @(posedge clk);

		print_results("Case 8");

		print_fifo_status();

		if (errors == 0)
			$display("TEST PASSED");
		else
			$display("TEST FAILED: %0d errors", errors);

		$display("END\n\n");
    endtask

    initial begin
        if (!$test$plusargs("test")) begin
            //test not provided on the command line
            $display("No test provided. Exiting");
            $finish;
        end 

        $value$plusargs("test=%d",t);

        if (t == 1)      t_normal();
        else if (t == 2) t_case94();
        else if (t == 3) t_case8();
        else begin
            $display("Invalid test case. Exiting"); 
            $finish;
        end

	$display("----------------------------");
	$finish;
    end
    //dump waveform
    initial begin
        $fsdbDumpvars;
		$fsdbDumpSVA;
    end
endmodule
