
-- cpu_entity.vhd: The VHDL entity for CPU modeling
--
-- Zhao Zhang, fall 2015
--
-- The CPU entity for datapath and control. It connects to 1) an instruction memory, 
-- 2) a data memory, and 3) an external clock source.
--
-- The architectures of the CPU are put in separate files.

library IEEE;
use IEEE.std_logic_1164.all;
use work.mips32.all;
use work.pl_reg.all;

entity cpu is
  port (imem_addr   : out m32_word := x"00080000";     	-- Instruction memory address
        inst        : in  m32_word := x"00000000";     	-- Instruction
        dmem_addr   : out m32_word := x"00000000";     	-- Data memory address
        dmem_read   : out m32_1bit := '0';     		-- Data memory read?
        dmem_write  : out m32_1bit := '1';     		-- Data memory write?
        dmem_wmask  : out m32_4bits := "0000";    	-- Data memory write mask
        dmem_rdata  : in  m32_word := x"00000000";     	-- Data memory read data
        dmem_wdata  : out m32_word := x"00000000";     	-- Data memory write data
        reg_write   : out m32_1bit := '0';     		-- FOR DEBUG: Register write or not
        reg_dst     : out m32_5bits := "00000";    	-- FOR DEBUG: The no. of the register to write
        reg_wdata   : out m32_word  := x"00000000";	-- FOR DEBUG: The register data to write
        inst_text   : out string(1 to 21);		-- FOR DEBUG: The text format of the instruction
	trace       : out m32_trace;	  		-- FOR DEBUGGING the pipeline execution
        clock       : in  m32_1bit := '0');    		-- System clock
end cpu;
