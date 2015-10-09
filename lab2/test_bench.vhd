library IEEE;
use IEEE.std_logic_1164.all;


entity test_bench is

    end test_bench;

architecture behavior of test_bench is 

    component ones_compliment_structure
        generic(N : integer:= 12);
        port(i_A  : in std_logic_vector(N-1 downto 0);
        o_B  : out std_logic_vector(N-1 downto 0));
    end component;
    
    component ones_compliment_data
        generic(N : integer:= 12);
        port(i_A  : in std_logic_vector(N-1 downto 0);
        o_B  : out std_logic_vector(N-1 downto 0));
    end component;
    --declare inputs and initialize?

    signal in1: std_logic_Vector(11 downto 0):="110011001100";
    signal out1: std_logic_Vector(11 downto 0);
    signal out2: std_logic_Vector(11 downto 0);
begin
    uut1: entity work.ones_compliment_structure(N => 12) port map(in1, out1);
    uut2: entity work.ones_compliment_structure(N => 12) port map(in1, out2);

end behavior;

