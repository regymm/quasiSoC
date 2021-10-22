## Quasi SoC -- Hart Transplant

It's not hard to use Quasi SoC peripherals with other/better/self-written RISC-V cores. Usually little change is required on software side. 

Main hardware modifications:

- Clock and reset -- running at 62.5 MHz is recommended
- Bus interface -- bridging required, for BRAM-like interface, this won't be hard
- PC start address -- ∂CPU has `0xf0000000`
- Interrupt -- this is tricky ...

#### [PicoRV32]()

TODO

#### [VexRiscv]()

TODO