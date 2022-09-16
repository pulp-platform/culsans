include ../common.mk

TESTS_DIR = ./testlist
TESTLIST := $(dir $(wildcard $(TESTS_DIR)/*/.))

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
	$(GCC) $(SW_INCLUDES) -Werror -c $< -o $@

# 
libs/libintegr.a: $(OBJS) libs
	$(AR) -rcs $@ $(OBJS)

sw : libs/libintegr.a
	for d in $(TESTLIST); do make -C $$d sw; done

# Compile the RTL

rtl:

# Run the test(s)

TEST ?= all

TEST_REPORT = result.rpt

# run all the tests
ifeq ($(TEST), all)
all: sw rtl
	for d in $(TESTLIST); do make -C $$d all; done
# run a single test
else
all: sw rtl
	if [ -d $(TESTS_DIR)/$(TEST) ]; then echo "$(TEST) doesn't exist"; false; fi
	make -C $(TESTS_DIR)/$(TEST) all
endif

# run failed or not-executed tests
rerun: sw rtl
	for d in $(TESTLIST); do if [ -e $$d/$(TEST_REPORT) ]; then if grep -q FAIL $$d/$(TEST_REPORT) ; then make -C $$d all; fi; else make -C $$d all; fi; done

# Cleanup

clean_sw:
	rm -rf objs
	rm -rf libs

clean_rtl:
	rm -rf work

clean_tests:
	for d in $(TESTLIST); do make -C $$d clean; done

clean: clean_sw clean_rtl clean_tests

.PHONY: all sw rtl rerun clean clean_sw clean_rtl