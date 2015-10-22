--
-- tb_cpu.vhd: Test bench for CPU
--
library IEEE;
use IEEE.std_logic_1164.all;
use work.mips32.all;

entity tb_cpu0 is
end tb_cpu0;

architecture behavior of tb_cpu0 is
  -- The cpu component
  component cpu is
    port (
      imem_addr   : out m32_word;     -- Instruction memory address
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
      inst_text   : out string;	      -- FOR DEBUG: The text format of the instruction
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
      q	        : out m32_word);      
  end component;

  -- Configuration of components
  for cpu0 : cpu use entity work.cpu(behavioral);
  
  -- Interfaces for CPU except the clock
  signal c0 : cpu_interface;

  -- CPU clock signals
  signal clock     : m32_1bit := '0'; 
  signal mem_clock : m32_1bit;

  -- CPU clock counter, to help debug
  signal clock_counter : integer := 0;
begin
  -- The instruction memory. Note that it is a read-write memory with write disabled.
  imem0 : mem
    generic map (mif_filename =>
        "/home/tstapler/CPRE381/Mini-Project-A/Project-A-Part1/imem.txt")
    port map (
      address => c0.imem_addr(9 downto 2), 
      byteena => b"0000", 	-- Instruction is not to be written
      clock   => clock, 
      data    => x"00000000",   -- No write data
      wren    => '0', 		-- No write enable
      q       => c0.inst);

  -- The data memory. It uses a different clock for writing. The writing is expected 
  -- to happen in the last 20% of the clock cycle (20ns), so the memory block trails
  -- the CPU clock by 0.8*CCT. Additionally, this memory writes on falling clock edge,
  -- so we also need to invert the clock.
  mem_clock <= transport not clock after 0.8*CCT;
  dmem0 : mem
    generic map (mif_filename => "/home/tstapler/CPRE381/Mini-Project-A/Project-A-Part1/dmem-sample.txt")
    port map (
      address => c0.dmem_addr(9 downto 2), 
      byteena => c0.dmem_wmask, 
      clock   => mem_clock, 
      data    => c0.dmem_wdata, 
      wren    => c0.dmem_write, 
      q       => c0.dmem_rdata);

  -- The CPU
  cpu0 : cpu
    port map (
      imem_addr  => c0.imem_addr, 
      inst       => c0.inst, 
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
      clock      => clock);

  -- Produce the clock signal
  CLOCK_PROC : process 
  begin
    L1 : loop
       -- High for half cycle
       clock <= '1';
       wait for 0.5*CCT;

       -- Low for half cycle
       clock <= '0';
       wait for 0.5*CCT;

       -- Increase clock counter
       clock_counter <= clock_counter + 1;
    end loop;
  end process;

end behavior;
