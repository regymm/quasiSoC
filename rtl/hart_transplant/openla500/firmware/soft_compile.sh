#!/bin/bash

make -C /src/chiplab/sims/verilator/run_prog soft_compile
cp /src/chiplab/sims/verilator/run_prog/obj/linux_obj/obj/vmlinux.bin /mnt
cp /src/chiplab/sims/verilator/run_prog/obj/linux_obj/obj/start.bin /mnt
