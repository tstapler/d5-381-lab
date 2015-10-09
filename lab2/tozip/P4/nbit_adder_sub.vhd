library IEEE;
use IEEE.std_logic_1164.all;

entity nbit_adder_sub  is 
    generic (N : integer := 8);
    port(i_A  : in std_logic_vector(N-1 downto 0);
         i_B  : in std_logic_vector(N-1 downto 0);
         n_Add_Sub  : in std_logic;
         o_F  : out std_logic_vector(N-1 downto 0);
         o_C  : out std_logic);

end nbit_adder_sub; 

architecture structure of nbit_adder_sub is

  component inv
      port(i_A          : in std_logic;
           o_F          : out std_logic);
             
  end component;
  
  component two_in_multiplexer
      port(i_A  : in std_logic; 
           i_B  : in std_logic; 
           i_C  : in std_logic; 
           o_F  : out std_logic);
           
  end component;
  
  component full_adder
      port(i_A  : in std_logic;
           i_B  : in std_logic;
           i_C  : in std_logic;
           o_F  : out std_logic;
           o_C  : out std_logic);
           
  end component;

signal sVALUE_Ax, sVALUE_Bx : std_logic_vector(N-1 downto 0);
signal sVALUE_Cx : std_logic_vector(N-1 downto 0);

  
begin
  
  g_inv1: inv
    port MAP(i_A => i_A(0),
             o_F => sVALUE_Ax(0));
             
  g_mux1: two_in_multiplexer
    port MAP(i_B => sVALUE_Ax(0),
             i_A => i_A(0),
             i_C => n_Add_Sub,
             o_F => sVALUE_Bx(0));
             
  g_fullAdd1: full_adder
    port MAP(i_A => sVALUE_Bx(0),
             i_B => i_B(0),
             i_C => n_Add_Sub,
             o_F => o_F(0),
             o_C => sVALUE_Cx(0));
             
G1: for i in 1 to N-2 generate
  
    g_inv2: inv
      port MAP(i_A => i_A(i),
             o_F => sVALUE_Ax(i));
             
    g_mux2: two_in_multiplexer
      port MAP(i_B => sVALUE_Ax(i),
             i_A => i_A(i),
             i_C => n_Add_Sub,
             o_F => sVALUE_Bx(i));
             
    g_fullAdd2: full_adder
      port MAP(i_A =>sVALUE_Bx(i),
             i_B =>i_B(i),
             i_C => sVALUE_Cx(i-1),
             o_F =>o_F(i),
             o_C =>sVALUE_Cx(i));        

end generate;

  g_inv3: inv
    port MAP(i_A => i_A(N-1),
             o_F => sVALUE_Ax(N-1));
             
  g_mux3: two_in_multiplexer
    port MAP(i_B => sVALUE_Ax(N-1),
             i_A => i_A(N-1),
             i_C => n_Add_Sub,
             o_F => sVALUE_Bx(N-1));
             
  g_fullAdd3: full_adder
    port MAP(i_A =>sVALUE_Bx(N-1),
             i_B =>i_B(N-1),
             i_C => sVALUE_Cx(N-2),
             o_F =>o_F(N-1),
             o_C =>o_C);
             
end structure;