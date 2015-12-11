-- cpu_pl.vhd: Pipelined implementation of MIPS32 for CprE 381
-- Iowa State University
--
-- Zhao Zhang, fall 2015
--
-- This file includes the architecture of the CPU for pipelined implementation,
-- and entities and architectures for all pipeline stages.
--

library IEEE;
use IEEE.std_logic_1164.all;
use work.mips32.all;
use work.pl_reg.all;

architecture pipeline of cpu is
    ---------------------------------------------
    -- Pipeline registers
    ---------------------------------------------
	component PC_reg is				-- PC can be thought as the 1st pipeline register
		port (NPC   : in  m32_word;  		-- Next PC as input
		      PC    : out m32_word;  		-- Current PC as output
		      we    : in  m32_1bit;   		-- Write enable
		      clock : in  m32_1bit);  		-- Clock signal
	end component;

	component IFID_reg is				-- IFID pipeline regster
		port (i  	: in  m32_IFID;			-- Input from the IF stage
		      o  	: out m32_IFID;			-- Output to the ID stage
		      we 	: in  m32_1bit;			-- Write enable signal
		      flush : in  m32_1bit;			-- Flush signal
		      clock : in  m32_1bit);		-- Clock signal
	end component;

	component IDEX_reg is				-- IDEX pipeline regster
		port (i  	: in  m32_IDEX;			-- Input from the ID stage
		      o  	: out m32_IDEX;			-- Output to the EX stage
		      we 	: in  m32_1bit;			-- Write enable signal
		      flush : in  m32_1bit;			-- Flush signal
		      clock : in  m32_1bit);		-- Clock signal
	end component;

	component EXMEM_reg is			-- EXMEM pipeline regster
		port (i  	: in  m32_EXMEM;		-- Input from the EX stage
		      o  	: out m32_EXMEM;		-- Output to the MEM stage
		      we 	: in  m32_1bit;			-- Write enable signal
		      flush : in  m32_1bit;			-- Flush signal
		      clock : in  m32_1bit);		-- Clock signal
	end component;

	component MEMWB_reg is			-- MEMWB pipeline regster
		port (i  	: in  m32_MEMWB;		-- Input from the MEM stage
		      o  	: out m32_MEMWB;	
		      we 	: in  m32_1bit;			-- Write enable signal
		      flush : in  m32_1bit;			-- Flush signal	-- Output to the WB stage
		      clock : in  m32_1bit);		-- Clock signal
	end component;

    ---------------------------------------
    -- Major datapath elements
    ---------------------------------------

    -- The main control unit
	component control is
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
	end component;

    -- The ALU control unit, extending aluop to 3-bit and adding jr and use_shamt signals
	component alu_ctrl is
		port (aluop     : in  m32_3bits;    -- ALUOp from the main control
		      funct     : in  m32_6bits;    -- The funct field
		      alu_code  : out m32_4bits;    -- ALU operation code
		      jr        : out m32_1bit;     -- Is it JR inst?
		      use_shamt : out m32_1bit);    -- Is it a Shift instruction that use shamt?
	end component;

    -- The register file
	component regfile is
		port (src1      : in  m32_5bits;
		      src2      : in  m32_5bits;
		      dst       : in  m32_5bits;
		      wdata     : in  m32_word;
		      rdata1    : out m32_word;
		      rdata2    : out m32_word;
		      WE        : in  m32_1bit;
		      clock     : in  m32_1bit);
	end component;

    -- The ALU.
	component ALU is
		port (data1    : in  m32_word;
		      data2    : in  m32_word;
		      alu_code : in  m32_4bits;
		      shamt    : in m32_5bits;
		      result   : out m32_word;
		      zero     : out m32_1bit);
	end component;

    -- The two adders for calculating PC+4 and branch target
	component adder is
		port (src1    : in  m32_word;
		      src2    : in  m32_word;
		      result  : out m32_word);
	end component;

    -----------------------------------------
    -- Small datapath elements
    -----------------------------------------

    -- 2-to-1 MUX
	component mux2to1 is
		generic (M    : integer := 1);    -- Number of bits in the inputs and output
		port (input0  : in  m32_vector(M-1 downto 0) := (others => '0');
		      input1  : in  m32_vector(M-1 downto 0) := (others => '0');
		      sel     : in  m32_1bit;
		      output  : out m32_vector(M-1 downto 0));
	end component;

    -- 4-to-1 MUX
	component mux4to1 is
		generic (M    : integer := 1);    -- Number of bits in the inputs and output
		port (input0  : in  m32_vector(M-1 downto 0) := (others => '0');
		      input1  : in  m32_vector(M-1 downto 0) := (others => '0');
		      input2  : in  m32_vector(M-1 downto 0) := (others => '0');
		      input3  : in  m32_vector(M-1 downto 0) := (others => '0');
		      sel     : in  m32_2bits;
		      output  : out m32_vector(M-1 downto 0));
	end component;

    -- A special MUX for next PC selection
	component pc_mux is
		port (PC_plus_4 : in  m32_word;	-- PC plus 4
		      br_target : in  m32_word;	-- Branch target
		      j_target  : in  m32_word;	-- Jump target
		      jr_target : in  m32_word;	-- jr target
		      branch    : in  m32_2bits;	-- Is it a branch?
		      jump      : in  m32_1bit;	-- Is it a jump?
		      jr        : in  m32_1bit;	-- Is it a jr?
		      alu_zero  : in  m32_1bit;	-- ALU result is zero?
		      NPC       : out m32_word);	-- Next PC
	end component;

    -- 1-bit inverter, for inverting clock signal
	component inv is
		port (i_A  : in  m32_1bit;
		      o_F : out m32_1bit);
	end component;

	component and2 is
		port(src1          : in std_logic;
		     src2          : in std_logic;
		     result          : out std_logic);
	end component;

	component or2 is
		port(src1          : in m32_1bit;
		     src2          : in m32_1bit;
		     result          : out m32_1bit);
	end component;
    ------------------------------------------------------------  
    -- Hazard detection, forwarding, and branch resolve units.
    -- Those are cross-stage hardware modules.
    ------------------------------------------------------------  

    -- Load use hazard detection unit 
	component LUD is
		port (EX_memread  : in  m32_1bit;    -- memread signal from EX
		      EX_dst      : in  m32_5bits;   -- Destination register from EX
		      ID_rs       : in  m32_5bits;   -- rs register of ID
		      ID_rt       : in  m32_5bits;   -- rt register
		      LUD_stall   : out m32_1bit);   -- Load-use is detected
	end component;

    -- Data forwarding unit from MEM and WB to EX
	component FWD is
		port (EX_rs        : in  m32_5bits; -- rs from EX
		      EX_rt        : in  m32_5bits; -- rt from EX
		      MEM_regwrite : in  m32_1bit;  -- regwrite from MEM
		      MEM_dst      : in  m32_5bits; -- Destination register from MEM
		      WB_regwrite  : in  m32_1bit;  -- regwrite from MEM
		      WB_dst       : in  m32_5bits; -- Destination register from MEM
		      EX_fwd1      : out m32_2bits; -- FWD selection for ALU input 1
		      EX_fwd2      : out m32_2bits); -- FWD selection for ALU input 1
	end component;

    -- The branch/jump unit: Detect taken branch and jump, produce
    -- br_taken and PC_target signals.
	component BRU is
		port (br_target : in  m32_word;     -- Branch target
		      j_target  : in  m32_word;     -- Jump target
		      jr_target : in  m32_word;     -- jr target
		      branch    : in  m32_2bits;    -- Is it a branch?
		      jump      : in  m32_1bit;	-- Is it a jump?
		      jr	    : in  m32_1bit;	-- Is it a jr?
		      alu_zero  : in  m32_1bit;	-- ALU result is zero?
		      br_taken  : out m32_1bit;     -- Taken branch/jump?
		      PC_target : out m32_word); 	-- The PC target
	end component;

    ---------------------------------------------------------------------
    -- Signals in the CPU, prefixed by the name of the pipeline stage
    --   or a cross-stage unit at which the signal is produced.
    ---------------------------------------------------------------------

    -- Inverted clock signal, for register write
	signal clock_inv	: m32_1bit;

    ---------- IF stage signals -------------
	signal IFID_i         : m32_IFID := INIT_IFID_VAL;     -- Input of the IFID register

	signal IF_PC          : m32_word := x"00000000";	-- PC for the current inst
	signal IF_NPC         : m32_word := x"00080000";	-- PC for the next inst, started with 0x00080000

    ---------- ID stage signals -------------
	signal IFID_o         : m32_IFID;     -- Output of the IFID register
	signal IDEX_i         : m32_IDEX := INIT_IDEX_VAL;     -- Input to the IDEX register
	signal IDEX_flush	  : m32_2bits;	-- Flush IDEX or not

    --------- EX stage signals -------------
	signal IDEX_o   : m32_IDEX;     -- Output of the IDEX register
	signal EXMEM_i  : m32_EXMEM                                    := INIT_EXMEM_VAL;    -- Input of the EXMEM register
	signal EX_fwd1  : m32_2bits := "00"; -- FWD selection for ALU input 1
	signal EX_fwd2  : m32_2bits := "00"; -- FWD selection for ALU input 2
	signal flush_sel: m32_2bits := "00";
	signal reg_sel  : m32_2bits := "00";
	signal use_shamt: m32_1bit := '0';
	signal alucode   : m32_4bits := "0000";
	signal there_is_branch : m32_1bit := '0';

    -- 32-bit data values
	signal EX_fwd_rdata1 : m32_word := x"00000000";	-- The 1st register read data after forwarding
	signal EX_fwd_rdata2 : m32_word := x"00000000";	-- The 2nd register read data after forwarding
	signal ext_shamt     : m32_word := x"00000000";	-- The extended shift amount
	signal ext_imme      : m32_word := x"00000000";	-- The extended immediate
	signal alu_input1    : m32_word := x"00000000"; -- alu input 1
	signal alu_input2    : m32_word := x"00000000"; -- alu input 2
	signal lui_result    : m32_word := x"00000000";
	signal PC_addr       : m32_word := x"00000000";
	signal NPC_addr      : m32_word := x"00000000";
	signal fwd_mux1      : m32_word := x"00000000";
	signal fwd_mux2      : m32_word := x"00000000";
    -- CODE DELETED

    -- Derived control signals
	signal br_offset      : m32_word := x"00000000";
	signal temp_alu_result: m32_word := x"00000000";
	signal j_target       : m32_word := x"00000000";
    -- CODE DELETED

    -- PC related signals
	signal EX_br_taken	: m32_1bit := '0'; -- Taken branch/jump detected?
	signal EX_PC_target   : m32_word := x"00000000";     -- The PC target
							     -- CODE DELETED

    ---------- MEM stage signals ----------
	signal EXMEM_o        : m32_EXMEM;    -- Output of the EXMEM register
	signal MEMWB_i        : m32_MEMWB := INIT_MEMWB_VAL;    -- Input of the MEMWB register

    ---------- WB stage signals -----------
	signal MEMWB_o        : m32_MEMWB := INIT_MEMWB_VAL;    -- Input of the MEMWB register
	signal WB_wdata       : m32_word := x"00000000";     -- Register write data
	signal write_data_sel : m32_2bits := "00";

    ---------- LUD and FWD signals ----------------
	signal LUD_stall   : m32_1bit := '0'; -- LUD stall signal
	signal LUD_nostall : m32_1bit := '1'; -- LUD stall and non-stall signals
	signal FWD_sel1, FWD_sel2 : m32_2bits := "00"; -- FWD select signal

begin

    -- The inverted clock is needed because register write now happens on the falling
    -- clock edge.
	INV_CLOCK : inv
	port map (
			 i_A  => clock,
			 o_F => clock_inv);

    -------------------------------------------------------
    -- The IF stage
    -- Instruction Fetch.
    -- For PC: Calculate PC+4 
    -------------------------------------------------------

	PC1 : PC_reg
	port map (
			 NPC   => IF_NPC, 
			 PC    => IF_PC,
			 WE    => LUD_nostall,
			 clock => clock);

    -- Send PC to instruction memory's address port
    -- Receive the returned instruction
	IFID_i.inst <= inst;

    -- The 1st PC adder, for PC plus 4
	PC_ADDER1 : adder
	port map (
			 src1   => IF_PC, 
			 src2   => x"00000004", 	-- Second input fixed to 4
			 result => IFID_i.PC_plus_4);
	
    -- NPC Mux: Select PC_plus_4 or ID_PC_target
    -- Note: All branch and jumps are resolved at the EX stage
    --   in this implementation.
	NPC_MUX : mux2to1
	generic map (M => 32)
	port map (
			 input0  => IFID_i.PC_plus_4,
			 input1  => EX_PC_target, 
			 sel     => EX_br_taken,
			 output  => IF_NPC);

	imem_addr <= IF_PC;

    -------------------------------------------------------------------------------
    -- The ID STAGE 
    -- Decode opcode and funct
    -- For PC: Calculate PC+4
    -- Note: Register write is also located here, but it happens in STAGE 5.
    -------------------------------------------------------------------------------

    -- IFID pipeline register
	IFID_REG1 : IFID_reg
	port map (i		=> IFID_i,
		  o		=> IFID_o,
		  we	=> LUD_nostall,         -- Write only if no load-use
		  flush => EX_br_taken,         -- Flush on taken branch/jump
		  clock	=> clock);

    -- Control Unit, decode the op-code
	CONTROL1: control
	port map (
			 opcode   => IFID_o.inst(31 downto 26),    -- opcode
			 alusrc   => IDEX_i.alusrc, 
			 aluop    => IDEX_i.aluop,
			 memread  => IDEX_i.memread,
			 memwrite => IDEX_i.memwrite,
			 regwrite => IDEX_i.regwrite,
			 regdst   => IDEX_i.regdst,
			 memtoreg => IDEX_i.memtoreg,
			 link     => IDEX_i.link,
			 branch   => IDEX_i.branch,
			 jump     => IDEX_i.jump);

    -- The register file with inverted clock. Note it's used in both ID and WB stages.
	REGFILE1 : regfile
	port map (
			 src1     => IFID_o.inst(25 downto 21),   -- rs
			 src2     => IFID_o.inst(20 downto 16),   -- rt
			 dst      => MEMWB_o.dst,
			 wdata    => WB_wdata,
			 rdata1   => IDEX_i.rdata1,
			 rdata2   => IDEX_i.rdata2,
			 WE       => MEMWB_o.regwrite,
			 clock    => clock);


    -- Pass pipeline signals 
	IDEX_i.inst        <= IFID_o.inst(25 downto 0);
	IDEX_i.ext_imme    <= (31 downto 16 => IFID_o.inst(15)) & IFID_o.inst(15 downto 0);
	IDEX_i.rs <= IFID_o.inst(25 downto 21);
	IDEX_i.rt <= IFID_o.inst(20 downto 16);
	IDEX_i.rd <= IFID_o.inst(15 downto 11);
	IDEX_i.shamt <= IFID_o.inst(10 downto 6);

	IDEX_i.PC_plus_4   <= IFID_o.PC_plus_4;

    ---------------------------------------------------------
    -- The EX STAGE
    -- ALU execute
    -- For PC: 1) Form the jump target; 2) calculate branch target, 
    --   3) resolve branch/jump.
    ---------------------------------------------------------

	flush_sel <= LUD_stall & EX_br_taken;

    -- IDEX pipeline register
	IDEX_REG1 : IDEX_reg
	port map (i		=> IDEX_i,        -- IF stage output
		  o		=> IDEX_o,        -- EX stage input
		  we    => LUD_nostall,   -- Write only if no load-use stall
		  flush => IDEX_flush(0),    -- flush on taken branch/jump
		  clock	=> clock);

    -- Flush the instruction coming to EX if any of the followings is
    -- detected: 1) load use, 2) taken branch

	EXMEM_flush_mux : mux4to1
	generic map (M => 2)
	port map(
			input0 => "00",
			input1 => "01",
			input2 => "01",
			input3 => "01",
			sel    => flush_sel,
			output => IDEX_flush);

    -- FWD mux for the 1st register data
	REG1_MUX : mux4to1
	generic map (M => 32)
	port map(
			input0 => IDEX_o.rdata1,
			input1 => WB_wdata,
			input2 => EXMEM_o.alu_result,
			input3 => x"00000000",
			sel    => EX_fwd1, --??? Check if actuall connected to something
			output => fwd_mux1);

    -- FWD mux for the 2nd register data
	REG2_MUX : mux4to1
	generic map (M => 32)
	port map(
			input0 => IDEX_o.rdata2,
			input1 => WB_wdata,
			input2 => EXMEM_o.alu_result,
			input3 => x"00000000",
			sel    => EX_fwd2, --??? Check if actuall connected to something
			output => fwd_mux2);

    -- Derived 32-bit data values from the instruction
	ext_shamt	<= (31 downto 5 => IDEX_o.inst(10)) & IDEX_o.inst(10 downto 6);
	lui_result  <= IDEX_o.inst(15 downto 0) & x"0000";

    -- ALU_SRC mux for the 1st data operand
	ALU_SRC1 : mux2to1
	generic map(M    => 32)
	port map(
			input0  => fwd_mux1,
			input1  => ext_shamt,
			sel     => use_shamt,
			output  => alu_input1);

    -- ALU_SRC mux for the 2nd data operand
	ALU_SRC2 : mux4to1 
	generic map(M   => 32)
	port map(
			input0 => fwd_mux2,
			input1 => IDEX_o.ext_imme,
			input2 => lui_result,
			input3 => x"00000000",
			sel    => IDEX_o.alusrc,
			output => alu_input2);

    -- ALU Control unit, decode the funct code
	ALU_CTRL1: alu_ctrl
	port map (
			 aluop	    => IDEX_o.aluop, 
			 funct	    => IDEX_o.inst(5 downto 0), 
			 alu_code  => alucode,
			 jr 	    => IDEX_o.jr,
			 use_shamt => use_shamt);

    -- The ALU
	ALU1 : alu
	port map (
			 data1    => alu_input1,
			 data2    => alu_input2,
			 alu_code => alucode,
			 shamt    => IDEX_o.shamt,
			 result   => temp_alu_result,
			 zero     => EXMEM_i.alu_zero );

	reg_sel   <= IDEX_o.link & IDEX_o.regdst;

    -- The merged dst and link mux
	REG_DST_MUX : mux4to1
	generic map (M => 5)
	port map(
			input0  =>IDEX_o.rt,
			input1  =>IDEX_o.rd,
			input2  =>"11111",
			input3  =>"00000",
			sel     =>reg_sel,
			output  =>EXMEM_i.dst);

    -- The link mux, replace alu_result with PC_plus_4 for JAL
	LINK_MUX : mux2to1
	generic map (M => 32)
	port map(
			input0  => temp_alu_result,
			input1  => IDEX_o.PC_plus_4,
			sel     => IDEX_o.link,
			output  => EXMEM_i.alu_result);

    -- Form 32-bit branch offset
	br_offset <= IDEX_o.ext_imme(29 downto 0) & "00";

    -- The branch target adder
	PC_ADDER2 : adder
	port map (
			 src1    => IDEX_o.PC_plus_4,
			 src2    => br_offset,
			 result  => EXMEM_i.branch_addr);


    -- Form the jump target
	j_target <= IDEX_o.PC_plus_4(31 downto 28) & (IDEX_o.inst(25 downto 0)) & "00";

    -- The Branch Resolve Unit: Detect taken branch and jump, produce
    -- br_taken, br_target and signals.  Note: Jump is treated as a taken branch.
	BRU1 : BRU
	port map (br_target => EXMEM_i.branch_addr,               -- Branch target 
		  j_target  => j_target,	    -- Jump target
		  jr_target => IDEX_o.rdata1,	        -- jr target
		  branch    => IDEX_o.branch,           -- Is it a branch?
		  jump      => IDEX_o.jump,	            -- Is it a jump?
		  jr        => IDEX_o.jr,               -- Is it a jr?
		  alu_zero  => EXMEM_i.alu_zero,         -- ALU result is zero?
		  br_taken  => EX_br_taken,                -- Taken branch/jump detected?
		  PC_target => EX_PC_target); 	            -- The PC target

    -- Pass pipeline signals 
	EXMEM_i.regwrite   <= IDEX_o.regwrite;
	EXMEM_i.memtoreg <= IDEX_o.memtoreg;
	EXMEM_i.memread    <= IDEX_o.memread;
	EXMEM_i.memwrite   <= IDEX_o.memwrite;
	EXMEM_i.rdata2     <= fwd_mux2;
	EXMEM_i.link       <= IDEX_o.link;
	EXMEM_i.PC_plus_4 <= IDEX_o.PC_plus_4;

    ------------------------------------------------------------------------
    -- The MEM STAGE 
    -- Data memory access
    -- For PC: Decide the next PC, is it PC_plus_4, br_target, or j_target?
    ------------------------------------------------------------------------       

    -- IDEX pipeline register
	EXMEM_REG1 : EXMEM_reg
	port map (i		    => EXMEM_i,	-- EX stage output
		  o		    => EXMEM_o,	-- MEM stage input
		  we	    => '1',	 	-- No stall in this implementation
		  flush     => '0',		-- No flush in this implementation
		  clock	    => clock);

    -- Connect signals to the data memory
	dmem_addr  <= EXMEM_o.alu_result;
	dmem_wdata <= EXMEM_o.rdata2;
	dmem_write <= EXMEM_o.memwrite;
	dmem_wmask <= "1111";

    -- Pass pipeline signals 
	MEMWB_i.regwrite   <= EXMEM_o.regwrite;
	MEMWB_i.memtoreg   <= EXMEM_o.memtoreg;

	MEMWB_i.alu_result <= EXMEM_o.alu_result;
	MEMWB_i.dst        <= EXMEM_o.dst;
	MEMWB_i.memdata    <= dmem_rdata;
	MEMWB_i.link       <= EXMEM_o.link;
	MEMWB_i.PC_plus_4 <= EXMEM_o.PC_plus_4;

    ------------------------------------------------------------
    -- The WB stage
    ------------------------------------------------------------

    -- MEMWB pipeline register
	MEMWB_REG1 : MEMWB_reg
	port map (i		    => MEMWB_i,       -- MEM stage output
		  o		    => MEMWB_o,       -- WB stage input
		  we	    => '1',	 	  -- No stall in this implementation
		  flush     => '0',		  -- No flush in this implementation
		  clock	    => clock);

	write_data_sel <= MEMWB_o.link & MEMWB_o.memtoreg;

    -- The merged memtoreg and link mux
	REGWDATA_MUX : mux4to1
	generic map( M => 32)
	port map(
			input0  => MEMWB_o.alu_result,
			input1  => MEMWB_o.memdata,
			input2  => MEMWB_o.PC_plus_4, --TODO: Add passed branch_target
			input3  => x"00000000",
			sel     => write_data_sel,
			output  => WB_wdata);

    -- Copy register write info for debuging
	reg_wdata <= WB_wdata;
	reg_write <= MEMWB_i.regwrite;
	reg_dst  <= EXMEM_o.dst;

    ------------------------------------------------------------------
    -- Cross-stage components that use inputs from multiple stages 
    --   1) Load-use hazard detection unit
    --   2) Data forwarding unit
    ------------------------------------------------------------------

    -- Load use hazard detection unit 
	LUD1 : LUD
	port map (EX_memread => IDEX_o.memread,
		  EX_dst     => IDEX_o.dst,
		  ID_rs      => IFID_o.rs,
		  ID_rt      => IFID_o.rt,
		  LUD_stall  => LUD_stall);

    -- Generated an inverted LUD_stall
    -- CODE DELETED

    -- Data forwarding unit
	FWD1 : FWD
	port map (EX_rs        => IDEX_o.rs,
		  EX_rt        => IDEX_o.rt,
		  MEM_regwrite => EXMEM_o.regwrite,
		  MEM_dst      => EXMEM_o.dst,
		  WB_regwrite  => MEMWB_o.regwrite,
		  WB_dst       => MEMWB_o.dst,
		  EX_fwd1      => EX_fwd1,
		  EX_fwd2      => EX_fwd2);

    ---------------------------------------------------------------------
    -- Set up trace signal. This is the ONLY section that behavioral 
    -- modeling may be used.
    -- *** YOU NEED TO revise this code section because your program may 
    -- *** use different signal names. Make sure the trace of an
    -- instruction represents correctly the instruction's PC, its memory
    -- write, and its register write.  Otherwise, the testbench may not
    -- work correctly.
    ---------------------------------------------------------------------

    -- Update trace upen 1) instruction fetch, 1) memory write, and 2) register write
    -- Note: If PC update is wrong, it will be detected when the mis-fetched
    -- instruction arrives at the WB stage. 
	TRACE_GENERATE : process
	-- The pipeline clock is 20 ns
		constant CCT_PL : time := 20 ns; -- Changed to 40 For testing

	-- Trace signals for the MEM and WB stages
		variable MEM_trace : m32_trace := INIT_TRACE_VAL;
		variable WB_trace  : m32_trace := INIT_TRACE_VAL;

	begin
	-- Mark the initial output as flushed. This is needed.
		trace.flushed <= true;

		TRACE_LOOP : loop
	    -- Wait until a rising clock edge arrives
			wait until rising_edge(clock);

	    -- Send instruction text to trace output at the beginning of the clock 
	    -- to help improve the bebugging view

	    -- Wait right before the next rising clock edge
	    -- Note that the testbench will check the trace at 19.9 ns 
			wait for 19.6 ns; 

	    -- IF stage: Update PC on instruction fetch for any instruction, reset
	    -- the other fields
			IFID_i.trace.PC 	     <= IF_PC;
			IFID_i.trace.flushed   <= false;
			IFID_i.trace.inst_text <= mips2text(IFID_i.inst);
			IFID_i.trace.o 	     <= (reg_write  => '0', 
						reg_dst    => "00000", 
						reg_wdata  => x"00000000",
						dmem_write => '0',
						dmem_addr  => x"00000000",
						dmem_wdata => x"00000000",
						dmem_wmask => "1111");

	    -- ID stage: Copy trace from IFID to IDEX
			IDEX_i.trace <= IFID_o.trace;

	    -- EX stage: Copy trace from IDEX to EXMEM
			EXMEM_i.trace  <= IDEX_o.trace;

	    -- MEM stage: Copy trace signal out of EXMEM, update for memory write, 
	    -- then write it to MEMWB
			MEM_trace := EXMEM_o.trace;
			if EXMEM_o.memwrite = '1' then
				MEM_trace.o.dmem_write := '1';
				MEM_trace.o.dmem_addr  := EXMEM_o.alu_result;
				MEM_trace.o.dmem_wdata := EXMEM_o.rdata2;
				MEM_trace.o.dmem_wmask := "1111";
			end if;
			MEMWB_i.trace <= MEM_trace;

	    -- MEM stage: Copy trace signal out of MEMWB, update for register
	    -- write, and then send it to in the CPU interface
			WB_trace := MEMWB_o.trace;
			if MEMWB_o.regwrite = '1' then
				WB_trace.o.reg_write := '1';
				WB_trace.o.reg_dst   := MEMWB_o.dst;
				WB_trace.o.reg_wdata := WB_wdata;
			end if;
			trace <= WB_trace;
		end loop;
	end process;
end pipeline;

