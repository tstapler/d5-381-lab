-- pl_reg.vhd: Package for MIPS32 pipeline implementation in CprE 381
-- It contains data types related to pipeline registers
--
-- Zhao Zhang, Fall 2015
--
-- This is a template file. You may make any change to it as you wish.
--

library IEEE;
use IEEE.std_logic_1164.all;
use work.mips32.all;

--------------------------------------------------
-- Data types and constant for pipeline register input/output
--------------------------------------------------
package pl_reg is
  -- Instruction outcome and trace, for debugging
  -- Note: The outcome of branch/jump is NPC change, which is not included here.
  --   This outcome only includes register write and data write.
  type m32_outcome is
    record
      reg_write  : m32_1bit;	-- Write to register?
      reg_dst    : m32_5bits;	-- Destination register
      reg_wdata  : m32_word;	-- Register write data
      dmem_write : m32_1bit;	-- Data memory write?
      dmem_addr  : m32_word;	-- Data memory address
      dmem_wdata : m32_word;	-- Data memory write data
      dmem_wmask : m32_4bits;	-- Data memory write mask
    end record;

  type m32_trace is
    record
      PC	: m32_word;	-- PC for this instruction
      inst_text : string(1 to 21); -- Instruction text
      flushed   : boolean;      -- Flushed or not
      o   	: m32_outcome;  -- Instruction outcome
    end record;

  -- Initial value for trace
  constant INIT_TRACE_VAL : m32_trace := (
      PC         => x"00000000",
      inst_text  => "                     ",
      flushed    => true,
      o          => (
      reg_write  => '0',
      reg_dst    => "00000",
      reg_wdata  => x"00000000",
      dmem_write => '0',
      dmem_addr  => x"00000000",
      dmem_wdata => x"00000000",
      dmem_wmask => "0000"));

  -- The IF/ID register type
  type m32_IFID is
    record        
      trace     : m32_trace;	-- The trace of execution

      PC_plus_4 : m32_word;    -- Next sequential PC
      inst      : m32_word; 	-- The binary instruction
      rs        : m32_5bits;
      rt        : m32_5bits;
    end record;

  -- Initial value for the IFID register
  constant INIT_IFID_VAL : m32_IFID := (
    trace     	=> INIT_TRACE_VAL,
    PC_plus_4 	=> x"00000000",
    rs => "00000",
    rt => "00000",
    inst	=> x"00000000");
  
  -- The ID/EX register type
  type m32_IDEX is
    record
      -- Control Signals
      trace     : m32_trace;	-- The trace of execution
      alusrc    : m32_2bits;	-- Source choice for the 2nd input of ALU
      aluop     : m32_3bits;    -- ALUop
      memread   : m32_1bit;
      memwrite  : m32_1bit;
      regwrite  : m32_1bit;
      regdst    : m32_1bit;
      memtoreg  : m32_1bit;
      link      : m32_1bit;
      branch    : m32_2bits;
      jump      : m32_1bit;
      jr        : m32_1bit;
      aluzero   : m32_1bit;

      --Other Signals
      inst      : m32_26bits;
      PC_plus_4 : m32_word;	-- PC plus 4
      rdata1    : m32_word;
      rdata2    : m32_word;
      ext_imme  : m32_word;
      ext_shamt : m32_word; 
      shamt : m32_5bits;
      dst       : m32_5bits;
      rt        : m32_5bits;
      rd        : m32_5bits;
      flushed   : boolean;
      rs : m32_5bits;
    end record;

  -- Initial value for the IDEX register
  constant INIT_IDEX_VAL : m32_IDEX := (
      trace 	=> INIT_TRACE_VAL,
      alusrc    => "00",
      aluop     => "000",
      memread  => '0',
      memwrite => '0',
      regwrite => '0',
      regdst => '0',
      memtoreg => '0',
      link => '0',
      branch => "00",
      jump  => '0',
      jr => '0',
      aluzero => '0',

      inst => "00000000000000000000000000",
      PC_plus_4 => x"00000000",
      rdata1 => x"00000000",
      rdata2 => x"00000000",
      ext_imme => x"00000000",
      ext_shamt => x"00000000",
      shamt => "00000",
      rt => "00000",
      dst => "00000",
      rs => "00000",
      rd => "00000",
      flushed => false);
    
  -- The EX/MEM register type
  type m32_EXMEM is
    record
      trace	 : m32_trace;	-- The trace of execution

      --Control Signals
      regwrite          : m32_1bit;
      memtoreg          : m32_1bit;
      branch            : m32_2bits;
      memwrite          : m32_1bit;
      memread           : m32_1bit;	-- Memory read signal
      link : m32_1bit;

      branch_addr       : m32_word;
      alu_zero          : m32_1bit;
      alu_result        : m32_word;
      rdata1            : m32_word;
      rdata2            : m32_word;
      dst               : m32_5bits;   -- Destination register (either rt or rd)
      PC_plus_4 : m32_word;
      flushed : boolean;
    end record;

  -- Initial value for the EXMEM register
  constant INIT_EXMEM_VAL : m32_EXMEM := (
      trace	=> INIT_TRACE_VAL,

      regwrite => '0',
      memtoreg => '0',
      branch => "00",
      memwrite => '0',
      memread => '0',
      link => '0',
      
      branch_addr => x"00000000",
      alu_zero => '0',
      alu_result => x"00000000",
      rdata1 => x"00000000",
      rdata2 => x"00000000",
      dst	=> "00000",
      PC_plus_4 => x"00000000",
	flushed => true);
      -- CODE DELETED

  -- The MEM/WB register type
  type m32_MEMWB is
    record
      trace      : m32_trace;	-- The trace of execution
      regwrite   : m32_1bit;	-- Register write
      memtoreg   : m32_1bit;
      memdata    : m32_word;
      alu_result : m32_word;
      link : m32_1bit;
      -- CODE DELETED

      dst        : m32_5bits;	-- Destination register (either rt or rd)
      PC_plus_4 : m32_word;
      flushed : boolean;
      -- CODE DELETED
    end record;

  -- Initial value for the MEMWB register
  constant INIT_MEMWB_VAL : m32_MEMWB := (
      trace	=> INIT_TRACE_VAL,
      regwrite  => '0',
      memtoreg => '0',
      memdata => x"00000000",
      alu_result => x"00000000",
      link => '0',

      dst       => "00000",
      PC_plus_4 => x"00000000",
	flushed => false);
end package;

------------------------------------------------------------
-- IFID register
------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use work.mips32.all;
use work.pl_reg.all;

entity IFID_reg is			-- IFID pipeline regster
  port (i  	: in  m32_IFID;		-- Input from the IF stage
        o  	: out m32_IFID;		-- Output to the ID stage
        we      : in  m32_1bit := '1';	-- Write enable signal
    	flush   : in  m32_1bit := '0';	-- Flush signal
    	clock   : in  m32_1bit);	-- Clock signal
end IFID_reg;

architecture behavior of IFID_reg is
  signal   r : m32_IFID := INIT_IFID_VAL; 
begin
  -- The read process
  o <= r;

  -- The write process
  WRITE : process (clock)
  begin
    if rising_edge(clock) then
      if flush = '1' then
        r.inst          <= x"00000000";	-- NOP instruction

        -- Pass trace and mark instruction as flushed
        r.trace.PC  	  <= i.trace.PC;
	r.trace.inst_text <= i.trace.inst_text;
        r.trace.flushed   <= true;
      elsif we = '1' then
        r <= i;
      end if;
    end if;
  end process;
end behavior;

------------------------------------------------------------
-- IDEX register
------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use work.mips32.all;
use work.pl_reg.all;

entity IDEX_reg is			-- IDEX pipeline regster
  port (i  	: in  m32_IDEX;		-- Input from the ID stage
        o  	: out m32_IDEX;		-- Output to the EX stage
        we      : in  m32_1bit := '1';  -- Write enable signal
    	flush   : in  m32_1bit := '0';	-- Flush signal
        clock   : in  m32_1bit);	-- Clock signal
end entity;

architecture behavior of IDEX_reg is
  signal r : m32_IDEX := INIT_IDEX_VAL; 
begin
  -- The read process
  o <= r;

  -- The write process
  WRITE: process (clock)
  begin
    if rising_edge(clock) then
      if flush = '1' then
        -- Clear any signals that cause write to PC, registers and
        -- memory write.  Mark instruction as "flushed"
        -- NOTE: Clear ALUop too, because ALU control may assert EX_jr when it 
        -- sees ALUop being R-type and a funct field that matches JR's funct code
        r.regwrite  <= '0';
        r.memwrite <= '0';
        r.aluop <= "000";
        r.flushed <= true;
        -- CODE DELETED

        -- Pass trace and mark instruction as flushed
        r.trace.PC  	  <= i.trace.PC;
	r.trace.inst_text <= i.trace.inst_text;
        r.trace.flushed   <= true;

      elsif we = '1' then
        r <= i;
      end if;
    end if;
  end process;
end behavior;

------------------------------------------------------------
-- EXMEM register
------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use work.mips32.all;
use work.pl_reg.all;

entity EXMEM_reg is			-- EXMEM pipeline regster
  port (i  	: in  m32_EXMEM;	-- Input from the EX stage
        o  	: out m32_EXMEM;	-- Output to the MEM stage
        we      : in  m32_1bit := '1';  -- Write enable signal
    	flush   : in  m32_1bit := '0';	-- Flush signal, not used yet
        clock   : in  m32_1bit);	-- Clock signal
end entity;

architecture behavior of EXMEM_reg is
  signal r : m32_EXMEM := INIT_EXMEM_VAL; 
begin
  -- The read process
  o <= r;

  -- The write process
  WRITE: process (clock)
  begin
    if rising_edge(clock) then
      if flush = '1' then
        -- Clear register and memory write signals
        r.regwrite  <= '0';
        r.memwrite <= '0';
        -- CODE DELETE
      
        -- Pass trace and mark the instruction as flushed
        r.trace.PC  	  <= i.trace.PC;
	r.trace.inst_text <= i.trace.inst_text;
        r.trace.flushed   <= true;

      elsif we = '1' then
        r <= i;
      end if;
    end if;
  end process;
end behavior;

------------------------------------------------------------
-- MEMWB register
------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use work.mips32.all;
use work.pl_reg.all;

entity MEMWB_reg is			-- MEMWB pipeline regster
  port (i  	: in  m32_MEMWB;	-- Input from the MEM stage
        o  	: out m32_MEMWB;	-- Output to the WB stage
        we      : in  m32_1bit := '1';  -- Write enable signal
    	flush   : in  m32_1bit := '0';	-- Flush signal, not used yet
        clock   : in  m32_1bit);	-- Clock signal
end entity;

architecture behavior of MEMWB_reg is
  signal r : m32_MEMWB := INIT_MEMWB_VAL; 
begin
  -- The read process
  o <= r;

  -- The write process
  WRITE: process (clock)
  begin
    if rising_edge(clock) then
      if flush = '1' then
        -- Clear register write signal and mark instruction as "flushed"
        r.regwrite  <= '0';
        r.flushed <= true;

        -- Pass trace and mark the instruction as flushed
        r.trace.PC  	  <= i.trace.PC;
        r.trace.inst_text <= i.trace.inst_text;
        r.trace.flushed   <= true;
      elsif we = '1' then
        r <= i;
      end if;
    end if;
  end process;
end behavior;

