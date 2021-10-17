#!/usr/bin/env python3
import sys
import subprocess

binfile = sys.argv[1]
elffile = sys.argv[2]
status, output = subprocess.getstatusoutput("riscv32-unknown-elf-readelf -S " + elffile + " | grep ' \\.bss ' | awk '{print $6}'");
try:
    bss_length = int(output, base=16)
except ValueError:
    print('BSS not found!')
    sys.exit()


with open(binfile, 'ab') as f:
    f.write(b'\x00' * bss_length)
print('binpatch done')

