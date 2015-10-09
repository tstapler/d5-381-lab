-- cpu_behavior.vhd: Behavioral modeling of MIPS ISA.
--
-- Zhao Zhang, Fall 2015
-- CprE 381 Course Project
--
-- This is Part 1 of Mini-Project A.  It will be used to verify more 
-- detailed modeling of MIPS processor.
-- 

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.mips32.all;

--
-- Behavioral modeling of the CPU. 
--
architecture behavioral of cpu is
  -- Use VHDL unsigned/signed data type for most data values, so that we can use VHDL data operators.
  -- They are based on VHDL std_logic but with pre-defined data operators.
  -- Note that All interface signals are m32_* type which are std_logic or std_logic_vector.
  -- Note that the used of "unsigned" is NOT allowed in the structural modeling.
  subtype u32_t is unsigned (31 downto 0);
  subtype u6_t  is unsigned (5 downto 0);
  subtype u5_t  is unsigned (4 downto 0);
  subtype u16_t is unsigned (15 downto 0);
  subtype s16_t is signed (15 downto 0);

  -- PC and GPRs
  signal PC      : u32_t := x"00080000";     			-- Program Counter
  signal regfile : m32_regval_array := (others => x"00000000");	-- Register file
 
begin
  -- The main process for CPU execution
  CPU_EXE_CYCLE : process
    -- PC-related variables in unsigned format
    variable NPC        : u32_t;  	-- Next PC
    variable PC_plus_4  : u32_t;  	-- Current PC's value plus 4

    -- Instruction fields and derives
    variable opcode     : u6_t;    	-- 6-bit opcode
    variable rs, rt, rd : u5_t;    	-- 5-bit RS, RT and RD fields
    variable shamt      : u5_t;    	-- 5-bit shift amount
    variable funct      : u6_t;    	-- 6-bit function code
    variable imme       : s16_t; 	-- Sign-extended immediate

    -- Source register values
    variable rdata1, rdata2  	: u32_t;

    -- Branch and jump targets
    variable br_target  : u32_t;	-- Branch target
    variable j_target   : u32_t; 	-- Jump target

    -- ALU result and zero signal
    variable ALU_result : u32_t;
    variable ALU_zero   : boolean;

    --
    -- Procedures/function for simplifying the modeling 
    --

    -- Procedure for clearing register write. It's for debugging in this modeling.
    procedure clear_reg_write is
    begin
       -- The following is for debugging
       reg_write <= '0';
       reg_dst   <= "00000";
       reg_wdata <= x"00000000";
    end clear_reg_write;

    -- Procedure for reading a register; it makes sure $0 returns zero
    function read_reg (regfile : m32_regval_array; r : u5_t) return u32_t is
    begin
      if r /= "00000" then
        return unsigned(regfile(to_integer(r)));
      else
	return x"00000000";
      end if;
    end read_reg;

    -- Procedure for writing back a register; it makes sure no write happens to $0
    procedure writeback (r : u5_t; datum : u32_t) is
    begin
      if r /= "00000" then
	-- Write the register
        regfile(to_integer(r)) <= std_logic_vector(datum);
        wait for 0.1*CCT;

        -- The following is for debugging
	reg_write <= '1';	
	reg_dst   <= std_logic_vector(r);
	reg_wdata <= std_logic_vector(datum);
      end if;
    end writeback;

    -- Procedure for ALU execute: Set ALU_result and ALU_zero
    -- Note that the input is expected to be unsigned type, not std_logic_vector
    procedure ALU_exec_result(result : u32_t) is
    begin
      ALU_result := result;
      ALU_zero   := (ALU_result = x"00000000");
      wait for 0.2*CCT;
    end ALU_exec_result;

    -- Procedure for making memory idle
    procedure make_dmem_idle is
    begin
      dmem_read  <= '0';
      dmem_write <= '0';
    end make_dmem_idle;

    -- Procedure for reading data memory. Data memory must be idle.
    procedure read_dmem (addr : u32_t) is
    begin
      dmem_addr  <= std_logic_vector(addr);
      dmem_read  <= '1';
      wait for 0.2*CCT;
    end read_dmem;

    -- Procedure for writing data memory. Data memory must be idle.
    procedure write_dmem (addr : u32_t; datum : u32_t; wmask : m32_4bits) is
    begin
      dmem_addr  <= std_logic_vector(addr);
      dmem_write <= '1';
      dmem_wmask <= wmask;
      dmem_wdata <= std_logic_vector(datum);
      wait for 0.2*CCT;
    end write_dmem;

  begin 
    report " ------------- CPU0 EXECUTION starts --------------------";

    loop
      -- CPU execution starts with rising clock edge
      wait on clock;
      if rising_edge(clock) then
        -- Clean up: Reset data memory read/write signals and register write signal
        clear_reg_write;
        make_dmem_idle;

        -- Stage 1: Instruction fetch
        imem_addr <= std_logic_vector(PC);
        wait for 0.2*CCT;
        inst_text <= mips2text(inst);

        -- STAGE 2: Instruction decode and register read
        opcode   := unsigned(inst(31 downto 26));
        rs       := unsigned(inst(25 downto 21));
        rt       := unsigned(inst(20 downto 16));
        rd       := unsigned(inst(15 downto 11));
        shamt    := unsigned(inst(10 downto 6));
        funct    := unsigned(inst(5 downto 0));
	imme     := signed(inst(15 downto 0));		-- Immediate is signed type

        rdata1   := read_reg(regfile, rs);
        rdata2   := read_reg(regfile, rt);

        -- Calculate PC+4
        PC_plus_4 := PC + 4;

        -- Pre-calculate branch and jump target
        br_target := PC_plus_4 + unsigned(resize(imme*4, 32));
        j_target  := PC_plus_4(31 downto 28) & unsigned(inst(25 downto 0)) & "00";

	-- Delay for 10ns
        wait for 0.1*CCT;

        ------------------------------------------------------------------------
        -- From now, there are three sequential stages, whose operations are
        -- decided by the opcode and the funct code.
        --   STAGE 3: ALU execution; produce ALU result
        --   STAGE 4: Read or write memory (or idle memory)
        --   STAGE 5: Write back to register, update PC
	-- There is a parallel operation that calculates branch/jump targets.
        ------------------------------------------------------------------------

        ------------------------------------------------------------------------
        -- ADD YOUR CODE TO SUPPORT MORE INSTRUCTIONS (OPCODE/FUNCT)
        ------------------------------------------------------------------------

        case opcode is
          when "000000" =>		-- R-type instructions
  	  -- Data operation according to funct code
            case funct is
	      when "100000" =>   -- ADD
                ALU_exec_result(rdata1 + rdata2);
                writeback(rd, ALU_result);
		NPC := PC_plus_4;

	      when "100001" =>   -- ADDU
                ALU_exec_result(rdata1 + rdata2);
                writeback(rd, ALU_result);
		NPC := PC_plus_4;

              when others => -- Funct code not supported yet
                report "Unsupported funct code" severity failure;
            end case;
            -- End of R-type

          when "000100" =>   -- BEQ
            ALU_exec_result(rdata1 - rdata2);
            if ALU_zero then
              NPC := br_target;
            else
	      NPC := PC_plus_4;
	    end if;

          when "100011" =>   -- LW
	    ALU_exec_result(rdata1 + unsigned(resize(imme, 32)));
	    read_dmem(ALU_result);
	    writeback(rt, unsigned(dmem_rdata));
	    NPC := PC_plus_4;

          when "101011" =>   -- SW
	    ALU_exec_result (rdata1 + unsigned(resize(imme, 32)));
	    write_dmem(ALU_result, rdata2, "1111");
	    NPC := PC_plus_4;

          when others => -- Inst not supported yet
            report "Unsupported opcode" severity failure;
        end case;

	-- Update PC with NPC
        PC <= NPC;
      end if;
    end loop;
  end process;
end behavioral;

