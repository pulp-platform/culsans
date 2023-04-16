import yaml
from pathlib import Path
from colorama import Fore, Back, Style

class ACE:

    # constructor function    
    def __init__(self, time_stamp,address,  snoop, rwtype, srcline):
        self.time_stamp = time_stamp
        self.address = address
        self.snoop = snoop
        self.rwtype = rwtype
        self.srcline = srcline

class AXI:

    # constructor function    
    def __init__(self, time_stamp,address, rwtype,srcline):
        self.time_stamp = time_stamp
        self.address = address
        self.rwtype = rwtype
        self.srcline = srcline

class SNOOP:

    # constructor function    
    def __init__(self, time_stamp,address, crresp, msgtype, srcline):
        self.time_stamp = time_stamp
        self.address = address
        self.crresp = crresp
        self.msgtype = msgtype
        self.srcline = srcline

class DATA_BUFFER_ACCESS:

    def __init__(self, address, min_address, max_address):
        self.address = address
        self.min_address = min_address
        self.max_address = max_address

class ACE_LIST_CHECKER:

    def __init__(self, theList,theDict, rw):
        self.theList = theList
        self.theDict = theDict
        self.rw = rw
 

    def checker (self, group_index, message_index):
        message_found = False
        snoop_search = self.theDict[test_yaml['test']['groups'][i]['messages'][j][self.rw]]
        for l in range(0,len(self.theList)):         
            if self.theList[l].address == search_address and self.theList[l].snoop == snoop_search :
                log_file.write(self.theList[l].srcline)
                del self.theList[l]
                message_found = True
                break
        if message_found == True:
            return True
        else:
            return False

    def isListEmpty(self):
        isEmpty = False
        if len(self.theList) == 0:
            isEmpty = True
        else:
            isEmpty = False

        return isEmpty         


class AXI_LIST_CHECKER:

    def __init__(self, theList, rw):
        self.theList = theList
        self.rw = rw
 

    def checker (self, group_index, message_index):
        message_found = False
        for l in range(0,len(self.theList)):         
            if self.theList[l].address == search_address :
                log_file.write(self.theList[l].srcline)
                del self.theList[l]
                message_found = True
                break
        if message_found == True:
            return True
        else:
            return False
        
    def isListEmpty(self):
        isEmpty = False
        if len(self.theList) == 0:
            isEmpty = True
        else:
            isEmpty = False

        return isEmpty 

class ACE_S_LIST_CHECKER:

    def __init__(self, theList,theDict):
        self.theList = theList
        self.theDict = theDict


    def checker (self, group_index, message_index):
        message_found = False
        crresp_search = test_yaml['test']['groups'][i]['messages'][j]['CRRESP']
        for l in range(0,len(self.theList)):
            if l <= len(self.theList) - 1:
                if self.theList[l].address == search_address:
                    log_file.write(self.theList[l].srcline)
                    del self.theList[l]
                    if len(self.theList) != 0:
                        if self.theList[l].crresp == crresp_search :
                            log_file.write("\t\t" + self.theList[l].srcline)
                            del self.theList[l]
                            message_found = True
                            break
                        else:
                            break        

        if message_found == True:
            return True
        else:
            return False

    def isListEmpty(self):
        isEmpty = False
        if len(self.theList) == 0:
            isEmpty = True
        else:
            isEmpty = False

        return isEmpty          
       
def getIndexLists():
   indexes = []
   buffer_access_dict[test_yaml['test']['test_buffer']] = []
   groups = test_yaml['test']['groups']
   for i in range(0,len(test_yaml['test']['groups'])):
       if "test_buffer" in test_yaml['test']['groups'][i]:
          #print(test_yaml['test']['groups'][i])
          #print(buffer_access_dict.keys())
          #print(test_yaml['test']['groups'][i]['test_buffer'])
          if test_yaml['test']['groups'][i]['test_buffer'] not in buffer_access_dict:
              buffer_access_dict[test_yaml['test']['groups'][i]['test_buffer']] = []                      
          buffer_access_dict[test_yaml['test']['groups'][i]['test_buffer']].append(groups[i]['start_index']);
          buffer_access_dict[test_yaml['test']['groups'][i]['test_buffer']].append(groups[i]['end_index']);
       else:
          buffer_access_dict[test_yaml['test']['test_buffer']].append(groups[i]['start_index'])
          buffer_access_dict[test_yaml['test']['test_buffer']].append(groups[i]['end_index']);
   for buffer, list in buffer_access_dict.items():
        for line in Lines:
            split_line = line.split()
            if len(split_line) > 1:
               if split_line[1] == buffer:
                   buffer_address = int(split_line[0],16)
                   min_index = min(list)*16 + buffer_address
                   max_index = max(list)*16 + buffer_address
        dba = DATA_BUFFER_ACCESS(buffer_address, min_index, max_index)
        buffer_address_list.append(dba)
   return buffer_address_list[0].address



def tr_ace(file_lines, transactions, snoop, rw):
    for line in file_lines:
        if  snoop in line:
            split_line = line.split()
            #print(split_line)
            for addr in  buffer_address_list:
                #print("here")
                #print(addr.min_address)
                #print(addr.max_address)
                if int(split_line[7],16) >= addr.min_address and int(split_line[7],16) <= addr.max_address:
                    if (int(split_line[7],16) & 15) == 0:
                        timestamp = split_line[0].strip('>')
                        snoopstrip = snoop + ':'
                        if snoop == 'ARSNOOP':
                            snoop_index = 10
                        if snoop == 'AWSNOOP':
                            snoop_index = 12
                        snoopstripped = split_line[snoop_index].strip(snoopstrip).strip(',')
                        tr = ACE(timestamp,int(split_line[7],16), int(snoopstripped,2) ,rw , line)
                        transactions.append(tr)

def tr_axi(file_lines, transactions, identifier,  rw):
    for line in file_lines:
        if  identifier in line:
            split_line = line.split()
            #print(split_line)
            list_address_index = 7
            for addr in  buffer_address_list:
                if int(split_line[list_address_index ],16) >= addr.min_address and int(split_line[ list_address_index ],16) <= addr.max_address:
                    if (int(split_line[list_address_index ],16) & 15) == 0:                     
                        timestamp = split_line[0].strip('>')
                        tr = AXI(timestamp,int(split_line[7],16) ,rw, line )
                        transactions.append(tr)

def tr_snoop(file_lines, transactions):
    snoop_in_line = False
    for line in file_lines:
        split_line = line.split()
        #print(split_line)
        if  snoop_in_line is True and 'RESP' in line:
              timestamp = split_line[0].strip('>')
              crresp_stripped = split_line[len(split_line) - 1].strip(',')
              crresp = int(crresp_stripped,2)
              tr = SNOOP(timestamp, 2023, crresp, 0, line)
              transactions.append(tr)
        snoop_in_line = False
        if  'SNOOP' in line:
            list_address_index = 3
            for addr in  buffer_address_list:
                if int(split_line[list_address_index ],16) >= addr.min_address and int(split_line[ list_address_index ],16) <= addr.max_address:
                    timestamp = split_line[0].strip('>')
                    snoop_in_line = True
                    tr = SNOOP(timestamp, int(split_line[list_address_index ],16), 7777, 1, line)
                    transactions.append(tr)
              
def get_and_filter_data():
   file_list = []
   for i in range(0,4):
       del file_list[:]
       for p in Path( 'ace_log/ccu_logger_master_'+ str(i) +'/' ).glob( '**/read*.log' ):
           file_list.append(str(p))
       filenames_dict['ace_log/ccu_logger_master_'+ str(i) +'/read'] = file_list.copy()
       del file_list [:]
       for p in Path( 'ace_log/ccu_logger_master_'+ str(i) +'/' ).glob( '**/write.log' ):
           file_list.append( str(p) )
       filenames_dict['ace_log/ccu_logger_master_'+ str(i) +'/write'] = file_list.copy()
       del file_list [:]
       for p in Path( 'ace_log/ccu_logger_snoop_'+ str(i) +'/' ).glob( '**/snoop_read.log' ):
           file_list.append( str(p) )
       filenames_dict['ace_log/ccu_logger_snoop_'+ str(i) +'/snoop_read'] = file_list.copy()
   del file_list[:]
   for p in Path( 'axi_log/ccu_logger_slave/' ).glob( '**/read*.log' ):
       file_list.append(str(p))
   filenames_dict['axi_log/ccu_logger_slave/read'] = file_list.copy()
   del file_list[:]   
   for p in Path( 'axi_log/ccu_logger_slave/' ).glob( '**/write.log' ):
        file_list.append(str(p))
   filenames_dict['axi_log/ccu_logger_slave/write'] = file_list.copy()

   for i in filenames_dict['ace_log/ccu_logger_master_0/read']:
       file1 = open(i, 'r')
       Lines = file1.readlines()
       tr_ace(Lines,ace_master_0_read, 'ARSNOOP', 'read')
   for i in filenames_dict['ace_log/ccu_logger_master_1/read']:
       file1 = open(i, 'r')
       Lines = file1.readlines()
       tr_ace(Lines,ace_master_1_read, 'ARSNOOP', 'read')    
   for i in filenames_dict['ace_log/ccu_logger_master_2/read']:
       file1 = open(i, 'r')
       Lines = file1.readlines()
       tr_ace(Lines,ace_master_2_read, 'ARSNOOP', 'read')  
   for i in filenames_dict['ace_log/ccu_logger_master_3/read']:
       file1 = open(i, 'r')
       Lines = file1.readlines()
       tr_ace(Lines,ace_master_3_read, 'ARSNOOP', 'read')      
   for i in filenames_dict['ace_log/ccu_logger_master_0/write']:
       file1 = open(i, 'r')
       Lines = file1.readlines()
       tr_ace(Lines,ace_master_0_write, 'AWSNOOP', 'write')      
   for i in filenames_dict['ace_log/ccu_logger_master_1/write']:
       file1 = open(i, 'r')
       Lines = file1.readlines()
       tr_ace(Lines,ace_master_1_write, 'AWSNOOP', 'write')      
   for i in filenames_dict['ace_log/ccu_logger_master_2/write']:
       file1 = open(i, 'r')
       Lines = file1.readlines()
       tr_ace(Lines,ace_master_2_write, 'AWSNOOP', 'write')    
   for i in filenames_dict['ace_log/ccu_logger_master_3/write']:
       file1 = open(i, 'r')
       Lines = file1.readlines()
       tr_ace(Lines,ace_master_3_write, 'AWSNOOP', 'write')       
   for i in filenames_dict['ace_log/ccu_logger_snoop_0/snoop_read']:
       file1 = open(i, 'r')
       Lines = file1.readlines()
       tr_snoop(Lines,  ace_master_0_snoop)     
   for i in filenames_dict['ace_log/ccu_logger_snoop_1/snoop_read']:
       file1 = open(i, 'r')
       Lines = file1.readlines()
       tr_snoop(Lines,  ace_master_1_snoop)      
   for i in filenames_dict['ace_log/ccu_logger_snoop_2/snoop_read']:
       file1 = open(i, 'r')
       Lines = file1.readlines()
       tr_snoop(Lines,  ace_master_2_snoop)    
   for i in filenames_dict['ace_log/ccu_logger_snoop_3/snoop_read']:
       file1 = open(i, 'r')
       Lines = file1.readlines()
       tr_snoop(Lines,  ace_master_3_snoop)       
   for i in filenames_dict['axi_log/ccu_logger_slave/read']:
       file1 = open(i, 'r')
       Lines = file1.readlines()
       tr_axi(Lines,   axi_slave_read , 'AR',  'read')        
   for i in filenames_dict['axi_log/ccu_logger_slave/write']:
       file1 = open(i, 'r')
       Lines = file1.readlines()
       tr_axi(Lines,   axi_slave_write , 'AW',  'write')

def print_warnings():
    for i in range(0,5):
        log_file.write( "WARNING !! CRRESP bits checked as a 5 bit word. Not individually checked !!! \n")
        log_file.write("WARNING !! TB only supports cacheline aligned accesses !!! \n")
        log_file.write("WARNING !! TB ignores addressses in files not specified in Yaml via start/end indexso if Yaml does not include all addresses, it will still flag it as pass !!! \n")

def are_there_any_extra_messages():

  
    is_there_extra_messages = False;
    log_file.write("Checking for extra messages \n")
    for theName, theObject in list_checker_dict.items():
        log_file.write(theName + "\n")
        if theObject.isListEmpty() != True:
            log_file.write(theName + " has extra messages \n" )
            is_there_extra_messages = True


    return is_there_extra_messages        

    

if __name__ == "__main__":
   buffer_access_dict = {}
   filenames_dict = {}
   #arsnoop dictionary defs from from IHI0022H_c_amba_axi_protocol_spec.pdf table D3.7
   arsnoop_dict = {'ReadNoSnoop':0,'ReadOnce':0,'ReadShared':1,'ReadClean':1,'ReadNotSharedDirty':3,'ReadUnique':7,'CleanUnique':11,'CleanShared':8,'CleanInvalid':9,'MakeInvalid':13}
   #awsnoop dictionary defs from from IHI0022H_c_amba_axi_protocol_spec.pdf table D3.8
   awsnoop_dict = {'WriteNoSnoop':0,'WriteUnique':0,'WriteLineUnique':1,'WriteClean':2,'WriteBack':3,'Evict':4,'WriteEvict':5}
   #acsnoop dictionary defs from from IHI0022H_c_amba_axi_protocol_spec.pdf table D3.19
   acsnoop_dict = {'ReadOnce':0,'ReadShared':1,'ReadClean':2,'ReadNotSharedDirty':3,'ReadUnique':7,'CleanShared':8,'CleanInvalid':5}   
   ace_master_0_read = []   
   ace_master_1_read = []
   ace_master_2_read = []
   ace_master_3_read = []
   ace_master_0_write  = []
   ace_master_1_write  = []
   ace_master_2_write  = []
   ace_master_3_write  = []
   ace_master_0_snoop = []
   ace_master_1_snoop  = []
   ace_master_2_snoop  = []
   ace_master_3_snoop = []
   axi_slave_read  = []
   axi_slave_write  = []
   buffer_address_list = []
  

   print(Style.RESET_ALL)
 
   with open('test.yaml', 'r') as file:
       test_yaml = yaml.safe_load(file)
       print("Test: " + test_yaml['test']['test_name'])
       #print(test_yaml['test']['test_buffer'])
       #print(test_yaml['test'])
       
   file1 = open('main.map', 'r')
   log_file = open(test_yaml['test']['test_name'] + "test_result.log", 'w')
   Lines = file1.readlines()       

   if "test_action" in test_yaml['test']:
       if test_yaml['test']['test_action'] == "skip":
          print(Fore.YELLOW + "Test Skipped")
          if "test_notes" in test_yaml['test']:
              print(Fore.YELLOW + test_yaml['test']['test_notes'])
              log_file.write(test_yaml['test']['test_notes'])
              log_file.close()
              file1.close()
          print(Style.RESET_ALL)
          exit(0)
       


   list_checker_dict = {}
   RACE = ACE_LIST_CHECKER(ace_master_0_read,  arsnoop_dict, 'ARSNOOP')
   list_checker_dict['ace_master_read_0'] = RACE
   RACE = ACE_LIST_CHECKER(ace_master_1_read,  arsnoop_dict, 'ARSNOOP')
   list_checker_dict['ace_master_read_1'] = RACE
   RACE = ACE_LIST_CHECKER(ace_master_2_read,  arsnoop_dict, 'ARSNOOP')
   list_checker_dict['ace_master_read_2'] = RACE
   RACE = ACE_LIST_CHECKER(ace_master_3_read,  arsnoop_dict, 'ARSNOOP')
   list_checker_dict['ace_master_read_3'] = RACE
   WACE = ACE_LIST_CHECKER(ace_master_0_write,  awsnoop_dict, 'AWSNOOP')
   list_checker_dict['ace_master_write_0'] = WACE
   WACE = ACE_LIST_CHECKER(ace_master_1_write,  awsnoop_dict, 'AWSNOOP')
   list_checker_dict['ace_master_write_1'] = WACE
   WACE = ACE_LIST_CHECKER(ace_master_2_write,  awsnoop_dict, 'AWSNOOP')
   list_checker_dict['ace_master_write_2'] = WACE
   WACE = ACE_LIST_CHECKER(ace_master_3_write,  awsnoop_dict, 'AWSNOOP')
   list_checker_dict['ace_master_write_3'] = WACE
   RAXI = AXI_LIST_CHECKER(axi_slave_read,   'READ')
   list_checker_dict['axi_master_read'] = RAXI
   WAXI = AXI_LIST_CHECKER(axi_slave_write,   'WRITE')
   list_checker_dict['axi_master_write'] = WAXI
   SACE = ACE_S_LIST_CHECKER(ace_master_0_snoop,  acsnoop_dict)
   list_checker_dict['ace_master_snoop_0'] = SACE   
   SACE = ACE_S_LIST_CHECKER(ace_master_1_snoop,  acsnoop_dict)
   list_checker_dict['ace_master_snoop_1'] = SACE
   SACE = ACE_S_LIST_CHECKER(ace_master_2_snoop,  acsnoop_dict)
   list_checker_dict['ace_master_snoop_2'] = SACE   
   SACE = ACE_S_LIST_CHECKER(ace_master_3_snoop,  acsnoop_dict)
   list_checker_dict['ace_master_snoop_3'] = SACE

   
   test_buffer_address = getIndexLists()
   get_and_filter_data()

   
   early_exit = False
   for i in range(0, len(test_yaml['test']['groups'])):
       if early_exit == True:
               break
       for k in range(int(test_yaml['test']['groups'][i]['start_index']),int(test_yaml['test']['groups'][i]['end_index']) + 1):
           if "test_buffer" in test_yaml['test']['groups'][i]:
               for line in Lines:
                  split_line = line.split()
                  if len(split_line) > 1:
                     if split_line[1] == test_yaml['test']['groups'][i]['test_buffer']:
                        new_address = int(split_line[0],16)
                        search_address = new_address + k*16
           else:
               search_address = test_buffer_address + k*16
           log_file.write( "Checking Group " + str(i) + "\n")
           if early_exit == True:
               break
           for j in range(0,len( test_yaml['test']['groups'][i]['messages'])):
               #print(Style.RESET_ALL)
               log_file.write("\t" +test_yaml['test']['groups'][i]['messages'][j]['log'] + "\t")
               message_found = False
               message_found = list_checker_dict[ test_yaml['test']['groups'][i]['messages'][j]['log']].checker(i,j)                                
               if message_found == False:
                   print(Fore.RED + "Expected  message " + test_yaml['test']['groups'][i]['messages'][j]['log'] + " " +str(j) + " of group " + str(i) + " not found")
                   print(Fore.RED + "at address " + str(hex(search_address)))
                   for i in range(0, len(test_yaml['test']['groups'])):
                      print("next group ")
                      print(test_yaml['test']['groups'][i])
                   early_exit = True
                   break              


                    
   extra_messages = are_there_any_extra_messages()
   #extra_messages = False
   if early_exit == True or extra_messages == True:
      print(Fore.RED + "Test FAILED !! \n")
      log_file.write("Test FAILED !! \n")
      if "test_notes" in test_yaml['test']:
           print(Fore.YELLOW + test_yaml['test']['test_notes'])
           log_file.write(test_yaml['test']['test_notes'])           
   else:
      print(Fore.GREEN + "Test PASSED !! \n ")
      log_file.write("Test PASSED !! \n")
   #print(filenames_dict)
   print_warnings() 
   #print(filenames_dict['ace_log/ccu_logger_master_0/read'])

   log_file.close()
   file1.close()
   print(Style.RESET_ALL)
   for tr in ace_master_2_read:
       print(tr.address)
       print(tr.time_stamp)
       print(tr.snoop)
       print(tr.rwtype)
       print(tr.srcline)

'''
   print("snoop 0")
   for tr in ace_master_0_snoop:
       print(tr.address)
       print(tr.time_stamp)
       print(tr.crresp)
       print(tr.msgtype)
       print(tr.srcline)
        
   print("snoop 1")
   for tr in ace_master_1_snoop:
       print(tr.address)
       print(tr.time_stamp)
       print(tr.crresp)
       print(tr.msgtype)
       print(tr.srcline)     
  



       
   print("The buffer " + test_yaml['test']['test_buffer'] + " " + str(hex(test_buffer_address)))
   print(str(hex(start_address)) + " " + str(hex(end_address)))
   for tr in ace_master_0_read:
       print(tr.address)
       print(tr.time_stamp)
       print(tr.snoop)
       print(tr.rwtype)
       print(tr.srcline)

   for tr in ace_master_0_write:
       print(tr.address)
       print(tr.time_stamp)
       print(tr.snoop)
       print(tr.rwtype)
       print(tr.srcline)       




   for tr in axi_slave_write:
       print(tr.address)
       print(tr.time_stamp)
       print(tr.rwtype)
       print(tr.srcline)

        
'''

    

