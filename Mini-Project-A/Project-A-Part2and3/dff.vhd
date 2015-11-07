-------------------------------------------------------------------------
-- Joseph Zambreno
-- Department of Electrical and Computer Engineering
-- Iowa State University
-------------------------------------------------------------------------


-- dff.vhd
-------------------------------------------------------------------------
-- DESCRIPTION: This file contains an implementation of an edge-triggered
-- flip-flop with parallel access and reset.
--
--
-- NOTES:
-- 9/07/08 by JAZ::Design created.
-------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use work.mips32.all;

entity dff is

  port(i_CLK        : in m32_1bit;     -- Clock input
       i_RST        : in m32_1bit;     -- Reset input
       i_WE         : in m32_1bit;     -- Write enable input
       i_D          : in m32_1bit := '0';     -- Data value input
       o_Q          : out m32_1bit := '0');   -- Data value output

end dff;

architecture mixed of dff is
  signal s_D    : m32_1bit;    -- Multiplexed input to the FF
  signal s_Q    : m32_1bit;    -- Output of the FF

begin

  -- The output of the FF is fixed to s_Q
  o_Q <= s_Q;
  
  -- Create a multiplexed input to the FF based on i_WE
  with i_WE select
    s_D <= i_D when '1',
           s_Q when others;
  
  -- This process handles the asyncrhonous reset and
  -- synchronous write. We want to be able to reset 
  -- our processor's registers so that we minimize
  -- glitchy behavior on startup.
  process (i_CLK, i_RST)
  begin
    if (i_RST = '1') then
      s_Q <= '0'; -- Use "(others => '0')" for N-bit values
    elsif (rising_edge(i_CLK)) then
      s_Q <= s_D;
    end if;

  end process;
  
end mixed;
