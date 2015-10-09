-------------------------------------------------------------------------
-- Joseph Zambreno
-- Department of Electrical and Computer Engineering
-- Iowa State University
-------------------------------------------------------------------------


-- Quadratic.vhd
-------------------------------------------------------------------------
-- DESCRIPTION: This file contains an implementation of the Quadratic
-- equation Ax^2+Bx+C using invidual adder and multiplier units.
--
--
-- NOTES:
-- 8/19/09 by JAZ::Design created.
-------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;


entity Quadratic is

  port(iCLK             : in std_logic;
       iX 		            : in integer;
       oY 		            : out integer);

end Quadratic;

architecture structure of Quadratic is
  
  -- Describe the component entities as defined in Adder.vhd 
  -- and Multiplier.vhd (not strictly necessary).
  component Adder
    port(iCLK           : in std_logic;
         iA             : in integer;
         iB             : in integer;
         oC             : out integer);
  end component;

  component Multiplier
    port(iCLK           : in std_logic;
         iA             : in integer;
         iB             : in integer;
         oC             : out integer);
  end component;

  -- Arbitrary constants for the A, B, C values. No need to change these.
  constant cA : integer := 5;
  constant cB : integer := 23;
  constant cC : integer := 2;

  -- Signals to store A*x, B*x
  signal sVALUE_Ax, sVALUE_Bx : integer;
  -- Signal to store A*x*x
  signal sVALUE_Axx 	         : integer;
  -- Signal to store B*x+C
  signal sVALUE_BxpC          : integer;

begin

  
  ---------------------------------------------------------------------------
  -- Level 1: Calculate A*x, B*x
  ---------------------------------------------------------------------------
  g_Mult1: Multiplier
    port MAP(iCLK             => iCLK,
             iA               => cA,
             iB               => iX,
             oC               => sVALUE_Ax);

  g_Mult2: Multiplier
    port MAP(iCLK             => iCLK,
             iA               => cB,
             iB               => iX,
             oC               => sVALUE_Bx);
    
 ---------------------------------------------------------------------------
  -- Level 2: Calculate A*x*x, B*x+C
  ---------------------------------------------------------------------------
  g_Mult3: Multiplier
    port MAP(iCLK             => iCLK,
             iA               => sVALUE_Ax,
             iB               => iX,
             oC               => sVALUE_Axx);

  g_Add1: Adder
    port MAP(iCLK             => iCLK,
             iA               => sVALUE_Bx,
             iB               => cC,
             oC               => sVALUE_BxpC);
    
  ---------------------------------------------------------------------------
  -- Level 3: Calculate A*x*x + B*x + C
  ---------------------------------------------------------------------------
  g_Add2: Adder
    port MAP(iCLK             => iCLK,
             iA               => sVALUE_Axx,
             iB               => sVALUE_BxpC,
             oC               => oY);
  
end structure;
