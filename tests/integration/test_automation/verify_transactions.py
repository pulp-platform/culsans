#!/usr/bin/python

import subprocess

#if __name__ == "__main__":
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

look_for_logs = subprocess.check_output(['grep', '-rnwe', address, '--exclude=trace_hart_*', '--exclude=main.map'])
look_for_logs = look_for_logs.splitlines()
for line in look_for_logs:
    print(line)
