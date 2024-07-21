## Quasi SoC -- Build & Run

**Preparation**

You should first have RISC-V 32-bit toolchain with Newlib -- [RISC-V GNU Compiler Toolchain](https://github.com/riscv-collab/riscv-gnu-toolchain), probably configure with `./configure --prefix=/opt/riscv32_xxx --with-arch=rv32ima_zicsr --with-abi=ilp32 && make newlib`. 

Or you can use pre-built Docker containers including the tools: `regymm/rv32ima`

**Hardware**

Then run `make` in `firmware/` to generate SoC boot ROM. Or `docker run -it --rm -v .:/mnt regymm/rv32ima:latest` and `make -C /mnt/firmware`. 

If error occurs, probably it's just some minor path problems or environment variables, just export variables, modify `Makefile`, and fix according your own case. 

~~Use `eda_projects/pCPU-squeakyboard-vivado/proj.tcl` to re-create Vivado project.~~ Just create a new project and add all verilog files and constraints. See `sim/run_sim.sh` for an idea of what files are required. That's it, because no IP core is used. Clocking is (by default) instantiated via PLL or MMCM directly instead of clocking_wizard. 

Of course you should modify files in `rtl/board-specific/nexys_video/` according to your own board and peripherals(you can just disconnect input/output wires without disabling modules, no problem). 

Then run synthesis/implementation/bitstream as usual -- just take special care that no critical warnings about `result_bootrom.dat` occur -- boot ROM must be compiled into bitstream, while RAM and register inital values usually don't matter. It's recommended to have ILA hooked up to ∂CPU program counter(PC) and memory buses, in case memory hangs or PC flies away. 

**UART**

UART is recommended for interaction, program downloading, and reseting -- instead of hardware buttons, SD card, or HDMI. 

Open serial port at 921600-baud with like `sudo picocom -b 921600 -p 1 /dev/ttyUSB1`. Picocom is recommend while screen is not -- when pasting a bunch of characters and transferring at full speed, screen seems to miss characters. Baud rate can be changed at `BAUD_RATE_UART` parameter in `quasi_main.v` 

When system starts, you should see messages like these: 

```
[bootrom]c_start
[bootrom]sdcard not found. boot from UART.
```

Or with `firmware/sd_uartbl/uartbl.bin` written to SD card's first sectors:

```
[bootrom]c_start
[bootrom]load from sdcard
[bootrom]xfer ctrl to 0x20000000

[uartbl] started. 
```

Input multiple `R` until LED brightness changes to reset the board. Then press `x` (or anything else, but not `0-9a-f`) to de-assert reset. So resetting can be automated without hardware intervention. 

See `software/uartboot.sh` for program downloading details. Make sure you have a 921600-baud picocom running when using `uartboot.sh`, or the `> /dev/ttyUSB?` will suffer wrong baud rate. 

**Software**

In `software/`, run `make run_tests`, `make run_coremark`, or `make run_renderer` for RISC-V tests, CoreMark, or the renderer. They'll be automatically compiled and downloaded via UART to Quasi SoC. You'll need HDMI for renderer. 

I think these three examples can cover most of the software flows required in cross-compiling(Makefile, linker script, volatile int* MMIO, ODR, inline assembly, call C in assembly, objcopy, patch BSS, ...). My coding habit is bad but they work(at least for now). 

Things like printf, string operation, float-point, and basic C++ are all tested to be working. 