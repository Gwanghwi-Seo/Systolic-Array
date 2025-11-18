# Systolic-Array
Basic Synthesizable Systolic Array

Note: This hardware is not supported the hardware optimization methods such as,

		1. pipelining

		2. double-buffering

		3. eDMA access

		4. I, W, PSUM SRAM access while matrix multiplication phase

These features will be added.

# FPGA Synthesize Option
Comment out the "SIM" macro in the systolic.vh
Active "FPGA" macro in the systolic .vh