include ../common.mk

include ../rtl.mk

TESTS_DIR = ./testlist
TESTLIST := $(dir $(wildcard $(TESTS_DIR)/*/.))

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


# Run the test(s)

TEST ?= all

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
	for d in $(TESTLIST); do if [ -e $$d/$(TEST_REPORT) ] and [ -e $$d/$(VERIFICATION_REPORT) ]; then if grep -q FAIL $$d/$(TEST_REPORT) ; then make -C $$d all; fi; else make -C $$d all; fi; done

# Cleanup

clean_sw:
	rm -rf objs
	rm -rf libs

clean_tests:
	for d in $(TESTLIST); do make -C $$d clean; done

clean: clean_sw clean_rtl clean_tests

.PHONY: all sw rerun clean clean_sw
