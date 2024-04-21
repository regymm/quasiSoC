## Quasi SoC -- Simulation

Probably you don't have the same hardware as me, so begin from simulation is a good idea. 

In the `sim` directory, ordinary firmware, No-MMU kernel, and MMU kernel simulation can be run with Verilator (you may need to compile the .bin beforehand): 

Ordinary firmware, like the riscv_tests: 

`./run_sim.sh ../software/tests/firmware/firmware.bin`

No MMU Linux kernel, kernel binary and device tree included in the repo:

`./run_sim.sh kernel ../software/kernel/Image  ../software/kernel/quasi.dtb`

MMU Linux kernel, loaded via a simple SBI implementation: 

`./run_sim.sh mmukernel ../software/mmukernel/Image   ../software/mmukernel/mmu0x2000.dtb  ../software/ssbi/sbi.bin`

An executable file for iverilog will also be compiled as `./a.out`, but the speed is much slower. 



#### Vivado / iverilog



#### Verilator

