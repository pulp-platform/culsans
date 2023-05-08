include ../common.mk

include ../rtl.mk

TESTS_DIR = ./testlist
TESTLIST := $(dir $(wildcard $(TESTS_DIR)/*/.))

# List known failing tests
FAIL_LIST += $(TESTS_DIR)/random_all/
FAIL_LIST += $(TESTS_DIR)/random_cached/
FAIL_LIST += $(TESTS_DIR)/random_cached_shared/
FAIL_LIST += $(TESTS_DIR)/read_two_writes_back_to_back/

PASS_LIST = $(filter-out $(FAIL_LIST), $(TESTLIST))

### # Check that SW is aligned with the NB_CORES setting
### 
### SW_NBCORES_DEF = "\# define NB_CORES $(NB_CORES)"
### 
### .PHONY: nb_cores_sw
### nb_cores_sw:
### 	@if ! grep -q $(SW_NBCORES_DEF) ./sw/sys/crt.S; then \
### 		sed -i 's/\# define NB_CORES [0-9]\+/\# define NB_CORES $(NB_CORES)/' ./sw/sys/crt.S; \
### 	fi
### 
### .PHONY: nb_cores
### nb_cores: nb_cores_sw nb_cores_rtl
### 
### # Compile the SW
### 
### COMMON_TEST_SW = ./sw
### COMMON_TEST_SW_SRC = $(COMMON_TEST_SW)/src
### COMMON_TEST_SW_INC = $(COMMON_TEST_SW)/include
### 
### # more folders might be added in the future
### VPATH = $(COMMON_TEST_SW_SRC)
### # more folders might be added in the future
### SW_INCLUDES = $(foreach d, $(COMMON_TEST_SW_INC), -I$d)
### # more folders might be added in the future
### SW_SRCS += $(shell find $(COMMON_TEST_SW_SRC) -name *.c -exec basename {} \;)
### 
### OBJDIR = ./objs
### OBJS = $(SW_SRCS:%.c=$(OBJDIR)/%.o)
### 
### objs:
### 	mkdir -p $@
### 
### libs:
### 	mkdir -p $@
### 
### $(OBJDIR)/%.o: %.c objs
### 	$(RV_GCC) $(SW_INCLUDES) -Werror -falign-functions=32 -falign-jumps=32 -c $< -o $@
### 
### #
### libs/libintegr.a: $(OBJS) libs
### 	$(RV_AR) -rcs $@ $(OBJS)
### 
### sw : libs/libintegr.a nb_cores
### 	for d in $(TESTLIST); do make -C $$d sw; done
### 
### sw_all : libs/libintegr.a nb_cores
### 	for d in $(TESTLIST); do make -C $$d all; done


# Run the test(s)

TEST ?= all

DEFINES := CULSANS_TB_UNIT_TEST

# run all the tests
ifeq ($(TEST), all)
all: rtl
	for d in $(TESTLIST); do make -C $$d all; done
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

# run all non-failing tests
pass: rtl
	for d in $(PASS_LIST); do make -C $$d all; done
	@$(MAKE) status

# run all failing tests
fail: rtl
	for d in $(FAIL_LIST); do make -C $$d all; done
	@$(MAKE) status

# run failed or not-executed tests
### rerun: sw rtl
rerun: rtl
	for d in $(TESTLIST); do \
		if [ -e $$d/$(TEST_REPORT) ]; then \
			if grep -q Error $$d/$(TEST_REPORT) ; then \
				make -C $$d all; \
			fi; \
		else \
			make -C $$d all; \
		fi; \
	done

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
clean_sw:
	rm -rf objs
	rm -rf libs

clean_tests:
	for d in $(TESTLIST); do make -C $$d clean; done

clean: clean_sw clean_rtl clean_tests

### .PHONY: all sw rerun clean clean_sw
.PHONY: all rerun clean clean_sw
