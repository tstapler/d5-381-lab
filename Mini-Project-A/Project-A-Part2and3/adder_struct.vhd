 -- adder.vhd
 --
 -- The adders used for calculating PC-plus-4 and branch targets
 -- CprE 381
 --
 -- Zhao Zhang, Fall 2013
 --

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.mips32.all;

entity adder is
  generic (DELAY : time := 19.0 ns; N : integer := 32);
  port (src1    : in  m32_word;
        src2    : in  m32_word;
        result  : out m32_word);
end entity;

-- Behavior modeling of ADDER
architecture structural of adder is

    component and2
      port(src1          : in std_logic;
           src2          : in std_logic;
           result          : out std_logic);

    end component;

    component xor2 
      port(src1          : in std_logic;
           src2          : in std_logic;
           result          : out std_logic);

    end component;

    component or2
      port(src1          : in std_logic;
           src2          : in std_logic;
           result          : out std_logic);
    end component;
    
    signal sVALUE_Ax, sVALUE_Bx, sVALUE_Cx : std_logic_vector(N-1 downto 0);
    signal sVALUE_Dx : std_logic_vector(N-2 downto 0);

begin

    g_xor: xor2
        port MAP(src1 => src1(0),
                 src2 => src2(0),
                 result => sVALUE_Ax(0));

    g_xor_2: xor2
        port MAP(src1 => sVALUE_Ax(0),
                 src2 => '0',
                 result => result(0));

    g_and_1: and2
        port MAP(src1 => '0',
                src2 => sVALUE_Ax(0),
                result => sVALUE_Bx(0));

    g_and_2: and2
        port MAP(src1 => src1(0),
                src2 => src2(0),
                result => sVALUE_Cx(0));

    g_or: or2
        port MAP(src1 => sVALUE_Bx(0),
                src2 => sVALUE_Cx(0),
                result => sVALUE_Dx(0));

G1: for i in 1 to N-2 generate
    g_xor1_i: xor2
        port MAP(src1 => src1(i),
                 src2 => src2(i),
                 result => sVALUE_Ax(i));

    g_xor2_i: xor2
        port MAP(src1 => sVALUE_Ax(i),
                 src2 => sVALUE_Dx(i-1),
                 result => result(i));

    g_and1_i: and2
        port MAP(src1 => sVALUE_Dx(i-1),
                src2 => sVALUE_Ax(i),
                result => sVALUE_Bx(i));

    g_and2_i: and2
        port MAP(src1 => src1(i),
                src2 => src2(i),
                result => sVALUE_Cx(i));

    g_or_i: or2
        port MAP(src1 => sVALUE_Bx(i),
                src2 => sVALUE_Cx(i),
                result => sVALUE_Dx(i));
end generate;

    g_xor5: xor2
        port MAP(src1 => src1(N-1),
                 src2 => src2(N-1),
                 result => sVALUE_Ax(N-1));

    g_xor_5: xor2
        port MAP(src1 => sVALUE_Ax(N-1),
                 src2 => sVALUE_Dx(N-2),
                 result => result(N-1));

    g_and_5: and2
        port MAP(src1 => sVALUE_Dx(N-2),
                src2 => sVALUE_Ax(N-1),
                result => sVALUE_Bx(N-1));

    g_and_6: and2
        port MAP(src1 => src1(N-1),
                src2 => src2(N-1),
                result => sVALUE_Cx(N-1));

end structural;
