# include an additional script, which implements testcase-specific functions
set sim_extensions "sim_ext.tcl"
if { [file exists $sim_extensions] == 1} {
    source $sim_extensions
}

# if a local wave file is present, then use that. Otherwise use default.
set local_wave   "my_wave.do"
set default_wave "wave.do"

if { [file exists $local_wave] == 1} {
    source $local_wave
} elseif { [file exists $default_wave] == 1} {
    source $default_wave
}


# add checks and breakpoints
# ...

add log * -r

# set a timeout
run 30ms

quit
