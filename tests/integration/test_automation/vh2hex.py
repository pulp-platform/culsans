#!/usr/bin/python

import os.path
import getopt
import sys
import re

################################################################

def usage():
    print 'This script reads a memory file written in verilog format and translates it to hexfile.'
    print 'The first word copied to the output is the one at the address specified with -b (0 by default).'
    print 'Usage: '+sys.argv[0]+' [-m  <verilog_memfile>] [-o  <hexfile>] [-b <baseaddress>] [-i <instructions_baseaddress>] [-d <data_baseaddress>] [-w <4/8>[-h]'
    print '-m: verilog memfile'
    print '-o: output hexfile'
    print '-b: first address copied to hexfile'
    print '-i: first address copied to the instructions hexfile'
    print '-d: first address copied to the data hexfile'
    print '-w: word size (4 or 8 bytes)'
    print '-h: this help'

################################################################

# to match groups
class REMatcher(object):
    def __init__(self, matchstring):
        self.matchstring = matchstring

    def match(self,regexp):
        self.rematch = re.match(regexp, self.matchstring)
        return bool(self.rematch)

    def group(self,i):
        return self.rematch.group(i)

################################################################

def isValidAddr(addr, baseAddr, endAddr):
    if addr >= baseAddr and addr <= endAddr:
        return True
    else:
        return False

################################################################

def writeWord(fd, word, wordLength):
    if wordLength == 8:
        fd.write(format(word, '016x')+'\n')     
    else:
        fd.write(format(word, '08x')+'\n')

################################################################
def extractHex(vhFile, hexFile, baseAddr, endAddr, wordLength):

    if not os.path.isfile(vhFile):
        assert False, vhFile + " doesn't exist"

    fi = open(vhFile, 'r+')
    fo = open(hexFile, 'w')

    addr = 0
    currentAddr = baseAddr
    byteCnt = 0
    word = 0
    for line in fi:
        m = REMatcher(line)
        # address
        if m.match('^@([0-9a-fA-F]+)'):
            addr = int(m.group(1), 16)
            #add padding
            if isValidAddr(addr, baseAddr, endAddr):
                #print str(hex(addr))+" "+str(hex(baseAddr))+" "+str(hex(endAddr))+" "+str(hex(currentAddr))
                #print "add padding"+str(addr)
                for i in range(0, (addr-currentAddr)):
                    word += 0 << (byteCnt*8)
                    byteCnt += 1
                    if byteCnt == wordLength:
                        #print format(word, '016x')
                        writeWord(fo, word, wordLength)
                        byteCnt = 0
                        word = 0
                currentAddr = addr
        elif m.match('^(([0-9a-fA-F]{2} )+)'):
            for s in line.split():
                #print s
                addr += 1
                if isValidAddr(addr, currentAddr, endAddr):
                    word += int(s, 16) << (byteCnt*8)
                    byteCnt += 1
                    if byteCnt == wordLength:
                        #print format(word, '016x')
                        #fo.write(str(hex(addr-8))+' '+format(word, '016x')+'\n')
                        writeWord(fo, word, wordLength)
                        byteCnt = 0
                        word = 0
#            if byteCnt != 0:
#                #print format(word, '016x')
#                if isValidAddr(addr, currentAddr, endAddr):
#                    #fo.write(str(hex(addr-8))+' '+format(word, '016x')+'\n')
#                    writeWord(fo, word, wordLength)
#                    byteCnt = 0
#                    word = 0
            if isValidAddr(addr, currentAddr, endAddr):
                currentAddr = addr

    if byteCnt != 0:
        #print format(word, '016x')
        #if isValidAddr(addr, currentAddr, endAddr):
            #fo.write(str(hex(addr-8))+' '+format(word, '016x')+'\n')
        writeWord(fo, word, wordLength)

    fi.close()
    fo.close()


################################################################

def main():

    vhFile = "main.vh"
    hexFile = "main.hex"
    baseAddr = 0x0
    baseAddrDefined = False
    instrBaseAddr = 0x0
    instrBaseAddrDefined = False
    dataBaseAddr = 0x0
    dataBaseAddrDefined = False
    wordLength = 8

    try:
        opts, args = getopt.getopt(sys.argv[1:], "m:o:b:i:d:w:h")
    except getopt.GetoptError as err:
        # print help information and exit:
        print str(err)
        usage()
        sys.exit(2)
    for o, a in opts:
        if o in ("-m"):
            vhFile = a
        elif o in ("-o"):
            hexFile = a
        elif o in ("-b"):
            baseAddr = int(a, 0)
            baseAddrDefined = True
        elif o in ("-i"):
            instrBaseAddr = int(a, 0)
            instrBaseAddrDefined = True
        elif o in ("-d"):
            dataBaseAddr = int(a, 0)
            instrDataAddrDefined = True
        elif o in ("-w"):
            wordLength = int(a, 0)
        elif o in ("-h"):
            usage()
            sys.exit()
        else:
            assert False, "unhandled option"

    assert wordLength == 4 or wordLength == 8, 'w should be 4 or 8'

    hexFile = hexFile
    hexInstrFile = hexFile.replace(".hex", "_instr.hex")
    hexDataFile = hexFile.replace(".hex", "_data.hex")

    if baseAddrDefined:
        extractHex(vhFile, hexFile, baseAddr, 0xFFFFFFFF, wordLength)

    if instrBaseAddrDefined or dataBaseAddrDefined:
        if instrBaseAddr < dataBaseAddr:
            extractHex(vhFile, hexInstrFile, instrBaseAddr, dataBaseAddr-1, wordLength)
            extractHex(vhFile, hexDataFile, dataBaseAddr, 0xFFFFFFFF, 8)
        else:
            extractHex(vhFile, hexInstrFile, instrBaseAddr, 0xFFFFFFFF, wordLength)
            extractHex(vhFile, hexDataFile, dataBaseAddr, instrBaseAddr-1, 8)

################################################################

if __name__ == "__main__":
    main()
