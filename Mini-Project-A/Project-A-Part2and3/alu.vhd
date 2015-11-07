-- alu.vhd
-- 
-- The ALU unit
--
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.math_real.all;
use work.mips32.all;

entity ALU is
  generic (DELAY : time := 19.5 ns);
  port (data1    : in  m32_word;
        data2    : in  m32_word;
        alu_code : in  m32_4bits;
        shamt    : in  m32_5bits;
        result   : out m32_word;
        zero     : out m32_1bit);
end entity;

architecture behavior of ALU is
begin
  P_ALU : process (alu_code, data1, data2, shamt)
    variable r: m32_word;
    variable code, a, b, sum, diff, slt, int_shamt: integer;
    variable and_result, or_result: m32_word;
    variable sll_result : std_logic_vector (31 downto 0);

  begin
    -- Pre-calculate arithmetic results
    a := to_integer(signed(data1));
    b := to_integer(signed(data2));
    int_shamt := to_integer(unsigned(shamt));

    sum := a + b;
    diff := a - b;
    and_result := data1 and data2;
    or_result := data1 or data2;

    if (a < b) then 
      slt := 1; 
    else 
      slt := 0;
    end if;

    sll_result := std_logic_vector(shift_left(unsigned(data2), int_shamt));
    
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
      when "0000" =>      -- and
        r := std_logic_vector(and_result);
      when "0001" =>      -- or
        r := std_logic_vector(or_result);
      when "0111" =>      -- slt
        r := std_logic_vector(to_signed(slt, 32));
      when "0100" =>      -- sll
        r := sll_result;
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
