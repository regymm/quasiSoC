## Quasi SoC -- SymbiFlow

TODO: update!

*I don't understand this toolchain, yet it works ...*

***Help needed!***

**Preparation**

Install the SymbiFlow toolchain. Following [symbiflow-examples](https://symbiflow-examples.readthedocs.io/en/latest/getting-symbiflow.html) would be enough. It's a little bit tricky so if you can't install it, try next week. 

**Build hardware**

Again, use xc7z010 @ SqueakyBoard as example. 

First, `cd eda_projects/pCPU-squeakyboard-symbiflow`. 

Since I don't know how to include header files, just copy it into build directory:

`mkdir build && cp quasi.vh build/`

Currently cache module have some compiling problem, and video module may cause other problems, so these two are disabled. 

Then just run `make`, wait, until `build/quasi_main.bit` is generated. 

Resource utilization is at the end of `build/pack.log`, there are also timing files.

*Currently timing constraints are not applied correctly, I don't know if timing failed though now it seems working.*

Running on board(I'm using Arch Linux's default openocd and custom FT2232 downloader, fortunately this works): 

`openocd -f /usr/share/openocd/scripts/board/arty_s7.cfg -c "init; pld load 0 build/quasi_main.bit; exit"`

If nothing went wrong, processor output will be on serial port 921600-baud and LEDs will react. 

