library IEEE;
use IEEE.std_logic_1164.all;

entity n_in_lab3_multiplexer is
    generic(N : integer := 32);
    port(i_A  : in std_logic_vector(N-1 downto 0);
         i_B  : in std_logic_vector(N-1 downto 0);
         i_C  : in std_logic;
         o_F  : out std_logic_vector(N-1 downto 0));
end n_in_lab3_multiplexer;

architecture dataflow of n_in_lab3_multiplexer is

begin 

    G1: for i in 0 to N-1 generate
       o_F(i) <= (i_A(i) and not i_C) or (i_C and i_B(i));
    end generate;
end dataflow;
