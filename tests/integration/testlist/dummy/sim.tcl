# include an additional script, which implements testcase-specific functions
set sim_extensions "sim_ext.tcl"
if { [file exists $sim_extensions] == 1} {               
    source sim_extensions
}

# add checks and breakpoints
# ...

# set a timeout
run 10ms

quit