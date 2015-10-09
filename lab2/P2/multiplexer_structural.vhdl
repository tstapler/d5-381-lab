library IEEE;
use IEEE.std_logic_1164.all;
entity two_in_multiplexer is 
port(	i_A  : in std_logic; 
	i_B  : in std_logic; 
	i_C  : in std_logic; 
	o_F  : out std_logic); 

end two_in_multiplexer; 

architecture structure of two_in_multiplexer is

    component and2
      port(i_A          : in std_logic;
           i_B          : in std_logic;
           o_F          : out std_logic);

    end component;

    component inv 
      port(i_A          : in std_logic;
           o_F          : out std_logic);

    end component;

    component or2
      port(i_A          : in std_logic;
           i_B          : in std_logic;
           o_F          : out std_logic);

    end component;
    
    signal sVALUE_Ax, sVALUE_Bx, sVALUE_Cx : std_logic;

begin

    g_not: inv
        port MAP(i_A => i_C,
                 o_F => sVALUE_Ax);

    g_and1: and2
        port MAP(i_A => i_A,
                i_B => sVALUE_Ax,
                o_F => sVALUE_Bx);

    g_and2: and2
        port MAP(i_A => i_C,
                i_B => i_B,
                o_F => sVALUE_Cx);

    g_or: or2
        port MAP(i_A => sVALUE_Bx,
                i_B => sVALUE_Cx,
                o_F => o_F);

end structure;
