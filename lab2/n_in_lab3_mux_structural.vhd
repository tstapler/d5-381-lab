library IEEE;
use IEEE.std_logic_1164.all;
entity n_in_multiplexer is 
    generic(N : integer := 32);
            port(i_A  : in std_logic_vector(N-1 downto 0);
                 i_B  : in std_logic_vector(N-1 downto 0);
                 i_C  : in std_logic_vector(N-1 downto 0);
                 o_F  : out std_logic_vector(N-1 downto 0));
        end n_in_multiplexer; 
architecture structure of n_in_multiplexer is

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

    signal sVALUE_Ax, sVALUE_Bx, sVALUE_Cx : std_logic_vector(N-1 downto 0);

begin

    G1: for i in 0 to N-1 generate
        g_not_i: inv
        port MAP(i_A => i_C,
                 o_F => sVALUE_Ax(i));

        g_and1_i: and2
        port MAP(i_A => i_A(i),
                 i_B => sVALUE_Ax(i),
                 o_F => sVALUE_Bx(i));

        g_and2_i: and2
        port MAP(i_A => i_C,
                 i_B => i_B(i),
                 o_F => sVALUE_Cx(i));

        g_or_i: or2
        port MAP(i_A => sVALUE_Bx(i),
                 i_B => sVALUE_Cx(i),
                 o_F => o_F(i));
    end generate;

end structure;
