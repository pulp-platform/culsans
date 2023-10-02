ROOT_DIR := $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
TESTNAME := $(notdir $(patsubst %/,%,$(ROOT_DIR)))
include ../../test_automation/Makefile
