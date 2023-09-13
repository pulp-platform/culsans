include ../common.mk
include ../rtl.mk

NB_CORES := 4

TESTS_DIR = ./testlist
TESTLIST := $(dir $(wildcard $(TESTS_DIR)/*/.))

# List known failing tests
FAIL_LIST += $(TESTS_DIR)/read_two_writes_back_to_back/ # Triggers Jira Issue PROJ-147

PASS_LIST = $(filter-out $(FAIL_LIST), $(TESTLIST))

# other sets
AMO_LIST := $(dir $(wildcard $(TESTS_DIR)/*amo*/.))


help:
	@echo ""
	@echo "    make all                   run all tests"
	@echo "    make pass                  run all tests that are expected to pass"
	@echo "    make fail                  run all tests that are expected to fail"
	@echo "    make all TEST=<testname>   run test $(TESTS_DIR)/<testname>"
	@echo "    make rerun                 run all tests that failed or that has not been run"
	@echo "    make rerun_pass            run all tests expected to pass that failed or that has not been run"
	@echo "    make status                list result from latest run of each test"
	@echo "    make list_tests            list all available tests"
	@echo "    make clean                 clean all test results"
	@echo "    make help                  print this message"
	@echo ""


# Check that SW is aligned with the NB_CORES setting

SW_NBCORES_DEF = "\# define NB_CORES $(NB_CORES)"

.PHONY: nb_cores_sw
nb_cores_sw:
	@if ! grep -q $(SW_NBCORES_DEF) ./sw/sys/crt.S; then \
		sed -i 's/\# define NB_CORES [0-9]\+/\# define NB_CORES $(NB_CORES)/' ./sw/sys/crt.S; \
	fi

.PHONY: nb_cores
nb_cores: nb_cores_sw nb_cores_rtl

# Compile the SW

COMMON_TEST_SW = ./sw
COMMON_TEST_SW_SRC = $(COMMON_TEST_SW)/src
COMMON_TEST_SW_INC = $(COMMON_TEST_SW)/include

# more folders might be added in the future
VPATH = $(COMMON_TEST_SW_SRC)
# more folders might be added in the future
SW_INCLUDES = $(foreach d, $(COMMON_TEST_SW_INC), -I$d)
# more folders might be added in the future
SW_SRCS += $(shell find $(COMMON_TEST_SW_SRC) -name *.c -exec basename {} \;)

OBJDIR = ./objs
OBJS = $(SW_SRCS:%.c=$(OBJDIR)/%.o)

objs:
	mkdir -p $@

libs:
	mkdir -p $@

$(OBJDIR)/%.o: %.c objs
	$(RV_GCC) $(SW_INCLUDES) -Werror -falign-functions=32 -falign-jumps=32 -c $< -o $@

#
libs/libintegr.a: $(OBJS) libs
	$(RV_AR) -rcs $@ $(OBJS)

sw : libs/libintegr.a nb_cores
	for d in $(TESTLIST); do make -C $$d sw; done

sw_all : libs/libintegr.a nb_cores
	for d in $(TESTLIST); do make -C $$d all; done

rtl : sw

# Run the test(s)

TEST ?= all

# select a test for sanity
sanity : TEST := read_miss
sanity : rtl
	make -C testlist/${TEST} all

# run all the tests
ifeq ($(TEST), all)
all: rtl sw
	@-for d in $(TESTLIST); do make -C $$d all; done
	@$(MAKE) status

# run a single test
else
all: rtl sw
	@if [ -d $(TESTS_DIR)/$(TEST) ]; then \
		make -C $(TESTS_DIR)/$(TEST) all; \
	else \
		echo "Test $(TEST) doesn't exist"; false; \
	fi
endif

# run all tests expected to pass
pass: rtl
	@-for d in $(PASS_LIST); do make -C $$d all; done
	@$(MAKE) status

# run all tests expected to fail
fail: rtl
	@-for d in $(FAIL_LIST); do make -C $$d all; done
	@$(MAKE) status

# run all tests expected to fail
amo: rtl
	@-for d in $(AMO_LIST); do make -C $$d all; done
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

rerun_pass: rtl
	@-for d in $(PASS_LIST); do \
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

clean: clean_tests

.PHONY: all sw pass fail rerun status list_tests clean_tests clean clean_sw
