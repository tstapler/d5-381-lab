library IEEE;
use IEEE.std_logic_1164.all;

entity n_in_dataflow_multiplexer is
    generic(N : integer := 32);
    port(i_A  : in std_logic_vector(N-1 downto 0);
         i_B  : in std_logic_vector(N-1 downto 0);
         i_C  : in std_logic_vector(N-1 downto 0);
         o_F  : out std_logic_vector(N-1 downto 0));
end n_in_dataflow_multiplexer;

architecture dataflow of n_in_dataflow_multiplexer is

begin 

    G1: for i in 0 to N-1 generate
       o_F <= (i_A and not i_C) or (i_C and i_B);
    end generate;
end dataflow;
