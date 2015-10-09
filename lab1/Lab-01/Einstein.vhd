library IEEE;
use IEEE.std_logic_1164.all;

entity Einstein is
    port(iCLK       : in std_logic;
        iM          : in integer;
        oE          : out integer);
end Einstein;

architecture structure of Einstein is

  component Multiplier
    port(iCLK           : in std_logic;
         iA             : in integer;
         iB             : in integer;
         oC             : out integer);
  end component;
    constant cC : integer := 9487;

    signal sVALUE_Ax : integer;

begin
  g_Mult1: Multiplier
    port MAP(iCLK             => iCLK,
             iA               => cC,
             iB               => cC,
             oC               => sVALUE_Ax);


  g_Mult2: Multiplier
    port MAP(iCLK             => iCLK,
             iA               => sVALUE_Ax,
             iB               => iM,
             oC               => oE);

end structure;
