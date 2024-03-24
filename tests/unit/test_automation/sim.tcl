# Copyright 2022 ETH Zurich and University of Bologna.
# Solderpad Hardware License, Version 0.51, see LICENSE for details.
# SPDX-License-Identifier: SHL-0.51

# include an additional script, which implements testcase-specific functions
set sim_extensions "sim_ext.tcl"
if { [file exists $sim_extensions] == 1} {
    source $sim_extensions
}

# if a local wave file is present, then use that. Otherwise use default.
set local_wave   "my_wave.do"
set default_wave "wave.do"

if { [file exists $local_wave] == 1} {
    do $local_wave
} elseif { [file exists $default_wave] == 1} {
    do $default_wave
}


# add checks and breakpoints
# ...

add log * -r
