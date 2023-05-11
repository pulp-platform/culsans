# include an additional script, which implements testcase-specific functions
set sim_extensions "sim_ext.tcl"
if { [file exists $sim_extensions] == 1} {
    source $sim_extensions
}

set wave "wave.do"
if { [file exists $wave] == 1} {
    source $wave
}

# add checks and breakpoints
# ...

add log * -r

# set a timeout
run 30ms

quit
