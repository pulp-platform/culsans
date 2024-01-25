# Culsans testsuite

## Introduction

This folder contains several regression lists to test the HCSC system.

The existing regression lists are:

- unit: tests for specific components (e.g. the coherent interconnect). More details are in [unit/](unit/)
- integration: tests to verify the correct interaction of the components
- performance: tests to measure the performance of various memory / cache transactions

## Preconditions

The following tools must be available:

- RISC-V toolchain
- RTL simulator (for RTL tests only, i.e. unit, integration and performance tests)

## Commands

Top-level commands:

- `make all`: runs all tests in all regression lists
- `make unit`: runs all unit-level tests
- `make integr`: runs all integration tests
- `make perf`: runs all performance tests
- `make [unit|integr|perf] TEST=<testname>`: runs the testname test under the specified regression list

Within each regression list, these commands are available:

- `make all`: runs all the unit-level tests
- `make rerun`: runs all the failed and non-executed tests
- `make all TEST=<testname>`: runs a specific testcase
- `make rtl`: compiles the RTL code

Within the **integration** and **performance** regression lists, these commands are available:
- `make sw`: compiles the C-code for all the tests

## Testcases

To ease the automation of the testing procedure, all testcases must share a common structure.

Each testcase must be contained in a folder named after the test (`<testname>`).

Other requirements change dependent on the regression list.

### Unit-level tests

Each test folder must contain:

- `Makefile`: a Makefile, typically setting the test name and including ../../test_automation/Makefile
- `sim.tcl`: a tcl file driving the simulation,, typically a symlink to ../../test_automation/sim.tcl

### Integration and performance level tests

Each test folder must contain:

- `<testfunction>.c`: the C-file implementing a test function; there can be multiple test functions in the same testcase
- `<testfunction>.h`: the header file declaring a test function
- `main.c`: the C-file using the test function(s)
- `sim.tcl`: a tcl file driving the simulation

Note: having a separate function for implementation and usage of the test function can help reusing some test functions among different testcases

`main.c`'s header must follow the same rules as the one for the unit-level tests.

The main function must return 0 in case of correct execution, an error code otherwise.
The `return` command is translated to a write to the location `to_host` (see `syscalls.c`), which is defined in the linker script (`linker.ld`). The testbench (both SystemVerilog and C++) react to this event, interrupt the simulation and write the report file.
