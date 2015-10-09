library IEEE;
use IEEE.std_logic_1164.all;

entity ones_compliment_structure is
    generic(N : integer := 12);
  port(i_A  : in std_logic_vector(N-1 downto 0);
       o_B  : out std_logic_vector(N-1 downto 0));

end ones_compliment_structure;

architecture structure of ones_compliment_structure is

    component inv
  port(i_A  : in std_logic;
       o_F  : out std_logic);
    end component;

begin

G1: for i in 0 to N-1 generate
  inv_i: inv 
    port map(i_A  => i_A(i),
  	          o_F  => o_B(i));
end generate;

end structure;
