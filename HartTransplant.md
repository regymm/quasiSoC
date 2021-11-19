## Quasi SoC -- Hart Transplant

It's not hard to use Quasi SoC peripherals with other/better/self-written RISC-V cores. Usually little change is required on software side. 

Main hardware modifications:

- Clock and reset -- running at 62.5 MHz is recommended
- Bus interface -- bridging required, **pay significant attention to endian problems**
- PC start address -- ∂CPU has `0xf0000000`
- Interrupt -- this is tricky ...

#### [PicoRV32](https://github.com/cliffordwolf/picorv32)

See `rtl/hart_transplant/picorv32/`. PicoRV32 uses simple valid-ready bus and bus bridging is not hard. But "misaligned"(non-32-bit, sb/sh, a.k.a. `mem_wstrb != 4'b1111`) store need manual processing(read then write). The core itself needs zero modification. Interrupt disabled. 

With mul/div enabled, all three examples(tests, coremark, renderer) run without any modification. Coremark is ~0.22 CoreMark/MHz, which is very low compared with [this](https://www.eembc.org/viewer/?benchmark_seq=13365), seems my crappy bus converter chopped performance half. 

#### [VexRiscv]()

TODO