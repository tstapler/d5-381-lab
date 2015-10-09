-- alu.vhd
-- 
-- The ALU unit
--
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.mips32.all;

entity ALU is
  generic (DELAY : time := 19.5 ns);
  port (data1    : in  m32_word;
        data2    : in  m32_word;
        alu_code : in  m32_4bits;
        result   : out m32_word;
        zero     : out m32_1bit);
end entity;

architecture behavior of ALU is
begin
  P_ALU : process (alu_code, data1, data2)
    variable r: m32_word;
    variable code, a, b, sum, diff, slt: integer;
  begin
    -- Pre-calculate arithmetic results
    a := to_integer(signed(data1));
    b := to_integer(signed(data2));
    sum := a + b;
    diff := a - b;
    if (a < b) then 
      slt := 1; 
    else 
      slt := 0;
    end if;
    
    -- Select the result, convert to signal if necessary
    -- The coding of alu_code is from Figure 4.12, P&H 5th, with extension
    case (alu_code) is
      ----------------------------------------------------------
      -- ADD YOUR NEW CODES FOR alu_code, SEE TEXTBOOK FIG 4.12
      ----------------------------------------------------------
      when "0010" =>      -- add
        r := std_logic_vector(to_signed(sum, 32));
      when "0110" =>      -- subtract
        r := std_logic_vector(to_signed(diff, 32));
      when others =>      -- Otherwise, make output to be 0
        r := (others => '0');
    end case;

    -- Drive the alu result output
    result <= r after DELAY;

    -- Drive the zero output
    if r = x"00000000" then
      zero <= '1' after DELAY;
    else
      zero <= '0' after DELAY;
    end if;
  end process;
end behavior;
