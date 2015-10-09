-- regfile.vhd: Register file for the MIPS processor
--
-- Zhao Zhang, Fall 2013
--

--
-- MIPS regfile, clock version for SCP
--
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.mips32.all;

entity regfile is
  generic (DELAY : time := 9.5 ns);
  port(src1   : in  m32_5bits;
       src2   : in  m32_5bits;
       dst    : in  m32_5bits;
       wdata  : in  m32_word;
       rdata1 : out m32_word;
       rdata2 : out m32_word;
       WE     : in  m32_1bit;
       clock  : in  m32_1bit);
end regfile;

architecture behavior of regfile is
  signal reg_array : m32_regval_array := (others => x"00000000");
begin
  -- Register reset/write logic, guarded by clock rising edge
  P_WRITE : process (clock)
    variable r : integer;
  begin
    -- Write/reset logic. It is guarded by clock.
    if (rising_edge(clock)) then
      if (WE = '1') then
        r := to_integer(unsigned(dst));
        if r /= 0 then         -- Don't write to $0
          reg_array(r) <= wdata;
        end if;
      end if;
    end if;
  end process;
  
  -- Register read logic. It is not clocked.
  P_READ : process (reg_array, src1, src2)
    variable r1, r2 : integer;
  begin
    -- Convert src1 and src2 to integer type
    r1 := to_integer(unsigned(src1));
    r2 := to_integer(unsigned(src2));

    -- Read r1, return fixed zero if r1 = 0
    if r1 /= 0 then
      rdata1 <= reg_array(r1) after DELAY;
    else
      rdata1 <= x"00000000" after DELAY;
    end if;

    -- Read r2, return fixed zero if r1 = 0
    if r2 /= 0 then
      rdata2 <= reg_array(r2) after DELAY;
    else
      rdata2 <= x"00000000" after DELAY;
    end if;
  end process;
end behavior;
