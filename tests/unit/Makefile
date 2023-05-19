include ../common.mk
include ../rtl.mk

TESTS_DIR = ./testlist
TESTLIST := $(dir $(wildcard $(TESTS_DIR)/*/.))

# List known failing tests
FAIL_LIST += $(TESTS_DIR)/read_two_writes_back_to_back/ # Triggers Jira Issue PROJ-147
FAIL_LIST += $(TESTS_DIR)/amo_snoop_single_collision/   # Triggers Jira issue PROJ-150
FAIL_LIST += $(TESTS_DIR)/random_cached_amo/            # Triggers Jira issue PROJ-150
FAIL_LIST += $(TESTS_DIR)/amo_read_write_collision/     # Triggers Jira issue PROJ-153
FAIL_LIST += $(TESTS_DIR)/amo_read_cached/              # Triggers Jira issue PROJ-153

PASS_LIST = $(filter-out $(FAIL_LIST), $(TESTLIST))

help:
	@echo ""
	@echo "    make all                   run all tests"
	@echo "    make pass                  run all tests that are expected to pass"
	@echo "    make fail                  run all tests that are expected to fail"
	@echo "    make all TEST=<testname>   run test $(TESTS_DIR)/<testname>"
	@echo "    make rerun                 run all tests that failed or that has not been run"
	@echo "    make status                list result from latest run of each test"
	@echo "    make list_tests            list all available tests"
	@echo "    make clean                 clean all test results"
	@echo "    make help                  print this message"
	@echo ""

# Run the test(s)

TEST ?= all

DEFINES := CULSANS_TB_UNIT_TEST

# run all the tests
ifeq ($(TEST), all)
all: rtl
	@-for d in $(TESTLIST); do make -C $$d all; done
	@$(MAKE) status

# run a single test
else
all: rtl
	@if [ -d $(TESTS_DIR)/$(TEST) ]; then \
		make -C $(TESTS_DIR)/$(TEST) all; \
	else \
		echo "Test $(TEST) doesn't exist"; false; \
	fi
endif

# run all tests expected to pass
pass: rtl
	@for d in $(PASS_LIST); do make -C $$d all; done
	@$(MAKE) status

# run all tests expected to fail
fail: rtl
	@-for d in $(FAIL_LIST); do make -C $$d all; done
	@$(MAKE) status

# run failed or not-executed tests
rerun: rtl
	@-for d in $(TESTLIST); do \
		if [ -e $$d/$(TEST_REPORT) ]; then \
			if grep -q Error $$d/$(TEST_REPORT) ; then \
				make -C $$d all; \
			fi; \
		else \
			make -C $$d all; \
		fi; \
	done
	@$(MAKE) status

# list status
status:
	@for d in $(TESTLIST); do \
		if [ -e $$d/$(TEST_REPORT) ]; then \
			if grep -q Error $$d/$(TEST_REPORT); then \
				printf "%-40s\t : \033[31mFAILED\033[0m\n" $$d; \
			else \
				printf "%-40s\t : \033[32mPASSED\033[0m\n" $$d; \
			fi; \
		else \
			printf "%-40s\t : \033[33mNOT RUN\033[0m\n" $$d; \
		fi; \
	done

list_tests:
	@for d in $(TESTLIST); do printf "$$d\n"; done

# Cleanup
clean_tests:
	for d in $(TESTLIST); do make -C $$d clean; done

clean: clean_rtl clean_tests

.PHONY: all pass fail rerun status list_tests clean_tests clean clean_sw
