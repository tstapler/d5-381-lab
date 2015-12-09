-- small_elements.vhd
-- For Mini-Project A, CprE 381, Fall 2015
-- Created by Zhao Zhang



library IEEE;
use IEEE.std_logic_1164.all;
use work.mips32.all;

--
-- A generic register. It may be used for pineline registers and others.
-- 
entity reg is
	generic (M  : integer := 32);			-- Size of the register
	port (D     : in  m32_vector(M-1 downto 0);  	-- Data input
	      Q     : out m32_vector(M-1 downto 0);  	-- Data output
	      WE    : in  m32_1bit;                  	-- Write enableenable
	      clock : in  m32_1bit);                 	-- The reset signal
end reg;

architecture behavior of reg is
	signal reg_buf : m32_vector(M-1 downto 0) := (others => '0');
begin
  -- Read is unclocked
	Q <= reg_buf;

  -- Write is guarded by clock
	REG : process (clock)
	begin
		if rising_edge(clock) and WE = '1' then
			reg_buf <= D;
		end if;
	end process;
end behavior;

--
-- A special PC register. It's initialzed to 0x00080000 on the first clock (rising) edge.
-- In other work, it takes the first clock edge as a reset event.
-- Note: It is NOT sufficient to given a initial value to internal signal, because
-- the signal will be overwritten on the first clock edge by external signals. We want
-- to have PC reset to 0x00080000 on the first clock edge, not when simulation starts.
-- 
library IEEE;
use IEEE.std_logic_1164.all;
use work.mips32.all;

entity PC_reg is
	port (NPC   : in  m32_word;  	-- Next PC as input
	      PC    : out m32_word;  	-- Current PC as output
	      WE    : in  m32_1bit;   -- Write enableenable
	      clock : in  m32_1bit);  -- The reset signal
end PC_reg;

architecture behavior of PC_reg is
	signal reg_buf : m32_word;
begin
  -- Read is unclocked
	PC <= reg_buf;

  -- Write is guarded by clock, and reset on the first rising clock edge
	REG : process (clock)
		variable reset_done : boolean := false;
	begin
		if rising_edge(clock) then
			if not reset_done then
				reg_buf <= x"00080000";
				reset_done := true;
			elsif WE = '1' then
				reg_buf <= NPC;
			end if;
		end if;
	end process;
end behavior;

--
-- 2-to-1 MUX
--
library IEEE;
use IEEE.std_logic_1164.all;
use work.mips32.all;

entity mux2to1 is
	generic (M : integer := 1);    -- Number of bits in the inputs and output
	port (input0  : in  m32_vector(M-1 downto 0);
	      input1  : in  m32_vector(M-1 downto 0);
	      sel     : in  m32_1bit;
	      output  : out m32_vector(M-1 downto 0));    
end entity;

architecture dataflow of mux2to1 is
begin
	with sel select 
		output <= input0 when '0',
			  input1 when '1',
			  input0 when others;
end dataflow;

--
-- 4-to-1 MUX
--
library IEEE;
use IEEE.std_logic_1164.all;
use work.mips32.all;

entity mux4to1 is
	generic (M : integer := 1);    -- Number of bits in the inputs and output
	port (input0  : in  m32_vector(M-1 downto 0);
	      input1  : in  m32_vector(M-1 downto 0);
	      input2  : in  m32_vector(M-1 downto 0);
	      input3  : in  m32_vector(M-1 downto 0);
	      sel     : in  m32_2bits;
	      output  : out m32_vector(M-1 downto 0));    
end entity;

architecture dataflow of mux4to1 is
begin
	with sel select 
		output <= input0 when "00",
			  input1 when "01",
			  input2 when "10",
			  input3 when "11",
			  input0 when others;
end dataflow;

--
-- A special MUX for next PC selection
--
library IEEE;
use IEEE.std_logic_1164.all;
use work.mips32.all;

entity pc_mux is
	port (PC_plus_4 : in  m32_word;	-- PC plus 
	      br_target : in  m32_word;	-- Branch target
	      j_target  : in  m32_word;	-- Jump target
	      jr_target : in  m32_word;	-- jr target
	      branch    : in  m32_2bits;	-- Is it a branch?
	      jump      : in  m32_1bit;	-- Is it a jump?
	      jr	  : in  m32_1bit;	-- Is it a jr?
	      ALU_zero  : in  m32_1bit;	-- ALU result is zero?
	      NPC       : out m32_word);	-- Next PC
end entity;

architecture behavior of pc_mux is
begin
	PC_MUX : process (PC_plus_4, br_target, j_target, branch, jump, ALU_zero, jr, jr_target)
	begin
		if jump = '1' then
			NPC <= j_target;
		elsif jr = '1' then
			NPC <= jr_target;
		elsif branch = "01" and ALU_zero = '1' then
			NPC <= br_target;
		elsif branch = "10" and ALU_zero = '0' then
			NPC <= br_target;
		else
			NPC <= PC_plus_4;
		end if;
	end process;
end behavior;


--
-- BRU - The unit for resolving where to go next
--
library IEEE;
use IEEE.std_logic_1164.all;
use work.mips32.all;

entity BRU is
	port (br_target : in m32_word;    -- Branch target ??? Dont know what this should be
		  j_target  : in m32_word;   -- Jump target
		  jr_target : in m32_word;   -- jr target
		  branch    : in m32_2bits;   -- Is it a branch?
		  jump      : in m32_1bit;   -- Is it a jump?
		  jr        : in m32_1bit;   -- Is it a jr?
		  alu_zero  : in m32_1bit;   -- ALU result is zero?
		  br_taken  : out m32_1bit;   -- Taken branch/jump detected?
		  PC_target : out m32_word); -- The PC target
end BRU;

architecture behavior of BRU is

begin
	branch_unit : process (j_target, jr_target, branch, jump, jr, alu_zero, br_taken, PC_target)
		begin
	if jump = '1' then
		PC_target <= j_target;
	elsif jr = '1' then
		PC_target <= jr_target;
	--elsif br_taken = '1' then ??? Not sure what to do
	elsif branch = "01" and ALU_zero = '1' then
		PC_target <= br_target;
		br_taken <= '1';
	elsif branch = "10" and ALU_zero = '0' then
		PC_target <= br_target;
		br_taken <= '1';
	end if;
	end process;
end behavior;


--
-- FWD - The data forwarding unit
--
library IEEE;
use IEEE.std_logic_1164.all;
use work.mips32.all;

entity FWD is
    port (EX_rs        : in m32_5bits;  -- rs from EX
              EX_rt        : in m32_5bits;  -- rt from EX
              MEM_regwrite : in m32_1bit;   -- regwrite from MEM
              MEM_dst      : in m32_5bits;  -- Destination register from MEM
              WB_regwrite  : in m32_1bit;   -- regwrite from MEM
              WB_dst       : in m32_5bits;   -- Destination register from MEM
              EX_fwd1      : out m32_2bits;  -- FWD selection for ALU input 1
              EX_fwd2      : out m32_2bits); -- FWD selection for ALU input 1
end FWD;

architecture behavior of FWD is 

-- RegisterRd is the Register Destination - rs or rd field
begin
	forward : process (EX_rs, EX_rt, MEM_regwrite, MEM_dst, WB_regwrite, WB_dst, EX_fwd1, EX_fwd2)
		begin
	if MEM_regwrite = '1' 
	and (not (MEM_dst = "00000")) 
	and ( MEM_dst = EX_rs) 
	and not (MEM_regwrite = '1' and (not (MEM_dst = "00000")) and (not (MEM_dst = EX_rs))) then
       	EX_fwd1 <= "01";
	end if;
	if MEM_regwrite = '1' 
	and not (MEM_dst = "00000") 
	and (MEM_dst = EX_rt) 
	and not (MEM_regwrite = '1' and (not (MEM_dst = "00000")) and (not (MEM_dst = EX_rt))) then
       	EX_fwd2 <= "01";
	end if;
	end process;
end behavior;
