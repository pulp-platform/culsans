include ../common.mk

include ../rtl.mk

LITMUS_SRC = ./litmus_src
LITMUS_BIN = $(LITMUS_SRC)/binaries

RESULTS = ./results

TEST ?= all

VSIM_LIB      = ./work

SIM_RUNTIME ?= 100ms
SIM_TCL = sim.tcl

VSIM_FLAGS += -voptargs=+acc
VSIM_FLAGS += -t 1ns
VSIM_FLAGS += -64
VSIM_FLAGS += -suppress 12110

GUI ?= 0

ifeq ($(GUI), 0)
	VSIM_FLAGS += -c
	VSIM_CMD = -do "run $(SIM_RUNTIME);"
else
	VSIM_CMD = -do "source $(SIM_TCL); run $(SIM_RUNTIME);"
endif


$(RESULTS):
	mkdir $(RESULTS)

.build-litmus-srcs:
	cd $(LITMUS_BIN) && ./make-riscv.sh ../tests; cd -
	touch .build-litmus-srcs

.PHONY: sw
sw: .build-litmus-srcs

HERD_EXP = $(RESULTS)/herd_exp.logs

$(HERD_EXP):
	python3 create_exp.py

COMPARE_LOG = $(RESULTS)/compare.rpt

.PHONY: run

# run all the tests
ifeq ($(TEST), all)
run: $(RESULTS) rtl
	@for t in $(LITMUS_BIN)/*.hex; \
		do \
			TESTNAME=`basename $$t .hex`; \
			echo "Running $$TESTNAME"; \
			rm main.hex 2> /dev/null; \
			rm uart.log 2> /dev/null; \
			rm sim.log 2> /dev/null; \
			ln -s $$t main.hex; \
			echo "Test $$TESTNAME Allow" > uart.log; \
			echo "Histogram" >> uart.log; \
			$(VSIM) $(VSIM_FLAGS) $(VSIM_CMD) -lib $(VSIM_LIB) $(TOP_LEVEL)_optimized > sim.log; \
			OUTFILE=$$TESTNAME.log && \
			mv uart.log $(RESULTS)/$$OUTFILE; \
			OUTFILE=$$TESTNAME_sim.log && \
			mv sim.log $(RESULTS)/$$OUTFILE; \
		done
	rm -f $(HERD_EXP)

RUN_LOG = $(RESULTS)/run.log

$(RUN_LOG): run
	@for t in $(RESULTS)/*.log; \
	do \
		if [[ "$$t" != *"_sim"* ]] && [[ "$$t" != "$(RUN_LOG)" ]] && [[ "$$t" != "$(HERD_EXP)" ]] ; then \
			if grep -q Time $$t; then \
				cat $$t >> $(RUN_LOG); \
				echo "" >> $(RUN_LOG); \
			fi; \
		fi; \
	done

$(COMPARE_LOG): $(RUN_LOG) $(HERD_EXP)
	mcompare7 -nohash $(RUN_LOG) $(HERD_EXP) > $(COMPARE_LOG)

# run a single test
else
$(RESULTS)/$(TEST).log: $(RESULTS) rtl
	@if [ -f $(LITMUS_BIN)/$(TEST).hex ]; then \
			echo "Running $(TEST)"; \
			rm main.hex 2> /dev/null; \
			rm uart.log 2> /dev/null; \
			rm sim.log 2> /dev/null; \
			ln -s $(LITMUS_BIN)/$(TEST).hex main.hex; \
			echo "Test $(TEST) Allow" > uart.log; \
			echo "Histogram" >> uart.log; \
			$(VSIM) $(VSIM_FLAGS) $(VSIM_CMD) -lib $(VSIM_LIB) $(TOP_LEVEL)_optimized > sim.log; \
    		OUTFILE=$(TEST).log && \
			mv uart.log $(RESULTS)/$$OUTFILE; \
			OUTFILE=$(TEST)_sim.log && \
			mv sim.log $(RESULTS)/$$OUTFILE; \
	else \
		echo "ERROR: TEST $(TEST) doesn't exist"; \
	fi
	rm -f $(HERD_EXP)

run: $(RESULTS)/$(TEST).log

$(COMPARE_LOG): run $(HERD_EXP)
	mcompare7 -nohash $(RESULTS)/$(TEST).log $(HERD_EXP) > $(COMPARE_LOG)

endif

compare: $(COMPARE_LOG)

eval: compare
	@if grep -q negative $(COMPARE_LOG); then echo FAILED; \
	else if grep -q positive $(COMPARE_LOG); then echo PASSED; \
	else echo UNKNOWN; \
	fi; fi

.PHONY: all
all: sw eval

.PHONY: clean_sw
clean_sw:
	cd $(LITMUS_BIN) && ./clean.sh && cd -
	@rm -rf .build-litmus-srcs

.PHONY: clean

clean: clean_rtl clean_sw
	@rm -rf $(RESULTS)
	@rm -rf trace_*
	@rm -rf transcript
	@rm -rf ace_log
	@rm -rf axi_log
	@rm -rf uart*
	@rm -rf vsim.wlf
	@rm -rf main.hex
