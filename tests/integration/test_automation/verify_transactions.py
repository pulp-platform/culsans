#!/usr/bin/python

import subprocess
import re
    
non_cached_non_shared_beginning = int("0x80000000", 16)
non_cached_non_shared_end = int("0x8001ffff", 16)
non_cached_shared_beginning = int("0x80020000", 16)
non_cached_shared_end = int("0x8002ffff", 16)
cached_shared_beginning = int("0x80030000", 16)
cached_shared_end = int("0x8003ffff", 16)
cached_non_shared_beginning = int("0x80040000", 16)
    
address_increment = "0x10"

result = ""

number_of_variables = 1
data_restriction = ""
expected_outcome = []

f = open("verify_truth.txt", "r")
load = 0
for line in f:
    if ":" in line:
        if ":iteration" in line:
            load = 1
        if ":data" in line:
            load = 2
        if ":expected" in line:
            load = 3
    else:
        if load == 1:
            number_of_variables = int(line)
            print(number_of_variables)
        if load == 2:
            data_restriction = line.strip()
            print(data_restriction)
        if load == 3:
            if line.strip() != '':
                expected_outcome.append(line.strip())
f.close()
print(expected_outcome)
    
if number_of_variables > 0:
    
    #if __name__ == "__main__":
    # look for the address in main.map
    # grep -rnwe 'data'
    look_for_data_address = subprocess.check_output(['grep', '-rnwe', ' data', '--include=main.map'])
    look_for_data_address = look_for_data_address.splitlines()

    start_address = ""
    for line in look_for_data_address:
        L = line.split(":")
        if L[0] == "main.map":
            chunks = L[2].split(" ")
            for item in chunks:
                if "0x" in item:
                    start_address = item
                    break
            break
    print(start_address)
    
    restrictions_passed = False
    # check restriction on the start address
    if "nocache_noshare" == data_restriction:
        if int(start_address,16) >= non_cached_non_shared_beginning and int(start_address,16) <= non_cached_non_shared_end:
            restrictions_passed = True
        else:
            print("data restriction check failed nocache_noshare")
    if "nocache_share" == data_restriction:
        if int(start_address,16) >= non_cached_shared_beginning and int(start_address,16) <= non_cached_shared_end:
            restrictions_passed = True 
        else:
            print("data restriction check failed nocache_share")
    if "cache_share" == data_restriction:
        if int(start_address,16) >= cached_shared_beginning and int(start_address,16) <= cached_shared_end:
            restrictions_passed = True
        else:
            print("data restriction check failed cache_share")
    if "cache_noshare" == data_restriction:
        if int(start_address,16) >= cached_non_shared_beginning:
            restrictions_passed = True
        else:
            print("data restriction check failed cache_noshare")
    print(restrictions_passed)
    if restrictions_passed:
    
        for iterator in range (0, number_of_variables):
        
            address =  int(start_address,16) + iterator * int(address_increment,16) 
            address = "{0:#0{1}x}".format(address,18)
            print(address)
        
            # look for the mention of the address in the logs
            look_for_logs = subprocess.check_output(['grep', '-rnwe', address, '--exclude=trace_hart_*', '--exclude=main.map', '--exclude=*snoop*'])
            look_for_logs = look_for_logs.splitlines()
            log_entry = []
            for line in look_for_logs:
                L = re.split(' |-|>|:', line)
                L = list(filter(None, L))
                if 'master' in L[0]:
                    if 'read' in L[0]:
                        L[0] = 'master_read'
                    if 'write' in L[0]:
                        L[0] = 'master_write'
                if 'slave' in L[0]:
                    if 'read' in L[0]:
                        L[0] = 'slave_read'
                    if 'write' in L[0]:
                        L[0] = 'slave_write'
                if 'snoop' in L[0]:
                    if 'read' in L[0]:
                        L[0] = 'snoop_read'
                    if 'write' in L[0]:
                        L[0] = 'snoop_write'
                log_entry.append(L)
                
            # look for the mention of the address in the logs
            look_for_logs = subprocess.check_output(['grep', '-rnwe', address, '--include=*snoop*', '--after-context=10'])
            look_for_logs = look_for_logs.splitlines()
            for line in look_for_logs:

                if 'ADDR:' in line and address not in line:
                    break
                #print(L)
                L = re.split(' |-|>|:', line)
                #print(L)
                L = list(filter(None, L))
                if 'master' in L[0]:
                    if 'read' in L[0]:
                        L[0] = 'master_read'
                    if 'write' in L[0]:
                        L[0] = 'master_write'
                if 'slave' in L[0]:
                    if 'read' in L[0]:
                        L[0] = 'slave_read'
                    if 'write' in L[0]:
                        L[0] = 'slave_write'
                if 'snoop' in L[0]:
                    if 'read' in L[0]:
                        L[0] = 'snoop_read'
                    if 'write' in L[0]:
                        L[0] = 'snoop_write'
                log_entry.append(L)
                #print(L)
                
            # sort the logs by simulation time
            #for entry in log_entry:
            #    print(entry)
            log_entry.sort(key = lambda x: (int(x[2]), x[0]) )
            for entry in log_entry:
                print(entry)
                
            # every transaction is 2~4 lines
            # address, (snoop), first half, [second half]
            # plus the same number of rows for the reply
            
            expected_outcome_copy = list(expected_outcome)
            
            while len(expected_outcome_copy) > 0 and len(log_entry) > 0:
                #for entry in log_entry:
                #    print(entry)
                if expected_outcome_copy[0] == "write":
                    if "write" in log_entry[0][0]:
                        result = "PASS"
                        while len(log_entry) > 0 and "write" in log_entry[0][0]:
                            del log_entry[0]
                        del expected_outcome_copy[0]
                        continue
                    else:
                        result = "FAIL"
                        print("fail 1")
                        break
                if expected_outcome_copy[0] == "read_snoop_slave":
                    if "read" in log_entry[0][0] and "snoop" in log_entry[1][0]:
                        result = "PASS"
                        while len(log_entry) > 0 and ("read" in log_entry[0][0] or "snoop" in log_entry[0][0]):
                            del log_entry[0]
                        del expected_outcome_copy[0]
                        continue
                    else:
                        result = "FAIL"
                        print("fail 2")
                        break
                if expected_outcome_copy[0] == "read_slave":
                    if "read" in log_entry[0][0]:
                        result = "PASS"
                        while len(log_entry) > 0 and "read" in log_entry[0][0]:
                            del log_entry[0]
                        del expected_outcome_copy[0]
                        continue
                    else:
                        result = "FAIL"
                        print("fail 3")
                        break
                        
            if len(expected_outcome_copy) != 0 or len(log_entry) != 0:
                result = "FAIL"
                print("fail 4")
                print(expected_outcome_copy)
                print(log_entry)
                
            # if the test already failed, there is no need to check subsequent memory addresses    
            if result == "FAIL":
                break
            
    else:
        result = "FAIL"
        print("fail 5")

else: # number of iteration was set to 0, means nothing to check. write pass
    result = "PASS"
    
f = open("verification_result.txt", "w")
f.write(result)
f.close()

