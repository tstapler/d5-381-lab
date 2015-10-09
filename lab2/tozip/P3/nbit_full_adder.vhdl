library IEEE;
use IEEE.std_logic_1164.all;

entity nbit_full_adder  is 
    generic (N : integer := 32);
    port(i_A  : in std_logic_vector(N-1 downto 0);
         i_B  : in std_logic_vector(N-1 downto 0);
         i_C  : in std_logic;
         o_F  : out std_logic_vector(N-1 downto 0);
         o_C  : out std_logic);

end nbit_full_adder; 

architecture structure of nbit_full_adder is

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
    
    signal sVALUE_Ax, sVALUE_Bx, sVALUE_Cx : std_logic_vector(N-1 downto 0);
    signal sVALUE_Dx : std_logic_vector(N-2 downto 0);

begin

    g_xor: xor2
        port MAP(i_A => i_A(0),
                 i_B => i_B(0),
                 o_F => sVALUE_Ax(0));

    g_xor_2: xor2
        port MAP(i_A => sVALUE_Ax(0),
                 i_B => i_C,
                 o_F => o_F(0));

    g_and_1: and2
        port MAP(i_A => i_C,
                i_B => sVALUE_Ax(0),
                o_F => sVALUE_Bx(0));

    g_and_2: and2
        port MAP(i_A => i_A(0),
                i_B => i_B(0),
                o_F => sVALUE_Cx(0));

    g_or: or2
        port MAP(i_A => sVALUE_Bx(0),
                i_B => sVALUE_Cx(0),
                o_F => sVALUE_Dx(0));

G1: for i in 1 to N-2 generate
    g_xor1_i: xor2
        port MAP(i_A => i_A(i),
                 i_B => i_B(i),
                 o_F => sVALUE_Ax(i));

    g_xor2_i: xor2
        port MAP(i_A => sVALUE_Ax(i),
                 i_B => sVALUE_Dx(i-1),
                 o_F => o_F(i));

    g_and1_i: and2
        port MAP(i_A => sVALUE_Dx(i-1),
                i_B => sVALUE_Ax(i),
                o_F => sVALUE_Bx(i));

    g_and2_i: and2
        port MAP(i_A => i_A(i),
                i_B => i_B(i),
                o_F => sVALUE_Cx(i));

    g_or_i: or2
        port MAP(i_A => sVALUE_Bx(i),
                i_B => sVALUE_Cx(i),
                o_F => sVALUE_Dx(i));
end generate;

    g_xor5: xor2
        port MAP(i_A => i_A(N-1),
                 i_B => i_B(N-1),
                 o_F => sVALUE_Ax(N-1));

    g_xor_5: xor2
        port MAP(i_A => sVALUE_Ax(N-1),
                 i_B => sVALUE_Dx(N-2),
                 o_F => o_F(N-1));

    g_and_5: and2
        port MAP(i_A => sVALUE_Dx(N-2),
                i_B => sVALUE_Ax(N-1),
                o_F => sVALUE_Bx(N-1));

    g_and_6: and2
        port MAP(i_A => i_A(N-1),
                i_B => i_B(N-1),
                o_F => sVALUE_Cx(N-1));

    g_or5: or2
        port MAP(i_A => sVALUE_Bx(N-1),
                i_B => sVALUE_Cx(N-1),
                o_F => o_C);

end structure;
