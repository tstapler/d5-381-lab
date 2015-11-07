--
-- tb_cpu1.vhd: Test bench for SCP
--
library IEEE;
use IEEE.std_logic_1164.all;
use work.mips32.all;

entity tb_cpu1 is
  generic (MEM_DELAY : time := 19.5 ns);
end tb_cpu1;

architecture behavior of tb_cpu1 is
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
  for cpu0 : cpu use entity work.cpu(behavioral);
  for cpu1 : cpu use entity work.cpu(scp);
  
  -- Interfaces for CPUs
  signal c0, c1 : cpu_interface;    -- Interaces for the reference CPU and the testing CPU

  -- Memory read data without delay
  signal imem_rdata0 : m32_word;
  signal imem_rdata1 : m32_word;
  signal dmem_rdata0 : m32_word;
  signal dmem_rdata1 : m32_word;

  -- CPU clock signals
  signal clock     : m32_1bit := '0'; 
  signal mem_clock : m32_1bit;

  -- CPU clock counter, to help debug
  signal clock_counter : integer := 0;
begin
  -- 
  -- The reference CPU and its memories
  --

  -- Data memory uses a different clock for writing. The writing is expected 
  -- to happen in the last 20% of the clock cycle (20ns), so the memory block trails
  -- the CPU clock by 0.8*CCT. Additionally, this memory writes on falling clock edge,
  -- so we also need to invert the clock.
  mem_clock <= transport not clock after 0.8*CCT;

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
      clock      => clock);

  -- The instruction memory. Note that it is a read-write memory with write disabled.
  imem0 : mem
    generic map (mif_filename => "/home/tstapler/CPRE381/Mini-Project-A/Project-A-Part1/imem.txt")
    port map (
      address => c0.imem_addr(9 downto 2), 
      byteena => "0000", 
      clock   => clock, 
      data    => x"00000000", 
      wren    => '0', 
      q       => imem_rdata0);
  c0.inst <= imem_rdata0 after MEM_DELAY;

  -- The data memory, with a fixed latency in meory read
  dmem0 : mem
    generic map (mif_filename => "/home/tstapler/CPRE381/Mini-Project-A/Project-A-Part1/dmem.txt")
    port map (
      address => c0.dmem_addr(9 downto 2), 
      byteena => c0.dmem_wmask, 
      clock   => mem_clock, 
      data    => c0.dmem_wdata, 
      wren    => c0.dmem_write, 
      q       => dmem_rdata0);
  c0.dmem_rdata <= dmem_rdata0 after MEM_DELAY;

  -- 
  -- The testing CPU and its memories
  --

  -- The CPU with structural modeling
  cpu1 : cpu
    port map (
      imem_addr  => c1.imem_addr, 
      inst	 => c1.inst, 
      dmem_addr  => c1.dmem_addr, 
      dmem_read  => c1.dmem_read, 
      dmem_write => c1.dmem_write, 
      dmem_wmask => c1.dmem_wmask, 
      dmem_rdata => c1.dmem_rdata, 
      dmem_wdata => c1.dmem_wdata, 
      reg_write  => c1.reg_write, 
      reg_dst    => c1.reg_dst, 
      reg_wdata  => c1.reg_wdata,
      clock      => clock);

  -- The instruction memory. Note that it is a read-write memory with write disabled.
  -- There is a fixed latency.
  imem1 : mem
    generic map (mif_filename =>
        "/home/tstapler/CPRE381/Mini-Project-A/Project-A-Part1/imem.txt")
    port map (
      address => c1.imem_addr(9 downto 2), 
      byteena => "0000", 
      clock   => clock, 
      data    => x"00000000", 
      wren    => '0', 
      q       => imem_rdata1);
  c1.inst <= imem_rdata1 after MEM_DELAY;

  -- The data memory, with a fixed latency in meory read
  dmem1 : mem
    generic map (mif_filename => "/home/tstapler/CPRE381/Mini-Project-A/Project-A-Part1/dmem.txt")
    port map (
      address => c1.dmem_addr(9 downto 2), 
      byteena => c0.dmem_wmask, 
      clock   => mem_clock, 
      data    => c1.dmem_wdata, 
      wren    => c1.dmem_write, 
      q       => dmem_rdata1);
  c1.dmem_rdata <= dmem_rdata1 after MEM_DELAY;

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
  
  --
  -- Test between cpu0 and cpu1, it's done right before the 
  --
  TEST1 : process -- Check PC and register write
    variable c0_reg_write, c1_reg_write : boolean;
  begin
    -- Wait until a rising clock edge arrives
    wait until rising_edge(clock);

    -- Wait right before the next rising clock edge
    wait for 0.99 * CCT;

    -- Compare current PC values
    if c0.imem_addr /= c1.imem_addr then
      report "PC (imem_addr) does not match." severity failure;
    end if;

    -- Compare register write; writing to $0 is not considered an actual write
    c0_reg_write := (c0.reg_write = '1') and (c0.reg_dst /= "00000");
    c1_reg_write := (c1.reg_write = '1') and (c1.reg_dst /= "00000");
    if c0_reg_write /= c1_reg_write or
          (c0_reg_write and (c0.reg_dst /= c1.reg_dst or c0.reg_wdata /= c1.reg_wdata)) then 
      report "Register write does not match." severity failure;
    end if;
  end process;

  TEST2 : process  -- Compare data memory write
  begin
    -- Wait until a falling memory clock edge arrives
    wait until falling_edge(mem_clock);

    if c0.dmem_write /= c1.dmem_write or 
          (c0.dmem_write = '1' and (c0.dmem_addr /= c1.dmem_addr or
                                    c0.dmem_wmask /= c1.dmem_wmask or
                                    c0.dmem_wdata /= c1.dmem_wdata)) then
         -- FIXME We actually only have to compare memory data after masking
      report "Memory write does not match." severity failure;
    end if;
  end process;

end behavior;
