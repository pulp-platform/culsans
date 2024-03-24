# Copyright 2022 ETH Zurich and University of Bologna.
# Solderpad Hardware License, Version 0.51, see LICENSE for details.
# SPDX-License-Identifier: SHL-0.51

for t in ../integration/testlist/cva6-litmus/binaries/*.hex
do
    rm main.hex 2> /dev/null
    rm uart.log 2> /dev/null
    ln -s $t main.hex
    vsim -c -voptargs=+acc -t 1ns -64 -do test_automation/sim.tcl -suppress 12110 -lib work culsans_tb
    OUTFILE=`basename $t .hex`.log
    cp uart.log $OUTFILE
    exit
done
