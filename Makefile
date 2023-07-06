VERILATE ?= 0
NB_CORES ?= 2

unit-tests:
	make -C tests VERILATE=$(VERILATE) NB_CORES=$(NB_CORES) unit

regr-tests:
	make -C tests VERILATE=$(VERILATE) NB_CORES=$(NB_CORES) regr

integration-tests:
	make -C tests VERILATE=$(VERILATE) NB_CORES=$(NB_CORES) integration

test: regr-tests #integration-tests

sanity-tests:
	make -C tests VERILATE=$(VERILATE) NB_CORES=$(NB_CORES) sanity

fpga:
	make -C fpga all

sdk:
	cd cva6-sdk/opensbi && git apply ../../patch/opensbi.patch
	cd cva6-sdk && git apply ../patch/cva6-sdk.patch
	make -C cva6-sdk images

clean:
	make -C fpga clean
	make -C tests clean
	make -C cva6-sdk clean-all

.PHONY : fpga test sanity-tests unit-tests regr-tests integration-tests sdk clean
