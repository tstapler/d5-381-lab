-- control.vhd: CprE 381 F13 template file
-- 
-- The main control unit of MIPS
-- 

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.mips32.all;

entity control is
  generic (DELAY : time := 9.5 ns);
  port (opcode   : in  m32_6bits;	-- The op code
        alusrc   : out m32_2bits;	-- Source choice for the 2nd input of ALU
        aluop    : out m32_3bits;	-- ALU op
        memread  : out m32_1bit;	-- Memory read signal
        memwrite : out m32_1bit;	-- Memory write signal
        regwrite : out m32_1bit;	-- Register write
        regdst   : out m32_1bit;	-- Register destination, rt or rd
        memtoreg : out m32_1bit;	-- Memory data or ALU output, which to register
        link     : out m32_1bit;	-- Write PC_plus_4 to $31?	
        branch   : out m32_2bits;	-- Branch instruction?
        jump     : out m32_1bit);	-- Jump instruction?
end control;

architecture rom of control is
  subtype code_t is m32_vector(13 downto 0);
  type rom_t is array (0 to 63) of code_t;

  -- ALU source (extended) for the second input
  --   00: $rt
  --   01: immediate
  --   10: lui result (to be added with zero)
  --   11: not used

  -- ALU OP encoding (extended). It must be consistent with alu.vhd
  --   000: Addition for LW/SW, ADDI, LUI, and JAL
  --   001: Subtraction for BEQ/BNE
  --   010: R-type (funct decides ALU operations)
  --   011: OR, for ORI
  --   100: Shift $rt for fixed 16 bits, for SLTI

  -- Register destination
  --   0: rt
  --   1: rd
  -- Note that if link = '1', then register destination is $31.

  -- Branch encoding (extended). It must be consistent with pcmux.vhd
  --   00: not a branch
  --   01: beq
  --   10: bne

  -- The ROM content
  -- Format: alusrc(2) aluop(2) & memread memwrite & regwrite regdst memtoreg link & branch(2) jump
  -- In the following code, "-" represents "doesn't care".
  signal rom : rom_t := (
    ------------------------------------------------------------
    -- ADD YOUR NEW OPCODES, SEE THE GREENSHEET OF THE TEXTBOOK 
    ------------------------------------------------------------
    0  => "00010" & "00" & "1100" & "000",	-- R-type
    4  => "00001" & "00" & "0---" & "010",	-- BEQ
    35 => "01000" & "10" & "1010" & "000",	-- LW
    43 => "01000" & "01" & "0---" & "000",	-- SW
    others => "00000000000000");		-- no-op

begin
  -- Copy the selected row of the rom to the output
  (alusrc(1), alusrc(0), aluop(2), aluop(1), aluop(0), 
     memread, memwrite, 
     regwrite, regdst, memtoreg, link,
     branch(1), branch(0), jump) 
     <= rom(to_integer(unsigned(opcode))) after DELAY;
end rom;

