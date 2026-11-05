# TO RUN: 
# make compile_sim1 -> make compile_sim2 -> make compile_sim3
# or just make all
# then you can justr un make waves_verdi
# and make clean when done
#
# variables
RTL 	=  fifo_mem_if.sv fifo_mem.sv async_cmp.sv rptr_empty.sv wptr_full.sv async_fifo.sv
TB      =  async_fifo_tb.sv
TB2     =  even_odd_alt_tb.sv
VCS     =  ${VCS_HOME}/bin/vcs -full64 -sverilog -timescale=1ns/1ps -debug_access+all -kdb -lca
CHECKER =  fifo_checker.sv
GOLDEN  =  fifo_golden_model.cpp
DROP    ?= 0

# for all of our commands phony makes sure they don't conflict w/ filenames
.PHONY: all compile compile_p2 sim1 sim2 sim3 sim4 sim5 sim6 sim7 sim8 sim9 sim10 sim11 sim12 \
        compile_sim1 compile_sim2 compile_sim3 compile_sim1_bug compile_sim2_bug \
        compile_sim3_bug compile_sim1_p2 compile_sim2_p2 compile_sim3_p2 waves_verdi clean

# compile and run each test
all: compile sim1 sim2 sim3 sim4 sim5 sim6 sim7 sim8 sim9 sim10 sim11 sim12

# compile the design and testbench into simv
compile:
	$(VCS) $(RTL) $(CHECKER) $(TB) $(GOLDEN) -CFLAGS "-std=c++17" -o simv -l compile.log
compile_p2:
	$(VCS) $(RTL) even_odd_alt.sv $(TB2) -top even_odd_alt_tb -o simv -l compile.log

# compile and sim
compile_sim1: compile sim1
compile_sim2: compile sim2
compile_sim3: compile sim3

compile_sim1_bug: compile 
	$(MAKE) sim1 DROP=4
compile_sim2_bug: compile 
	$(MAKE) sim2 DROP=4
compile_sim3_bug: compile 
	$(MAKE) sim3 DROP=4

compile_sim1_p2: compile_p2 eo_naive
compile_sim2_p2: compile_p2 eo_case9_4
compile_sim3_p2: compile_p2 eo_case8

# scenario 1: empty, filled, full, emptied
sim1:
	./simv +test=1 +drop_n=$(DROP) $(if $(filter write,$(BUG)),+write_bug,) $(if $(filter empty,$(BUG)),+empty_bug,) -l sim1.log

# scenario 2: assert almost_full and almost_empty 
sim2:
	./simv +test=2 +drop_n=$(DROP) -l sim2.log

# scenario 3: simultaneous read and write w/ different clock frequencies
sim3:
	./simv +test=3 +drop_n=$(DROP) -l sim3.log

# Additional directed cases from the verification plan.
sim4 sim5 sim6 sim7 sim8 sim9 sim10 sim11 sim12:
	./simv +test=$(patsubst sim%,%,$@) +drop_n=$(DROP) -l $@.log


eo_naive:
	./simv +test=1 -l eo_naive.log
eo_case9_4:
	./simv +test=2 -l eo_case9_4.log
eo_case8:
	./simv +test=3 -l eo_case8.log

# launch verdi with the waves from the last scenario that ran
waves_verdi:
	$(VERDI_HOME)/bin/verdi -dbdir ./simv.daidir -ssf novas.fsdb -nologo

clean:
	\rm -rf *.log *.h csrc DVEFiles simv simv.daidir ucli.key vcdplus.vpd \
	        *.syn *.pvl *.mr *.svf command.log *.txt \
	        *.fsdb novas.conf novas.rc novas.log novas_dump.log verdi_config_file verdiLog

