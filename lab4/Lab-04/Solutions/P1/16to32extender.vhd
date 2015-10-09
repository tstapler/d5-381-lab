library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;

entity extender16_to_32 is
    port(bits : in std_logic_vector(15 downto 0);
         zero_extend : in  std_logic; -- Sign Extension or Zero Extension 1 is Zero
         outbits : out std_logic_vector(31 downto 0)
         );
end extender16_to_32;

architecture behavior of extender16_to_32 is
begin
        --Extend the sign bit by 16 bits, if zero extend isn't enabled extend all zeros
        --otherwise extend the current sign
        outbits <=  (31 downto 16 => bits(15) and zero_extend) & bits;
end behavior;


