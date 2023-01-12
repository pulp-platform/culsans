#!/usr/bin/python

import subprocess
import re
    
#if __name__ == "__main__":
# look for the address in main.map
# grep -rnwe 'data'
look_for_data_address = subprocess.check_output(['grep', '-rnwe', ' data'])
look_for_data_address = look_for_data_address.splitlines()

address = ""
for line in look_for_data_address:
    L = line.split(":")
    if L[0] == "main.map":
        address = L[2].split(" ")
        for item in address:
            if "0x" in item:
                address = item
                break
        break
print(address)

# look for the mention of the address in the logs
look_for_logs = subprocess.check_output(['grep', '-rnwe', address, '--exclude=trace_hart_*', '--exclude=main.map'])
look_for_logs = look_for_logs.splitlines()
log_entry = []
for line in look_for_logs:
    L = re.split(' |> |:', line)
    L = list(filter(None, L))
    log_entry.append(L)
    
# sort the logs by simulation time
log_entry.sort(key = lambda x: int(x[2]))
for entry in log_entry:
    print(entry)
    

