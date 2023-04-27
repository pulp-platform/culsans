import os
import re

infile = './litmus_src/model-results/herd.logs'
outdir = './results'
outfile = outdir + '/herd_exp.logs'

with open(infile) as fi:
    with open(outfile, 'w') as fo:
        startPattern = re.compile('Test\s+(.+)\s+Allowed')
        endPattern = re.compile('Hash=(.)+')
        copy = False
        for line in fi:
            m = startPattern.match(line)
            if m != None:
                test = m.group(1)
                if os.path.isfile(outdir + '/' + test + '.log'):
                    copy = True
            if copy:
                fo.write(line)
            m = endPattern.match(line)
            if m != None:
                copy = False
                fo.write('')
        fo.close()
    fi.close()
