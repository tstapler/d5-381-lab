--
-- ALU Control
--

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.mips32.all;

entity alu_ctrl is
  generic (DELAY : time := 9.5 ns);
  port (aluop     : in  m32_3bits;  -- ALUOp from the main control
        funct     : in  m32_6bits;  -- The funct field
        alu_code  : out m32_4bits;  -- ALU operation code
        jr        : out m32_1bit;   -- Is it JR inst?
        use_shamt : out m32_1bit);  -- Is it a Shift instruction that use shamt?
end alu_ctrl;

architecture behavior of alu_ctrl is
  type truth_table_t is array(natural range <>) of m32_vector(14 downto 0);
  
  -- The truth table: The first two columns (aluop and funct) are the input, 
  -- the right two columns are the output (of the truth table).
  -- The truth table is extended from Figure 4.12, P&H 5th edition.
  -- Note that '-' matches either '0' or '1', i.e. it represents 
  -- "don't care" for a truth table.
  signal truth_table : truth_table_t(1 to 12) := (
    ------------------------------------------------------------
    -- ADD YOUR NEW ALUOP/FUNCT PAIRS, SEE TEXTBOOK FIG 4.12
    ------------------------------------------------------------
    -- I-type
    "000" & "------" & "0010" & "00",	-- ADD, for LW, SW, ADDI, LUI, JAL
    "001" & "------" & "0110" & "00",	-- SUB, for BEQ and BNE
    "011" & "------" & "0001" & "00",--ORI
    "100" & "------" & "0111" & "00",--SLTI

    -- R-type
    "010" & "100000" & "0010" & "00",	-- ADD
    "010" & "100001" & "0010" & "00",   -- ADDU
    "010" & "100010" & "0110" & "00",   -- SUB
    "010" & "100100" & "0000" & "00",   -- AND
    "010" & "100101" & "0001" & "00",   -- OR
    "010" & "101010" & "0111" & "00",   -- SLT
    "010" & "000000" & "0100" & "01",   --SLL
    "010" & "001000" & "0010" & "10");   --JR;
  -- Delay funct signal
  signal delayed_funct : m32_6bits;

begin 
  -- Model a delay from funct change to alu_code change.
  -- This is done by delaying the funct code signal.
  -- There is no delay in modeling from aluop to alu_code.
  delayed_funct <= funct after DELAY;

  -- search the truth table
  -- search the truth table
  P1: process (aluop, funct) begin
    for i in truth_table'range loop
      if std_match(aluop & funct, truth_table(i)(14 downto 6)) then
        alu_code  <= truth_table(i)(5 downto 2);
        jr        <= truth_table(i)(1);
        use_shamt <= truth_table(i)(0);
      end if;
    end loop;
  end process;
end behavior;
        
