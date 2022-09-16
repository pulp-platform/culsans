# Culsans testsuite

## Introduction

This folder contains several regression lists to test the HCSC system.

The existing regression lists are:

- unit: tests for specific components (e.g. the coherent interconnect)
- integration: tests to verify the correct interaction of the components
- performance: 
- fpga: real-world and computational intensive tests, which would not be executable in simulation

## Preconditions

The following tools must be available:

- RISC-V toolchain
- RTL simulator (for RTL tests only, i.e. unit, integration and performance tests)
- RISC-V openOCD (for FPGA tests only)

In addition, to be able to run the FPGA-based tests, a bitfile must be available.
See the related README file for information about the creation of the bitfile.

## Commands

Top-level commands:

- `make all`: runs all tests in all regression lists
- `make unit`: runs all unit-level tests
- `make integr`: runs all integration tests
- `make perf`: runs all performance tests
- `make fpga`: runs all FPGA-based tests
- `make [unit|integr|perf|fpga] TEST=<testname>`: runs the testname test under the specified regression list
- `make summary`: summarises the results of the tests in an html file

Within each regression list, these commands are available:

- `make all`: runs all the unit-level tests
- `make failed`: runs all the failed and non-executed tests
- `make <testname>`: runs a specific testcase
- `make summary`: summarises the results of the unit-tests in an html file

Within the integration and performance regression lists, these commands are available:

- `make rtl`: compiles the RTL code
- `make sw`: compiles the C-code for all the tests

Within the FPGA regression list, these commands are available:

- `make bit`: generates the bitstream
- `make sw`: compiles the C-code for all the tests

Within a specific unit-level test:

- `make run`: runs the test
- `make rungui`: runs the test in GUI mode
- `make rtl`: compiles the RTL code

Within a specific integration or performance testcase:

- `make sw`: compiles the C-code for the specific testcase
- `make run`: runs the testcase
- `make rungui`: runs the test in GUI mode

Within a specific FPGA-based testcase:

- `make sw`: compiles the C-code for the specific testcase
- `make run`: runs the testcase

## Folders Structure

- unit
  - testcases
    - ...
- integr
  - scripts
  - sw
  - tb
  - testcases
    - ...
- perf
  - scripts
  - sw
  - tb
  - testcases
    - ...
- fpga
  - scripts
  - sw
  - testcases
    - ...

## Testcases

To ease the automation of the testing procedure, all testcases must share a common structure.

Each testcase must be contained in a folder named after the test (`<testname>`).

Other requirements change dependent on the regression list.

### Unit-level tests

Each test folder must contain:

- `<testname>.sv`: the testbench file
- `test.tcl`: a tcl file driving the simulation

The testbench file's header must be formatted like this:
```
// TestName: [the test name]
// Feature: [feature under test]
// TestObjective: [specific aspect of the feature to be stressed]
// TestPrerequisite: [prerequisite to the test sequence - e.g. memory content, active flags...]
// TestSequence: [describes how the test objective is actually stressed]
// PassCriteria: [describes which conditions must be verified to consider the test successful]
// ID: [related JIRA ticket]
```
These information are used to generate the test summary.

### Integration and performance level tests

Each test folder must contain:

- `<testfunction>.c`: the C-file implementing a test function; there can be multiple test functions in the same testcase
- `<testfunction>.h`: the header file declaring a test function
- `main.c`: the C-file using the test function(s)
- `test.tcl`: a tcl file driving the simulation

Note: having a separate function for implementation and usage of the test function can help reusing some test functions among different testcases

`main.c`'s header must follow the same rules as the one for the unit-level tests.

### FPGA tests

Each test folder must contain:

- `<testfunction>.c`: the C-file implementing a test function; there can be multiple test functions in the same testcase
- `<testfunction>.h`: the header file declaring a test function
- `main.c`: the C-file using the test function(s)

Note: having a separate function for implementation and usage of the test function can help reusing some test functions among different testcases

`main.c`'s header must follow the same rules as the one for the unit-level tests.

### Test evaluation

The execution of each test results in the generation of a `<testname>.rpt` file, which contains information about the result of the test (`PASS` or `FAIL`) and possibly some additional information to help with debugging (e.g. timeout or error code).

These files are used when generating the test summary.
