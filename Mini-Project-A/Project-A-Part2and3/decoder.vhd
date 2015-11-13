library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all ;
use IEEE.std_logic_arith.all;
use work.mips32.all;


entity decoder5to32 is

    port (i_D  : in m32_5bits := "00000";
          o_D  : out m32_word := x"00000000");
end decoder5to32;

architecture mixed of decoder5to32 is

begin

    with i_D select
        o_D <= 
              "00000000000000000000000000000001" when "00000",
              "00000000000000000000000000000010" when "00001",
              "00000000000000000000000000000100" when "00010",
              "00000000000000000000000000001000" when "00011",
              "00000000000000000000000000010000" when "00100",
              "00000000000000000000000000100000" when "00101",
              "00000000000000000000000001000000" when "00110",
              "00000000000000000000000010000000" when "00111",
              "00000000000000000000000100000000" when "01000",
              "00000000000000000000001000000000" when "01001",
              "00000000000000000000010000000000" when "01010",
              "00000000000000000000100000000000" when "01011",
              "00000000000000000001000000000000" when "01100",
              "00000000000000000010000000000000" when "01101",
              "00000000000000000100000000000000" when "01110",
              "00000000000000001000000000000000" when "01111",
              "00000000000000010000000000000000" when "10000",
              "00000000000000100000000000000000" when "10001",
              "00000000000001000000000000000000" when "10010",
              "00000000000010000000000000000000" when "10011",
              "00000000000100000000000000000000" when "10100",
              "00000000001000000000000000000000" when "10101",
              "00000000010000000000000000000000" when "10110",
              "00000000100000000000000000000000" when "10111",
              "00000001000000000000000000000000" when "11000",
              "00000010000000000000000000000000" when "11001",
              "00000100000000000000000000000000" when "11010",
              "00001000000000000000000000000000" when "11011",
              "00010000000000000000000000000000" when "11100",
              "00100000000000000000000000000000" when "11101",
              "01000000000000000000000000000000" when "11110",
              "10000000000000000000000000000000" when "11111",
              "00000000000000000000000000000000" when others;
end mixed;
