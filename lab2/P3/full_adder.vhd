library IEEE;
use IEEE.std_logic_1164.all;

entity full_adder  is 
    port(i_A  : in std_logic;
         i_B  : in std_logic;
         i_C  : in std_logic;
         o_F  : out std_logic;
         o_C  : out std_logic);

end full_adder; 

architecture structure of full_adder is

    component and2
      port(i_A          : in std_logic;
           i_B          : in std_logic;
           o_F          : out std_logic);

    end component;

    component xor2 
      port(i_A          : in std_logic;
           i_B          : in std_logic;
           o_F          : out std_logic);

    end component;

    component or2
      port(i_A          : in std_logic;
           i_B          : in std_logic;
           o_F          : out std_logic);

    end component;
    
    signal sVALUE_Ax, sVALUE_Bx, sVALUE_Cx : std_logic;

begin

    g_xor1: xor2
        port MAP(i_A => i_A,
                 i_B => i_B,
                 o_F => sVALUE_Ax);

    g_xor2: xor2
        port MAP(i_A => sVALUE_Ax,
                 i_B => i_C,
                 o_F => o_F);

    g_and1_i: and2
        port MAP(i_A => i_C,
                i_B => sVALUE_Ax,
                o_F => sVALUE_Bx);

    g_and2_i: and2
        port MAP(i_A => i_A,
                i_B => i_B,
                o_F => sVALUE_Cx);

    g_or_i: or2
        port MAP(i_A => sVALUE_Bx,
                i_B => sVALUE_Cx,
                o_F => o_C);

end structure;
