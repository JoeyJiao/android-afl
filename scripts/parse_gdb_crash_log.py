#!/usr/bin/env python3

import os
import re
import subprocess
import sys
import json

R1 = re.compile(r'#(\d+)\s+0x\S+ in (\S+)')
R2 = re.compile(r'#(\d+)\s+(\S+)')
R3 = re.compile(r'at\s(\S+):(\d+)$')

def main():
    if len(sys.argv) < 2:
        print('Usage:', sys.argv[0], '[gdb crash log]')
        exit(1)

    log = sys.argv[1]
    if os.path.isfile(log):
        parse(log)

def parse(log):
    TMP_LOG = '/tmp/gdb_parse_log'
    in_stack = False
    descr = None
    class_ = None
    stack = []
    fd = open(log, 'r')
    lines = fd.readlines()
    fd.close()
    fd = open(TMP_LOG, 'w+')
    output = []
    for line in lines:
        if descr is not None:
            if line.startswith('Exploitability Classification: '):
                class_ = line[31:].replace('\n', '')
                output.append("\x1b[1;36m{}\x1b[1;31m{}\x1b[m".format(descr, class_))
                if stack:
                    for num, func, file_, line_ in stack:
                        output.append("{:2d} {} ({}:{})".format(num, func, file_, line_))
                fd.write(json.dumps(output))
                fd.write('\n')
                output = []
                stack = []
        if in_stack:
            if line.startswith('(gdb) '):
                in_stack = False
                descr = line[6:]
            else:
                backtrace(line, stack)
        else:
            if line.startswith('(gdb) #'):
                in_stack = True
                backtrace(line[6:], stack)
    fd.close()

    for line in set(open(TMP_LOG).readlines()):
        line = json.loads(line)
        print('\n'.join(line))

    os.remove(TMP_LOG)

def backtrace(s, stack):
    num, func, file_, line = None, None, None, None
    m1 = re.match(R1, s)
    if m1 is not None:
        num, func = int(m1.group(1)), m1.group(2)
    else:
        m2 = re.match(R2, s)
        if m2 is not None:
            num, func = int(m2.group(1)), m2.group(2)
    m3 = re.search(R3, s)
    if m3 is not None:
        f, line = m3.group(1), int(m3.group(2))
        file_ = f
    if num is not None:
        stack.append([num, func, file_, line])
    else:
        stack[-1][2:4] = file_, line

if __name__ == '__main__':
    main()
