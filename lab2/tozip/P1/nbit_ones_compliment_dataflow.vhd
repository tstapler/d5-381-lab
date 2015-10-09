library IEEE;
use IEEE.std_logic_1164.all;

entity ones_compliment_data is
    generic(N : integer := 12);
  port(i_A  : in std_logic_vector(N-1 downto 0);
       o_B  : out std_logic_vector(N-1 downto 0));

end ones_compliment_data;

architecture dataflow of ones_compliment_data is

begin

G1: for i in 0 to N-1 generate
    o_B <= not i_A;
end generate;

end dataflow;
