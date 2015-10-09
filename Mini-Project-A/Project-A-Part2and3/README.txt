README.txt

CprE 381, Fall 2015

This package contains template and sample files for Mini-Project A,
Parts 2 and 3.  File cpu_scp.vhd is a template file for structural
modeling of the organization of a single-cycle MIPS CPU.  The other
files are for behavioral or dataflow modeling of the datapath elements
and control units.

The files are revised from a sample solution by Dr. Zhao Zhang.  When
you use or revise the files, you must maintain the same time delay for
the ALU, adders, main control unit, ALU control unit, register file,
instruction memory, and data memory.

The files should be used together with the files provided in
Project-A-Part1.zip.

-----------------------
Detailed description
-----------------------

If a file is labeled as sample, it is directly from the solution code.
If a file is marked as template, some (probably many) code lines has
been removed, and additional comments may have added.

cpu_scp.vhd (template): Structural modeling of the cpu.vhd, with most
code lines removed.  You need to make it complete.  

tb_cpu1.vhd (use as it is): The testbench program.  It contains two CPU
instances, a behavioral one (cpu0) and a structural one (cpu1). The
first one is used to check the correctness of the second one.  For each
CPU, the code provides a instruction memory instance and a data memory
instance,  with a fixed memory read latency of 19.5 ns.  It also drives
the CPU clock and a memory clock.  This is the only file that you should
NOT make any change.

alu.vhd (template): Behavioral modeling of the ALU. The ALU has a fixed
latency of 19.5 ns.  You may extend it to support more data operations. 

adder.vhd (sample): Behavioral modeling of a simple adder. The adder has
a fixed latency of 19.0 ns. You may use it as it is, one for calculating
PC+4 and on for branch target.

control.vhd (template): Dataflow modeling for the main control unit.  It
has a fixed latency of 9.5 ns.  You may extend it to support more
opcodes.  You may also use slightly different control signals, depending
on your own design.  Alternatively, you may use behavioral modeling
instead of dataflow modeling.

alu_ctrl.vhd (template): Behavioral modeling for the ALU control unit.
Its latency is 9.5 ns fixed.  You may extend it to support more funct
codes.  Note that the ALU control unit has to be extended to support JR
and SLL instructions.  See the code for hints.

regfile.vhd (sample): Behavioral modeling for the register file.  The
register read latency is 9.5 ns fixed.  You are suggested to use it as
it is.

small_elements.vhd (sample):  Collection of other, small datapath
elements, including single register, PC register, 2-to-1 mux, 4-to-1
mux, and a special PC mux.  You may add new elements and revise the
existing ones as you wish.

