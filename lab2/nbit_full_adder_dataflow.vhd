library IEEE;
use IEEE.std_logic_1164.all;

entity n_bit_full_adder_dataf is
    generic(N : integer := 32);
    port(i_A  : in std_logic_vector(N-1 downto 0);
         i_B  : in std_logic_vector(N-1 downto 0);
         i_C  : in std_logic;
         o_F  : out std_logic_vector(N-1 downto 0);
         o_C  : out std_logic);
end n_bit_full_adder_dataf;



architecture dataflow of n_bit_full_adder_dataf is

signal sVALUE_Ax :std_logic_vector(N-2 downto 0);

begin 
  
  o_F(0) <= ((i_A(0) XOR i_B(0)) XOR i_C);
  sVALUE_Ax(0) <= (((i_A(0) XOR i_B(0)) AND i_C) OR (i_A(0) AND i_B(0)));
  
  G1: for i in 1 to N-2 generate
    o_F(i) <= (i_A(i) XOR i_B(i)) XOR sVALUE_Ax(i-1);
    sVALUE_Ax(i) <= (((i_A(i) XOR i_B(i)) AND sVALUE_Ax(i-1)) OR (i_A(i) AND i_B(i)));
  end generate;
  
  o_F(N-1) <= ((i_A(N-1) XOR i_B(N-1)) XOR sVALUE_Ax(N-2));
  o_C <= (((i_A(N-1) XOR i_B(N-1)) AND sVALUE_Ax(N-2)) OR (i_A(N-1) AND i_B(N-1)));
  
  
end dataflow;
  