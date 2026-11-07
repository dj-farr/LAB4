# CSE 494 Lab 4: FIFO Verification

This lab verifies the asynchronous FIFO and even-odd circuit from Lab 1. Each part folder is self-contained, with its own copy of the design files and its own Makefile.

| Folder | Design under test | Verification approach |
|---|---|---|
| [`Part2/`](Part2/) | Asynchronous FIFO | C++ reference model and checker connected through DPI-C |
| [`Part3/`](Part3/) | Asynchronous FIFO | SystemVerilog interfaces, monitors, and a scoreboard |
| [`Part4/`](Part4/) | Even-odd circuit | SystemVerilog Assertions (SVA) inside an interface |

## Part 2: Reference model and checker

Checks the FIFO against a reference model written in C++.

- `fifo_golden_model.cpp`: reference FIFO, called from SystemVerilog through DPI-C.
- `fifo_checker.sv`: compares FIFO data and the full and empty flags against the reference model.
- `async_fifo_tb.sv`: runs the stimulus and can drop every Nth write to test that the checker catches errors.
- `part2.rc`: saved Verdi signal setup.

The `.svh` class files and `fifo_verification_pkg.sv` are also in this folder, but the Part 2 Makefile does not compile them. They are used in Part 3.

```bash
make compile_sim1        # scenarios 1-3: compile_sim1, compile_sim2, compile_sim3
make compile_sim1_bug    # same test, dropping every 4th write
```

## Part 3: Monitors and scoreboard

Checks the FIFO with a class-based testbench written in SystemVerilog. The testbench uses a SystemVerilog queue as its reference model and does not use the DPI-C checker.

- `fifo_write_if.sv`, `fifo_read_if.sv`: separate interfaces for the write and read clock domains.
- `fifo_transaction.svh`: describes one observed write, read, or reset.
- `fifo_monitor.svh`: write and read monitors that send transactions to a mailbox.
- `fifo_scoreboard.svh`: checks data, flags, and final counts against the queue.
- `fifo_verification_pkg.sv`: packages the classes for the testbench.

The monitors support three logging levels through `+LOGGER`: off (0), brief (1), and verbose (2).

```bash
make compile_sim1                # scenarios 1-3: compile_sim1, compile_sim2, compile_sim3
make compile_sim1_bug            # drop every 4th write
make compile_sim1_bug_brief      # with brief logging
make compile_sim1_bug_verbose    # with verbose logging
```

## Part 4: Assertion-based verification

Checks the even-odd circuit using assertions and the stimulus from Lab 1.

- `even_odd_if.sv`: passive interface containing the assertions and cover properties. It reads internal DUT signals through hierarchical references.
- `even_odd_alt.sv`: the design, with an error that can be enabled using `+BUG=1`.
- `even_odd_alt_tb.sv`: the Lab 1 testbench, with the interface added and assertion dumping enabled.
- `a_*.rc`, `bug_injected.rc`: saved Verdi signal setups for each assertion and for the injected error.

| Assertion | What it checks |
|---|---|
| `a_even_path` | An even write goes only to the even FIFO |
| `a_odd_path` | An odd write goes only to the odd FIFO |
| `a_even_then_odd` | The next read switches to odd after an even read |
| `a_odd_then_even` | The next read switches to even after an odd read |
| `a_dout_hold` | `dout` changes only on a successful read |
| `a_even_empty_rptr` | The even read pointer does not move when the FIFO is empty |
| `a_odd_empty_rptr` | The odd read pointer does not move when the FIFO is empty |

With `+BUG=1`, the design stays on the even FIFO after an even read instead of switching to odd, which makes `a_even_then_odd` fail.

```bash
make compile_sim1_p2     # compile and run test 1 with no injected error
make eo_case9_4          # run test 2 without recompiling
make eo_case8            # run test 3 without recompiling
make eo_naive BUG=1      # run test 1 with the injected error
```

Use only the `_p2` and `eo_*` targets in this folder. The other simulation targets need `async_fifo_tb.sv`, which is not included here.

## Running the labs

The simulations use Synopsys VCS and Verdi. From a part folder, in `csh` or `tcsh`:

```bash
source ../env.cshrc
make <target>
make waves_verdi    # view the waveform from the last run
make clean          # remove generated files
```

## Other files

The `sv_style_*.sv`, `dpi_*.sv`, and `dpi.c` files in the repository root are small adder examples, not part of the FIFO design. The `sv_style` files show different testbench structures, and the `dpi` files show how to call C from SystemVerilog.
