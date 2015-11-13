-- mips32.vhd: Package for MIPS32 implementation in CprE 381
--
-- Zhao Zhang, Fall 2013
--

library IEEE;
use IEEE.std_logic_1164.all;

package MIPS32 is
  -- Half Cycle Time of the clock signal
  -- ** THE ONLY CHANGE is to reduce the clock cycle
  -- ** time from 100 ns to 20 ns.
  -- constant HCT : time := 50 ns;  
  constant HCT : time := 10 ns;
  
  -- Clock Cycle Time of the clock signal
  constant CCT : time := 2 * HCT;
  
  -- MIPS32 logic type
  subtype m32_logic is std_logic;
  
  -- MIPS32 logic vector type
  subtype m32_vector is std_logic_vector;
  
  -- Word type, for register values, memory word contents, and 
  -- memory address
  subtype m32_word is m32_vector(31 downto 0);  
  
  -- Halfword, byte, and bit fields of varying size
  subtype m32_halfword is m32_vector(15 downto 0);
  subtype m32_byte is m32_vector(7 downto 0);
  subtype m32_1bit is m32_logic;
  subtype m32_2bits is m32_vector(1 downto 0);
  subtype m32_3bits is m32_vector(2 downto 0);
  subtype m32_4bits is m32_vector(3 downto 0);
  subtype m32_5bits is m32_vector(4 downto 0);
  subtype m32_6bits is m32_vector(5 downto 0);
  subtype m32_26bits is m32_vector(25 downto 0);
   
  -- Register value array type
  type m32_regval_array is array (31 downto 1) of m32_word;
  
  -- Conversion functions for debugging
  function dec(vec : m32_vector) return string;
  function hex(vec : m32_vector) return string;
  function mips2text(bin : m32_word) return string;

  -- The CPU interface and interfance signals, excluding reset and clock
  -- This record should be consistent with the entity declaration of cpu
  type cpu_interface is record
    imem_addr  : m32_word;     -- Instruction memory address
    inst       : m32_word;     -- Instruction
    dmem_addr  : m32_word;     -- Data memory address
    dmem_read  : m32_1bit;     -- Data memory read?
    dmem_write : m32_1bit;     -- Data memory write?
    dmem_wmask : m32_4bits;    -- Data memory write mask
    dmem_rdata : m32_word;     -- Data memory read data
    dmem_wdata : m32_word;     -- Data memory write data
    reg_write  : m32_1bit;     -- FOR DEBUG: Register write or not
    reg_dst    : m32_5bits;    -- FOR DEBUG: The no. of the register to write
    reg_wdata  : m32_word;     -- FOR DEBUG: The register data to write
    inst_text  : string(1 to 21); -- FOR DEBUG: The text format of the instruction
  end record;

end MIPS32;

package body MIPS32 is
  -- Convert m32_vector to dec
  function dec(vec : m32_vector) return string is
    use std.textio.all;
    use IEEE.std_logic_textio.all;
    variable buf : line;
  begin
    write (buf, vec);
    return buf.all;
  end dec;
  
  -- Convert m32_vector to dec
  function hex(vec : m32_vector) return string is
    use std.textio.all;
    use IEEE.std_logic_textio.all;
    variable buf : line;
  begin
    hwrite (buf, vec);
    return buf.all;
  end hex;

  -- Translate an instruction from binary into text format
  function mips2text(bin : m32_word) return string is
    use std.textio.all;
    use IEEE.std_logic_textio.all;
    use IEEE.numeric_std.all;

    type opcode_table is array (0 to 63) of string (1 to 7);
    variable opcode_name : opcode_table := (
      0  => "R-type ", 2  => "j      ", 3  => "jal    ", 4  => "beq    ", 5  => "bne    ", 6  => "blez   ", 7  => "bgtz   ",
      8  => "addi   ", 9  => "addiu  ", 10 => "slti   ", 11 => "sltiu  ", 12 => "andi   ", 13 => "ori    ", 14 => "xori   ", 15 => "lui    ",
      32 => "lb     ", 33 => "lh     ", 34 => "lwl    ", 35 => "lw     ", 36 => "lbu    ", 37 => "lhu    ", 38 => "lwr    ",
      40 => "sb     ", 31 => "sh     ", 42 => "swl    ", 43 => "sw     ", 46 => "swr    ", 47 => "cache  ",
      48 => "ll     ", 49 => "lwc1   ", 50 => "lwc2   ", 51 => "pref   ", 53 => "ldc1   ", 54 => "ldc2   ", 
      56 => "sc     ", 57 => "swc1   ", 58 => "swc2   ", 61 => "sdc1   ", 62 => "sdc2   ", others => "unknown");

    type funct_table is array (0 to 63) of string (1 to 7);
    variable funct_name : funct_table := (
      0  => "sll    ", 2  => "srl    ", 3  => "sra    ", 4  => "sllv   ", 6  => "srlv   ", 7  => "srav   ", 
      8  => "jr     ", 9  => "jral   ", 10 => "movz   ", 11 => "movn   ", 12 => "syscall", 13 => "break  ", 15 => "sync   ",
      16 => "mfhi   ", 17 => "mthi   ", 18 => "mflo   ", 19 => "mtlo   ",
      24 => "mult   ", 25 => "multu  ", 26 => "div    ", 27 => "divu   ",
      32 => "add    ", 33 => "addu   ", 34 => "sub    ", 35 => "subu   ", 36 => "and    ", 37 => "or     ", 38 => "xor    ", 39 => "nor    ",
      42 => "slt    ", 43 => "sltu   ", 48 => "tge    ", 49 => "tgeu   ", 50 => "tlt    ", 51 => "tltu   ", 52 => "teq    ", 54 => "tne    ",
      others => "unknown");

    type reg_table is array (0 to 31) of string (1 to 2);
    variable reg_name : reg_table := (
      0 => "ze", 1 => "at", 2 => "v0", 3 => "v1", 4 => "a0", 5 => "a1", 6 => "a2", 7 => "a3",
      8 => "t0", 9 => "t1", 10 => "t2", 11 => "t3", 12 => "t4", 13 => "t5", 14 => "t6", 15 => "t7",
      16 => "s0", 17 => "s1", 18 => "s2", 19 => "s3", 20 => "s4", 21 => "s5", 22 => "s6", 23 => "s7", 
      24 => "t8", 25 => "t9", 26 => "k0", 27 => "k1", 28 => "gp", 29 => "sp", 30 => "fp", 31 => "ra");

    variable opcode : string(1 to 7) := opcode_name(to_integer(unsigned(bin(31 downto 26))));
    variable funct  : string(1 to 7) := funct_name(to_integer(unsigned(bin(5 downto 0))));
    variable rs     : string(1 to 2) := reg_name(to_integer(unsigned(bin(25 downto 21))));
    variable rt     : string(1 to 2) := reg_name(to_integer(unsigned(bin(20 downto 16))));
    variable rd     : string(1 to 2) := reg_name(to_integer(unsigned(bin(15 downto 11))));
    variable inst   : string(1 to 21);
  begin
    case opcode is
      when "R-type " =>
        case funct is
          when "jr     " => inst := funct & " $" & rs & "          ";
          when others    => inst := funct & " $" & rd & ", $" & rs & ", $" & rt;
        end case;
      when "jal    "     => inst := opcode & "              ";			-- TODO Add jump target
      when "j      "     => inst := opcode & "              ";			-- TODO Add jump target
      when "lw     "     => inst := opcode & " $" & rt & " ????($" & rs & ")";	-- TODO Add offset
      when "sw     "     => inst := opcode & " $" & rt & " ????($" & rs & ")";	-- TODO Add offset
      when others        => inst := opcode & " $" & rs & ", $" & rt & "???? ";	-- TODO Add branch target
    end case;
    return inst;
  end mips2text;
end MIPS32;  
