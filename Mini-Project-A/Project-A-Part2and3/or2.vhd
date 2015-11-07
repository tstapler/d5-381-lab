-------------------------------------------------------------------------
-- Joseph Zambreno
-- Department of Electrical and Computer Engineering
-- Iowa State University
-------------------------------------------------------------------------


-- or2.vhd
-------------------------------------------------------------------------
-- DESCRIPTION: This file contains an implementation of a 2-input OR 
-- gate.
--
--
-- NOTES:
-- 8/27/08 by JAZ::Design created.
-------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use work.mips32.all;

entity or2 is

  port(src1          : in m32_1bit;
       src2          : in m32_1bit;
       result          : out m32_1bit);

end or2;

architecture dataflow of or2 is
begin

  result <= src1 or src2;
  
end dataflow;
