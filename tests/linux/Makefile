include ../common.mk

include ../rtl.mk

TESTS_DIR = ./testlist
TESTLIST := $(dir $(wildcard $(TESTS_DIR)/*/.))

.PHONY: nb_cores
nb_cores: nb_cores_rtl

# Run the test(s)

TEST ?= all

# run all the tests
ifeq ($(TEST), all)
all: sw rtl
	for d in $(TESTLIST); do make -C $$d all; done
# run a single test
else
all: rtl
	if [ -d $(TESTS_DIR)/$(TEST) ]; then make -C $(TESTS_DIR)/$(TEST) all; else echo "$(TEST) doesn't exist"; false; fi
endif

# run failed or not-executed tests
rerun: rtl
	for d in $(TESTLIST); do if [ -e $$d/$(TEST_REPORT) ] and [ -e $$d/$(VERIFICATION_REPORT) ]; then if grep -q FAIL $$d/$(TEST_REPORT) ; then make -C $$d all; fi; else make -C $$d all; fi; done

# coverage
$(MERGED_UCDB):
	$(VCOVER) merge -out $(MERGED_UCDB) $(COVERAGE_DIR)

report_coverage: $(MERGED_UCDB)
	$(VCOVER) report -details       -codeAll -output $(COVERAGE_REPORT)      $(MERGED_UCDB)
	$(VCOVER) report -details -html -codeAll -output $(COVERAGE_REPORT_HTML) $(MERGED_UCDB)

# Cleanup

clean_tests:
	for d in $(TESTLIST); do make -C $$d clean; done

clean: clean_rtl clean_tests

.PHONY: all sw sw_all rerun clean report_coverage
