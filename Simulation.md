## Quasi SoC -- Simulation

Probably you don't have the same hardware as me, so begin from simulation is a good idea. 

#### Preparation

The 32-bit RISC-V toolchain is required to build firmware files. 

You should first have RISC-V 32-bit toolchain with Newlib -- [RISC-V GNU Compiler Toolchain](https://github.com/riscv-collab/riscv-gnu-toolchain), probably configure with `./configure --prefix=/opt/riscv32_xxx --with-arch=rv32ima_zicsr --with-abi=ilp32 && make newlib`. 

Or you can use pre-built Docker containers including the tools: `regymm/rv32ima`

Then run `make` in `firmware/` to generate SoC boot ROM. Or `docker run -it --rm -v .:/mnt regymm/rv32ima:latest` and `make -C /mnt/firmware`. 

`make` in `software/tests` compiles the riscv_tests to test all RISC-V instructions. 

`make` in `software/ssbi` builds the SBI to run MMU Linux kernels. 

#### Simulation

In the `sim` directory, ordinary firmware, No-MMU kernel, and MMU kernel simulation can be run with Verilator: 

Ordinary firmware, like the riscv_tests: 

`./run_sim.sh ../software/tests/firmware/firmware.bin`

No MMU Linux kernel, kernel binary and device tree included in the repo:

`./run_sim.sh kernel ../software/kernel/Image  ../software/kernel/quasi.dtb`

MMU Linux kernel, loaded via a simple SBI implementation: 

`./run_sim.sh mmukernel ../software/mmukernel/Image   ../software/mmukernel/mmu0x2000.dtb  ../software/ssbi/sbi.bin`

An executable file for iverilog will also be compiled as `./a.out`, but the speed is much slower. 

#### 


