### openLA500 LA32R Simulation

Clone the repo, then: 

```sh
$ cd rtl/hart_transplant/openla500
$ git clone https://github.com/regymm/open-la500 # Original repo is https://gitee.com/loongson-edu/open-la500
cd firmware
$ ./get_start_vmlinux_docker.sh # This copies kernel and startup files from pre-built Docker image https://github.com/FPGAOL-CE/osstoolchain-docker-things/tree/master/la32r
$ ./gen_sim_data.sh
$ cd ../sim
$ ./run_sim.sh
```

Expected output:

```
❯ ./run_sim.sh 
Compiling...
- V e r i l a t i o n   R e p o r t: Verilator 5.034 2025-02-24 rev v5.034
- Verilator: Built from 9.777 MB sources in 55 modules, into 15.317 MB in 23 C++ files needing 0.004 MB
- Verilator: Walltime 1.319 s (elab=0.035, cvt=1.199, bld=0.000); cpu 1.548 s on 28 threads; alloced 209.852 MB
make: Entering directory '/tmp/quasiSoC/rtl/hart_transplant/openla500/sim/obj_dir'
g++  -I.  -MMD -I/usr/share/verilator/include -I/usr/share/verilator/include/vltstd -DVM_COVERAGE=0 -DVM_SC=0 -DVM_TIMING=0 -DVM_TRACE=0 -DVM_TRACE_FST=0 -DVM_TRACE_VCD=0 -faligned-new -fcf-protection=none -Wno-bool-operation -Wno-shadow -Wno-sign-compare -Wno-subobject-linkage -Wno-tautological-compare -Wno-uninitialized -Wno-unused-but-set-parameter -Wno-unused-but-set-variable -Wno-unused-parameter -Wno-unused-variable      -O3 -march=native  -c -o sim_main.o ../sim_main.cpp
g++ -Os  -I.  -MMD -I/usr/share/verilator/include -I/usr/share/verilator/include/vltstd -DVM_COVERAGE=0 -DVM_SC=0 -DVM_TIMING=0 -DVM_TRACE=0 -DVM_TRACE_FST=0 -DVM_TRACE_VCD=0 -faligned-new -fcf-protection=none -Wno-bool-operation -Wno-shadow -Wno-sign-compare -Wno-subobject-linkage -Wno-tautological-compare -Wno-uninitialized -Wno-unused-but-set-parameter -Wno-unused-but-set-variable -Wno-unused-parameter -Wno-unused-variable      -c -o verilated.o /usr/share/verilator/include/verilated.cpp
g++ -Os  -I.  -MMD -I/usr/share/verilator/include -I/usr/share/verilator/include/vltstd -DVM_COVERAGE=0 -DVM_SC=0 -DVM_TIMING=0 -DVM_TRACE=0 -DVM_TRACE_FST=0 -DVM_TRACE_VCD=0 -faligned-new -fcf-protection=none -Wno-bool-operation -Wno-shadow -Wno-sign-compare -Wno-subobject-linkage -Wno-tautological-compare -Wno-uninitialized -Wno-unused-but-set-parameter -Wno-unused-but-set-variable -Wno-unused-parameter -Wno-unused-variable      -c -o verilated_threads.o /usr/share/verilator/include/verilated_threads.cpp
g++ -O3 -march=native  -I.  -MMD -I/usr/share/verilator/include -I/usr/share/verilator/include/vltstd -DVM_COVERAGE=0 -DVM_SC=0 -DVM_TIMING=0 -DVM_TRACE=0 -DVM_TRACE_FST=0 -DVM_TRACE_VCD=0 -faligned-new -fcf-protection=none -Wno-bool-operation -Wno-shadow -Wno-sign-compare -Wno-subobject-linkage -Wno-tautological-compare -Wno-uninitialized -Wno-unused-but-set-parameter -Wno-unused-but-set-variable -Wno-unused-parameter -Wno-unused-variable      -x c++-header Vquasi_main__pch.h -o Vquasi_main__pch.h.fast.gch
g++   -I.  -MMD -I/usr/share/verilator/include -I/usr/share/verilator/include/vltstd -DVM_COVERAGE=0 -DVM_SC=0 -DVM_TIMING=0 -DVM_TRACE=0 -DVM_TRACE_FST=0 -DVM_TRACE_VCD=0 -faligned-new -fcf-protection=none -Wno-bool-operation -Wno-shadow -Wno-sign-compare -Wno-subobject-linkage -Wno-tautological-compare -Wno-uninitialized -Wno-unused-but-set-parameter -Wno-unused-but-set-variable -Wno-unused-parameter -Wno-unused-variable      -x c++-header Vquasi_main__pch.h -o Vquasi_main__pch.h.slow.gch
echo "" > Vquasi_main__ALL.verilator_deplist.tmp
g++ -O3 -march=native  -I.  -MMD -I/usr/share/verilator/include -I/usr/share/verilator/include/vltstd -DVM_COVERAGE=0 -DVM_SC=0 -DVM_TIMING=0 -DVM_TRACE=0 -DVM_TRACE_FST=0 -DVM_TRACE_VCD=0 -faligned-new -fcf-protection=none -Wno-bool-operation -Wno-shadow -Wno-sign-compare -Wno-subobject-linkage -Wno-tautological-compare -Wno-uninitialized -Wno-unused-but-set-parameter -Wno-unused-but-set-variable -Wno-unused-parameter -Wno-unused-variable      -include Vquasi_main__pch.h.fast -c -o Vquasi_main.o Vquasi_main.cpp
g++ -O3 -march=native  -I.  -MMD -I/usr/share/verilator/include -I/usr/share/verilator/include/vltstd -DVM_COVERAGE=0 -DVM_SC=0 -DVM_TIMING=0 -DVM_TRACE=0 -DVM_TRACE_FST=0 -DVM_TRACE_VCD=0 -faligned-new -fcf-protection=none -Wno-bool-operation -Wno-shadow -Wno-sign-compare -Wno-subobject-linkage -Wno-tautological-compare -Wno-uninitialized -Wno-unused-but-set-parameter -Wno-unused-but-set-variable -Wno-unused-parameter -Wno-unused-variable      -include Vquasi_main__pch.h.fast -c -o Vquasi_main___024root__DepSet_h1e9f1e78__0.o Vquasi_main___024root__DepSet_h1e9f1e78__0.cpp
g++ -O3 -march=native  -I.  -MMD -I/usr/share/verilator/include -I/usr/share/verilator/include/vltstd -DVM_COVERAGE=0 -DVM_SC=0 -DVM_TIMING=0 -DVM_TRACE=0 -DVM_TRACE_FST=0 -DVM_TRACE_VCD=0 -faligned-new -fcf-protection=none -Wno-bool-operation -Wno-shadow -Wno-sign-compare -Wno-subobject-linkage -Wno-tautological-compare -Wno-uninitialized -Wno-unused-but-set-parameter -Wno-unused-but-set-variable -Wno-unused-parameter -Wno-unused-variable      -include Vquasi_main__pch.h.fast -c -o Vquasi_main___024root__DepSet_h7486f407__0.o Vquasi_main___024root__DepSet_h7486f407__0.cpp
g++ -O3 -march=native  -I.  -MMD -I/usr/share/verilator/include -I/usr/share/verilator/include/vltstd -DVM_COVERAGE=0 -DVM_SC=0 -DVM_TIMING=0 -DVM_TRACE=0 -DVM_TRACE_FST=0 -DVM_TRACE_VCD=0 -faligned-new -fcf-protection=none -Wno-bool-operation -Wno-shadow -Wno-sign-compare -Wno-subobject-linkage -Wno-tautological-compare -Wno-uninitialized -Wno-unused-but-set-parameter -Wno-unused-but-set-variable -Wno-unused-parameter -Wno-unused-variable      -include Vquasi_main__pch.h.fast -c -o Vquasi_main___024root__DepSet_h7486f407__1.o Vquasi_main___024root__DepSet_h7486f407__1.cpp
g++ -O3 -march=native  -I.  -MMD -I/usr/share/verilator/include -I/usr/share/verilator/include/vltstd -DVM_COVERAGE=0 -DVM_SC=0 -DVM_TIMING=0 -DVM_TRACE=0 -DVM_TRACE_FST=0 -DVM_TRACE_VCD=0 -faligned-new -fcf-protection=none -Wno-bool-operation -Wno-shadow -Wno-sign-compare -Wno-subobject-linkage -Wno-tautological-compare -Wno-uninitialized -Wno-unused-but-set-parameter -Wno-unused-but-set-variable -Wno-unused-parameter -Wno-unused-variable      -include Vquasi_main__pch.h.fast -c -o Vquasi_main___024root__DepSet_h7486f407__2.o Vquasi_main___024root__DepSet_h7486f407__2.cpp
g++ -O3 -march=native  -I.  -MMD -I/usr/share/verilator/include -I/usr/share/verilator/include/vltstd -DVM_COVERAGE=0 -DVM_SC=0 -DVM_TIMING=0 -DVM_TRACE=0 -DVM_TRACE_FST=0 -DVM_TRACE_VCD=0 -faligned-new -fcf-protection=none -Wno-bool-operation -Wno-shadow -Wno-sign-compare -Wno-subobject-linkage -Wno-tautological-compare -Wno-uninitialized -Wno-unused-but-set-parameter -Wno-unused-but-set-variable -Wno-unused-parameter -Wno-unused-variable      -include Vquasi_main__pch.h.fast -c -o Vquasi_main___024root__DepSet_h7486f407__3.o Vquasi_main___024root__DepSet_h7486f407__3.cpp
g++ -O3 -march=native  -I.  -MMD -I/usr/share/verilator/include -I/usr/share/verilator/include/vltstd -DVM_COVERAGE=0 -DVM_SC=0 -DVM_TIMING=0 -DVM_TRACE=0 -DVM_TRACE_FST=0 -DVM_TRACE_VCD=0 -faligned-new -fcf-protection=none -Wno-bool-operation -Wno-shadow -Wno-sign-compare -Wno-subobject-linkage -Wno-tautological-compare -Wno-uninitialized -Wno-unused-but-set-parameter -Wno-unused-but-set-variable -Wno-unused-parameter -Wno-unused-variable      -include Vquasi_main__pch.h.fast -c -o Vquasi_main___024root__DepSet_h7486f407__4.o Vquasi_main___024root__DepSet_h7486f407__4.cpp
g++ -O3 -march=native  -I.  -MMD -I/usr/share/verilator/include -I/usr/share/verilator/include/vltstd -DVM_COVERAGE=0 -DVM_SC=0 -DVM_TIMING=0 -DVM_TRACE=0 -DVM_TRACE_FST=0 -DVM_TRACE_VCD=0 -faligned-new -fcf-protection=none -Wno-bool-operation -Wno-shadow -Wno-sign-compare -Wno-subobject-linkage -Wno-tautological-compare -Wno-uninitialized -Wno-unused-but-set-parameter -Wno-unused-but-set-variable -Wno-unused-parameter -Wno-unused-variable      -include Vquasi_main__pch.h.fast -c -o Vquasi_main___024root__DepSet_h7486f407__5.o Vquasi_main___024root__DepSet_h7486f407__5.cpp
g++ -O3 -march=native  -I.  -MMD -I/usr/share/verilator/include -I/usr/share/verilator/include/vltstd -DVM_COVERAGE=0 -DVM_SC=0 -DVM_TIMING=0 -DVM_TRACE=0 -DVM_TRACE_FST=0 -DVM_TRACE_VCD=0 -faligned-new -fcf-protection=none -Wno-bool-operation -Wno-shadow -Wno-sign-compare -Wno-subobject-linkage -Wno-tautological-compare -Wno-uninitialized -Wno-unused-but-set-parameter -Wno-unused-but-set-variable -Wno-unused-parameter -Wno-unused-variable      -include Vquasi_main__pch.h.fast -c -o Vquasi_main___024root__DepSet_h7486f407__6.o Vquasi_main___024root__DepSet_h7486f407__6.cpp
g++ -O3 -march=native  -I.  -MMD -I/usr/share/verilator/include -I/usr/share/verilator/include/vltstd -DVM_COVERAGE=0 -DVM_SC=0 -DVM_TIMING=0 -DVM_TRACE=0 -DVM_TRACE_FST=0 -DVM_TRACE_VCD=0 -faligned-new -fcf-protection=none -Wno-bool-operation -Wno-shadow -Wno-sign-compare -Wno-subobject-linkage -Wno-tautological-compare -Wno-uninitialized -Wno-unused-but-set-parameter -Wno-unused-but-set-variable -Wno-unused-parameter -Wno-unused-variable      -include Vquasi_main__pch.h.fast -c -o Vquasi_main___024root__DepSet_h7486f407__7.o Vquasi_main___024root__DepSet_h7486f407__7.cpp
g++ -O3 -march=native  -I.  -MMD -I/usr/share/verilator/include -I/usr/share/verilator/include/vltstd -DVM_COVERAGE=0 -DVM_SC=0 -DVM_TIMING=0 -DVM_TRACE=0 -DVM_TRACE_FST=0 -DVM_TRACE_VCD=0 -faligned-new -fcf-protection=none -Wno-bool-operation -Wno-shadow -Wno-sign-compare -Wno-subobject-linkage -Wno-tautological-compare -Wno-uninitialized -Wno-unused-but-set-parameter -Wno-unused-but-set-variable -Wno-unused-parameter -Wno-unused-variable      -include Vquasi_main__pch.h.fast -c -o Vquasi_main___024root__DepSet_h7486f407__8.o Vquasi_main___024root__DepSet_h7486f407__8.cpp
g++   -I.  -MMD -I/usr/share/verilator/include -I/usr/share/verilator/include/vltstd -DVM_COVERAGE=0 -DVM_SC=0 -DVM_TIMING=0 -DVM_TRACE=0 -DVM_TRACE_FST=0 -DVM_TRACE_VCD=0 -faligned-new -fcf-protection=none -Wno-bool-operation -Wno-shadow -Wno-sign-compare -Wno-subobject-linkage -Wno-tautological-compare -Wno-uninitialized -Wno-unused-but-set-parameter -Wno-unused-but-set-variable -Wno-unused-parameter -Wno-unused-variable      -include Vquasi_main__pch.h.slow -c -o Vquasi_main__ConstPool_0.o Vquasi_main__ConstPool_0.cpp
g++   -I.  -MMD -I/usr/share/verilator/include -I/usr/share/verilator/include/vltstd -DVM_COVERAGE=0 -DVM_SC=0 -DVM_TIMING=0 -DVM_TRACE=0 -DVM_TRACE_FST=0 -DVM_TRACE_VCD=0 -faligned-new -fcf-protection=none -Wno-bool-operation -Wno-shadow -Wno-sign-compare -Wno-subobject-linkage -Wno-tautological-compare -Wno-uninitialized -Wno-unused-but-set-parameter -Wno-unused-but-set-variable -Wno-unused-parameter -Wno-unused-variable      -include Vquasi_main__pch.h.slow -c -o Vquasi_main___024root__Slow.o Vquasi_main___024root__Slow.cpp
g++   -I.  -MMD -I/usr/share/verilator/include -I/usr/share/verilator/include/vltstd -DVM_COVERAGE=0 -DVM_SC=0 -DVM_TIMING=0 -DVM_TRACE=0 -DVM_TRACE_FST=0 -DVM_TRACE_VCD=0 -faligned-new -fcf-protection=none -Wno-bool-operation -Wno-shadow -Wno-sign-compare -Wno-subobject-linkage -Wno-tautological-compare -Wno-uninitialized -Wno-unused-but-set-parameter -Wno-unused-but-set-variable -Wno-unused-parameter -Wno-unused-variable      -include Vquasi_main__pch.h.slow -c -o Vquasi_main___024root__DepSet_h1e9f1e78__0__Slow.o Vquasi_main___024root__DepSet_h1e9f1e78__0__Slow.cpp
g++   -I.  -MMD -I/usr/share/verilator/include -I/usr/share/verilator/include/vltstd -DVM_COVERAGE=0 -DVM_SC=0 -DVM_TIMING=0 -DVM_TRACE=0 -DVM_TRACE_FST=0 -DVM_TRACE_VCD=0 -faligned-new -fcf-protection=none -Wno-bool-operation -Wno-shadow -Wno-sign-compare -Wno-subobject-linkage -Wno-tautological-compare -Wno-uninitialized -Wno-unused-but-set-parameter -Wno-unused-but-set-variable -Wno-unused-parameter -Wno-unused-variable      -include Vquasi_main__pch.h.slow -c -o Vquasi_main___024root__DepSet_h7486f407__0__Slow.o Vquasi_main___024root__DepSet_h7486f407__0__Slow.cpp
g++   -I.  -MMD -I/usr/share/verilator/include -I/usr/share/verilator/include/vltstd -DVM_COVERAGE=0 -DVM_SC=0 -DVM_TIMING=0 -DVM_TRACE=0 -DVM_TRACE_FST=0 -DVM_TRACE_VCD=0 -faligned-new -fcf-protection=none -Wno-bool-operation -Wno-shadow -Wno-sign-compare -Wno-subobject-linkage -Wno-tautological-compare -Wno-uninitialized -Wno-unused-but-set-parameter -Wno-unused-but-set-variable -Wno-unused-parameter -Wno-unused-variable      -include Vquasi_main__pch.h.slow -c -o Vquasi_main___024root__DepSet_h7486f407__1__Slow.o Vquasi_main___024root__DepSet_h7486f407__1__Slow.cpp
g++   -I.  -MMD -I/usr/share/verilator/include -I/usr/share/verilator/include/vltstd -DVM_COVERAGE=0 -DVM_SC=0 -DVM_TIMING=0 -DVM_TRACE=0 -DVM_TRACE_FST=0 -DVM_TRACE_VCD=0 -faligned-new -fcf-protection=none -Wno-bool-operation -Wno-shadow -Wno-sign-compare -Wno-subobject-linkage -Wno-tautological-compare -Wno-uninitialized -Wno-unused-but-set-parameter -Wno-unused-but-set-variable -Wno-unused-parameter -Wno-unused-variable      -include Vquasi_main__pch.h.slow -c -o Vquasi_main___024root__DepSet_h7486f407__2__Slow.o Vquasi_main___024root__DepSet_h7486f407__2__Slow.cpp
g++   -I.  -MMD -I/usr/share/verilator/include -I/usr/share/verilator/include/vltstd -DVM_COVERAGE=0 -DVM_SC=0 -DVM_TIMING=0 -DVM_TRACE=0 -DVM_TRACE_FST=0 -DVM_TRACE_VCD=0 -faligned-new -fcf-protection=none -Wno-bool-operation -Wno-shadow -Wno-sign-compare -Wno-subobject-linkage -Wno-tautological-compare -Wno-uninitialized -Wno-unused-but-set-parameter -Wno-unused-but-set-variable -Wno-unused-parameter -Wno-unused-variable      -include Vquasi_main__pch.h.slow -c -o Vquasi_main___024root__DepSet_h7486f407__3__Slow.o Vquasi_main___024root__DepSet_h7486f407__3__Slow.cpp
g++   -I.  -MMD -I/usr/share/verilator/include -I/usr/share/verilator/include/vltstd -DVM_COVERAGE=0 -DVM_SC=0 -DVM_TIMING=0 -DVM_TRACE=0 -DVM_TRACE_FST=0 -DVM_TRACE_VCD=0 -faligned-new -fcf-protection=none -Wno-bool-operation -Wno-shadow -Wno-sign-compare -Wno-subobject-linkage -Wno-tautological-compare -Wno-uninitialized -Wno-unused-but-set-parameter -Wno-unused-but-set-variable -Wno-unused-parameter -Wno-unused-variable      -include Vquasi_main__pch.h.slow -c -o Vquasi_main___024root__DepSet_h7486f407__4__Slow.o Vquasi_main___024root__DepSet_h7486f407__4__Slow.cpp
g++   -I.  -MMD -I/usr/share/verilator/include -I/usr/share/verilator/include/vltstd -DVM_COVERAGE=0 -DVM_SC=0 -DVM_TIMING=0 -DVM_TRACE=0 -DVM_TRACE_FST=0 -DVM_TRACE_VCD=0 -faligned-new -fcf-protection=none -Wno-bool-operation -Wno-shadow -Wno-sign-compare -Wno-subobject-linkage -Wno-tautological-compare -Wno-uninitialized -Wno-unused-but-set-parameter -Wno-unused-but-set-variable -Wno-unused-parameter -Wno-unused-variable      -include Vquasi_main__pch.h.slow -c -o Vquasi_main___024root__DepSet_h7486f407__5__Slow.o Vquasi_main___024root__DepSet_h7486f407__5__Slow.cpp
g++   -I.  -MMD -I/usr/share/verilator/include -I/usr/share/verilator/include/vltstd -DVM_COVERAGE=0 -DVM_SC=0 -DVM_TIMING=0 -DVM_TRACE=0 -DVM_TRACE_FST=0 -DVM_TRACE_VCD=0 -faligned-new -fcf-protection=none -Wno-bool-operation -Wno-shadow -Wno-sign-compare -Wno-subobject-linkage -Wno-tautological-compare -Wno-uninitialized -Wno-unused-but-set-parameter -Wno-unused-but-set-variable -Wno-unused-parameter -Wno-unused-variable      -include Vquasi_main__pch.h.slow -c -o Vquasi_main___024root__DepSet_h7486f407__6__Slow.o Vquasi_main___024root__DepSet_h7486f407__6__Slow.cpp
g++   -I.  -MMD -I/usr/share/verilator/include -I/usr/share/verilator/include/vltstd -DVM_COVERAGE=0 -DVM_SC=0 -DVM_TIMING=0 -DVM_TRACE=0 -DVM_TRACE_FST=0 -DVM_TRACE_VCD=0 -faligned-new -fcf-protection=none -Wno-bool-operation -Wno-shadow -Wno-sign-compare -Wno-subobject-linkage -Wno-tautological-compare -Wno-uninitialized -Wno-unused-but-set-parameter -Wno-unused-but-set-variable -Wno-unused-parameter -Wno-unused-variable      -include Vquasi_main__pch.h.slow -c -o Vquasi_main___024root__DepSet_h7486f407__7__Slow.o Vquasi_main___024root__DepSet_h7486f407__7__Slow.cpp
g++   -I.  -MMD -I/usr/share/verilator/include -I/usr/share/verilator/include/vltstd -DVM_COVERAGE=0 -DVM_SC=0 -DVM_TIMING=0 -DVM_TRACE=0 -DVM_TRACE_FST=0 -DVM_TRACE_VCD=0 -faligned-new -fcf-protection=none -Wno-bool-operation -Wno-shadow -Wno-sign-compare -Wno-subobject-linkage -Wno-tautological-compare -Wno-uninitialized -Wno-unused-but-set-parameter -Wno-unused-but-set-variable -Wno-unused-parameter -Wno-unused-variable      -include Vquasi_main__pch.h.slow -c -o Vquasi_main__Syms.o Vquasi_main__Syms.cpp
g++    sim_main.o verilated.o verilated_threads.o Vquasi_main__ALL.a    -pthread -lpthread -latomic   -o Vquasi_main
rm Vquasi_main__ALL.verilator_deplist.tmp
make: Leaving directory '/tmp/quasiSoC/rtl/hart_transplant/openla500/sim/obj_dir'
Launching simulation...
abcdefghij
uart work!
[    0.000000] Linux version 5.14.0-rc2-g4ed7b98e08e8-dirty (root@d07d21f89541) (loongarch32r-linux-gnusf-gcc (GCC) 8.3.0, GNU ld (GNU Binutils) 2.31.1.20190122) #8 PREEMPT Sat May 17 11:35:23 KST 2025
[    0.000000] Standard 32-bit Loongson Processor probed
[    0.000000] the link is empty!
[    0.000000] Scan bootparam failed
[    0.000000] printk: bootconsole [early0] enabled
[    0.000000] initrd start < PAGE_OFFSET
[    0.000000] Can't find EFI system table.
[    0.000000] start_pfn=0x0, end_pfn=0x8000, num_physpages:0x8000
[    0.000000] The BIOS Version: (null)
[    0.000000] Initrd not found or empty - disabling initrd
[    0.000000] CPU0 revision is: 00004200 (Loongson-32bit)
[    0.000000] Primary instruction cache 8kB, 2-way, VIPT, linesize 16 bytes.
[    0.000000] Primary data cache 8kB, 2-way, VIPT, no aliases, linesize 16 bytes
[    0.000000] Zone ranges:
[    0.000000]   DMA32    [mem 0x0000000000000000-0x00000000ffffffff]
[    0.000000]   Normal   empty
[    0.000000] Movable zone start for each node
[    0.000000] Early memory node ranges
[    0.000000]   node   0: [mem 0x0000000000000000-0x0000000007ffffff]
[    0.000000] Initmem setup node 0 [mem 0x0000000000000000-0x0000000007ffffff]
[    0.000000] eentry = 0xa0210000,tlbrentry = 0xa0201000
[    0.000000] pcpu-alloc: s0 r0 d32768 u32768 alloc=1*32768
[    0.000000] pcpu-alloc: [0] 0 
[    0.000000] Built 1 zonelists, mobility grouping on.  Total pages: 32512
[    0.000000] Kernel command line: =/init loglevel=8
[    0.000000] Dentry cache hash table entries: 16384 (order: 4, 65536 bytes, linear)
[    0.000000] Inode-cache hash table entries: 8192 (order: 3, 32768 bytes, linear)
[    0.000000] mem auto-init: stack:off, heap alloc:off, heap free:off
[    0.000000] Memory: 121016K/131072K available (2457K kernel code, 950K rwdata, 208K rodata, 2844K init, 324K bss, 10056K reserved, 0K cma-reserved)
[    0.000000] SLUB: HWalign=64, Order=0-3, MinObjects=0, CPUs=1, Nodes=1
[    0.000000] rcu: Preemptible hierarchical RCU implementation.
[    0.000000] 	Trampoline variant of Tasks RCU enabled.
[    0.000000] rcu: RCU calculated value of scheduler-enlistment delay is 25 jiffies.
[    0.000000] NR_IRQS: 320
[    0.000000] Constant clock event device register
[    0.000000] clocksource: Constant: mask: 0xffffffffffffffff max_cycles: 0x2e2049d3e8, max_idle_ns: 440795210634 ns
[    0.000000] Constant clock source device register
[    0.004000] Console: colour dummy device 80x25
[    0.004000] Calibrating delay loop (skipped), value calculated using timer frequency.. 400.00 BogoMIPS (lpj=800000)
[    0.004000] pid_max: default: 32768 minimum: 301
[    0.008000] Mount-cache hash table entries: 1024 (order: 0, 4096 bytes, linear)
[    0.008000] Mountpoint-cache hash table entries: 1024 (order: 0, 4096 bytes, linear)
[    0.020000] rcu: Hierarchical SRCU implementation.
[    0.024000] devtmpfs: initialized
[    0.028000] clocksource: jiffies: mask: 0xffffffff max_cycles: 0xffffffff, max_idle_ns: 7645041785100000 ns
[    0.028000] futex hash table entries: 256 (order: -1, 3072 bytes, linear)
[    0.072000] clocksource: Switched to clocksource Constant
[    0.148000] workingset: timestamp_bits=30 max_order=15 bucket_order=0
[    0.200000] io scheduler mq-deadline registered
[    0.244000] Serial: 8250/16550 driver, 16 ports, IRQ sharing enabled
[    0.284000] printk: console [ttyS0] disabled
[    0.292000] 1fe001e0.serial: ttyS0 at MMIO 0x1fe001e0 (irq = 19, base_baud = 2062500) is a 16550A
[    0.292000] printk: console [ttyS0] enabled
[    0.292000] printk: console [ttyS0] enabled
[    0.292000] printk: bootconsole [early0] disabled
[    0.292000] printk: bootconsole [early0] disabled
[    0.396000] loop: module loaded
[    0.396000] random: get_random_bytes called from 0xa030bea4 with crng_init=0
[    1.020000] random: fast init done
[    1.960000] Freeing unused kernel image (initmem) memory: 2844K
[    1.960000] This architecture does not have kernel memory protection.
[    1.960000] Run /init as init process
[    1.964000]   with arguments:
[    1.964000]     /init
[    1.964000]   with environment:
[    1.964000]     HOME=/
[    1.964000]     TERM=linux
can't run '/bin/hostname': No such file or directory
Starting syslogd: /etc/init.d/S01syslogd: line 16: start-stop-daemon: not found
FAIL
Starting klogd: /etc/init.d/S02klogd: line 16: start-stop-daemon: not found
FAIL
Running sysctl: OK

Welcome to Buildroot LA32R
(none) login: root
Password: 
login[42]: root login on 'console'
# ls / 
bin      init     linuxrc  opt      run      tmp
dev      lib      media    proc     sbin     usr
etc      lib32    mnt      root     sys      var
# 
```

On a machine with good single-core performance, simulate till Linux user login takes ~40 minutes. 

Delay between kernel entry and first earlycon printk message: it's because of clearing BSS. Disabling BSS clearing in `arch/loongarch/kernel/head.S` can speed this up (e.g. when doing initial simulation in Vivado). 