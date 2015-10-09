 -- adder.vhd
 --
 -- The adders used for calculating PC-plus-4 and branch targets
 -- CprE 381
 --
 -- Zhao Zhang, Fall 2013
 --

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.mips32.all;

entity adder is
  generic (DELAY : time := 19.0 ns);
  port (src1    : in  m32_word;
        src2    : in  m32_word;
        result  : out m32_word);
end entity;

-- Behavior modeling of ADDER
architecture behavior of adder is
begin
  ADD : process (src1, src2)
    variable a : integer;
    variable b : integer;
    variable c : integer;
  begin
    -- Pre-calculate
    a := to_integer(signed(src1));
    b := to_integer(signed(src2));
    c := a + b;
    
    -- Convert integer to 32-bit signal
    result <= std_logic_vector(to_signed(c, result'length)) after DELAY;
  end process;
end behavior;
