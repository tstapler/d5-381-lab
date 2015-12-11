--
-- tb_cpu1.vhd: Test bench for SCP
--
library IEEE;
use IEEE.std_logic_1164.all;
use work.mips32.all;
use work.pl_reg.all;

entity tb_cpu3 is
  generic (MEM_DELAY : time := 19.5 ns);
end tb_cpu3;

architecture behavior of tb_cpu3 is
  -- The pipeline clock is 1/5 of the CCT for single-cycle implementation
  constant CCT_PL : time := 40 ns; -- Changed to 40 just for testing

  -- The cpu component
  component cpu is
    port (imem_addr   : out m32_word;     -- Instruction memory address
          inst        : in  m32_word;     -- Instruction
          dmem_addr   : out m32_word;     -- Data memory address
          dmem_read   : out m32_1bit;     -- Data memory read?
          dmem_write  : out m32_1bit;     -- Data memory write?
          dmem_wmask  : out m32_4bits;    -- Data memory write mask
          dmem_rdata  : in  m32_word;     -- Data memory read data
          dmem_wdata  : out m32_word;     -- Data memory write data
          reg_write   : out m32_1bit;     -- FOR DEBUG: Register write or not
          reg_dst     : out m32_5bits;    -- FOR DEBUG: The no. of the register to write
          reg_wdata   : out m32_word;     -- FOR DEBUG: The register data to write
          inst_text   : out string (1 to 21); -- FOR DEBUG: The text format of the instruction
	  trace       : out m32_trace;	  -- For debugging the pipeline execution
          clock       : in  m32_1bit);    -- System clock
  end component;
  
  -- The memory component
  component mem is
    generic (
      depth_exp_of_2  : integer := 8;
      mif_filename    : string);
	  port (
	    address   : in  m32_vector(7 downto 0);
            byteena   : in  m32_vector(3 DOWNTO 0);
	    clock     : in  m32_1bit;
	    data      : in  m32_word;
	    wren      : in  m32_1bit;
	    q	      : out m32_word);
  end component;

  -- Configuration of components
  for cpu0 : cpu use entity work.cpu(scp);
  for cpu3 : cpu use entity work.cpu(pipeline);
  
  -- Interfaces for CPUs
  signal c0, c3 : cpu_interface;    -- Interaces for the reference CPU and the testing CPU

  -- Trace for CPU1
  signal t : m32_trace;

  -- Memory read data without delay
  signal imem_rdata0 : m32_word;
  signal imem_rdata1 : m32_word;
  signal dmem_rdata0 : m32_word;
  signal dmem_rdata1 : m32_word;

  -- CPU clock signals
  signal clock             : m32_1bit := '0';
  signal mem_clock         : m32_1bit;
  signal cpu0_clock        : m32_1bit;
  signal cpu0_clock_enable : m32_1bit := '1';

  -- CPU clock counter, to help debug
  signal clock_counter : integer := 0;

begin
  -- 
  -- The reference CPU and its memories
  --

  -- Data memory uses a different clock for writing. 
  -- This memory writes on falling clock edge.
  mem_clock <= not clock;

  -- The CPU with behavior modeling
  cpu0 : cpu
    port map (
      imem_addr  => c0.imem_addr, 
      inst 	 => c0.inst, 
      dmem_addr  => c0.dmem_addr, 
      dmem_read  => c0.dmem_read, 
      dmem_write => c0.dmem_write, 
      dmem_wmask => c0.dmem_wmask, 
      dmem_rdata => c0.dmem_rdata, 
      dmem_wdata => c0.dmem_wdata, 
      reg_write  => c0.reg_write, 
      reg_dst    => c0.reg_dst, 
      reg_wdata  => c0.reg_wdata, 
      inst_text  => c0.inst_text,
      clock      => cpu0_clock);

  -- The instruction memory. Note that it is a read-write memory with write disabled.
  imem0 : mem
    generic map (mif_filename => "imem-bubblesort.txt")
    port map (
      address => c0.imem_addr(9 downto 2), 
      byteena => "0000", 
      clock   => clock, 
      data    => x"00000000", 
      wren    => '0', 
      q       => imem_rdata0);
  c0.inst <= imem_rdata0;	-- No delay for the reference CPU

  -- The data memory, with a fixed latency in meory read
  dmem0 : mem
    generic map (mif_filename => "dmem-bubblesort.txt")
    port map (
      address => c0.dmem_addr(9 downto 2), 
      byteena => c0.dmem_wmask, 
      clock   => mem_clock, 
      data    => c0.dmem_wdata, 
      wren    => c0.dmem_write, 
      q       => dmem_rdata0);
  c0.dmem_rdata <= dmem_rdata0;  -- No delay for the reference CPU

  -- 
  -- The testing CPU and its memories
  --

  -- The CPU with structural modeling
  cpu3 : cpu
    port map (
      imem_addr  => c3.imem_addr, 
      inst	 => c3.inst, 
      dmem_addr  => c3.dmem_addr, 
      dmem_read  => c3.dmem_read, 
      dmem_write => c3.dmem_write, 
      dmem_wmask => c3.dmem_wmask, 
      dmem_rdata => c3.dmem_rdata, 
      dmem_wdata => c3.dmem_wdata, 
      reg_write  => c3.reg_write, 
      reg_dst    => c3.reg_dst, 
      reg_wdata  => c3.reg_wdata,
      inst_text  => c3.inst_text,
      trace      => t,
      clock      => clock);

  -- The instruction memory. Note that it is a read-write memory with write disabled.
  -- There is a fixed latency.
  imem3 : mem
    generic map (mif_filename => "imem-bubblesort.txt")
    port map (
      address => c3.imem_addr(9 downto 2), 
      byteena => "0000", 
      clock   => clock, 
      data    => x"00000000", 
      wren    => '0', 
      q       => imem_rdata1);
  c3.inst <= imem_rdata1 after MEM_DELAY;

  -- The data memory, with a fixed latency in meory read
  dmem3 : mem
    generic map (mif_filename => "dmem-bubblesort.txt")
    port map (
      address => c3.dmem_addr(9 downto 2), 
      byteena => c3.dmem_wmask, 
      clock   => mem_clock, 
      data    => c3.dmem_wdata, 
      wren    => c3.dmem_write, 
      q       => dmem_rdata1);
  c3.dmem_rdata <= dmem_rdata1 after MEM_DELAY;

  --
  -- Produce the clock signal
  --
  CLOCK_PROC : process 
  begin
    L1 : loop
       -- High for half cycle
       clock <= '1';
       wait for 0.5*CCT_PL;

       -- Low for half cycle
       clock <= '0';
       wait for 0.5*CCT_PL;

       -- Increase clock counter
       clock_counter <= clock_counter + 1;
    end loop;
  end process;

  -- Produce a special clock for cpu0, which advances only if the
  -- instruction from cpu1 is not actually a pipeline bubble.
  cpu0_clock <= cpu0_clock_enable and clock;
  
  --
  -- Test between cpu0 and cpu3.  
  -- ***NOTE*** The output from cpu3 is expected to be that of the instruction at 
  -- the WB stage.  If the instruction is actually a pipeline bubble, the content 
  -- of the inst_text must be "bubble".
  --
  TEST1 : process -- Check PC (current PC), register write, and memory write
    variable c0_reg_write, c3_reg_write : boolean;
  begin
    -- Wait until a rising clock edge arrives
    wait until rising_edge(clock);

    -- Wait right before the next rising clock edge
    wait for 19.9 ns;

    if not t.flushed then
      -- Compare current PC values
      if c0.imem_addr /= t.PC then
        report "PC (imem_addr) does not match." severity failure;
      end if;

      -- Compare register write; writing to $0 is not considered an actual write
      c0_reg_write := (c0.reg_write = '1') and (c0.reg_dst /= "00000");
      c3_reg_write := (t.o.reg_write = '1') and (t.o.reg_dst /= "00000");
      if c0_reg_write /= c3_reg_write or
            (c0_reg_write and (c0.reg_dst /= t.o.reg_dst or c0.reg_wdata /= t.o.reg_wdata)) then 
        report "Register write does not match." severity failure;
      end if;

      -- Compare memory write
      if c0.dmem_write /= t.o.dmem_write or 
            (c0.dmem_write = '1' and (c0.dmem_addr /= t.o.dmem_addr or
                                      c0.dmem_wmask /= t.o.dmem_wmask or
                                      c0.dmem_wdata /= t.o.dmem_wdata)) then
           -- FIXME We actually only have to compare memory data after masking
        report "Memory write does not match." severity failure;
      end if;

      -- Advance cpu0 clock
      cpu0_clock_enable <= '1';
    else
      -- If the WB instruction from cpu1 is actually a pipeline bubble, do not advance
      -- the clock of cpu0
      cpu0_clock_enable <= '1';
    end if;
  end process;
end behavior;
