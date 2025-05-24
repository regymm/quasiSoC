#!/bin/bash -e
xxd -c 4 -e start.bin | awk '{print $2}' > start.dat
rm -rf meminit.bin
fallocate -l $((0x300000)) meminit.bin 
cat vmlinux.bin >> meminit.bin         
fallocate -l $((0x5f00000)) meminit.bin 
xxd -r -p init_5f.txt >> meminit.bin                                         
fallocate -l $((0x8000000)) meminit.bin 
xxd -c 4 -e meminit.bin | awk '{print $2}' > meminit.dat
