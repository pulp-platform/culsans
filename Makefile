VERILATE ?= 0
NB_CORES ?= 2

unit-tests:
	@$(MAKE) -C tests VERILATE=$(VERILATE) NB_CORES=$(NB_CORES) unit

regr-tests:
	@$(MAKE) -C tests VERILATE=$(VERILATE) NB_CORES=$(NB_CORES) regr

integration-tests:
	@$(MAKE) -C tests VERILATE=$(VERILATE) NB_CORES=$(NB_CORES) integration

test: regr-tests #integration-tests

sanity-tests:
	@$(MAKE) -C tests VERILATE=$(VERILATE) NB_CORES=$(NB_CORES) sanity

fpga:
	@$(MAKE) -C fpga all

sdk:
	@$(MAKE) -C cva6-sdk images

clean:
	@$(MAKE) -C fpga clean
	@$(MAKE) -C tests clean
	@$(MAKE) -C cva6-sdk clean-all

.PHONY : fpga test sanity-tests unit-tests regr-tests integration-tests sdk clean
