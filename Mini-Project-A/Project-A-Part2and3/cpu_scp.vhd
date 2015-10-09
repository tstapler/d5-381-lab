-- This architecture of CPU must be dominantly structural, with no bahavior 
-- modeling, and only data flow statements to copy/split/merge signals or 
-- with a single level of basic logic gates.
architecture scp of cpu is
  -- The PC register
  component PC_reg is
    port (NPC   : in  m32_word;  	-- Next PC as input
          PC    : out m32_word;  	-- Current PC as output
          WE    : in  m32_1bit;   	-- Write enableenable
          clock : in  m32_1bit);  	-- The reset signal
  end component;

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
    port (aluop      : in  m32_3bits;  	-- ALUOp from the main control
          funct       : in  m32_6bits;  -- The funct field
          alu_code    : out m32_4bits;  -- ALU operation code
          jr          : out m32_1bit;   -- Is it JR inst?
          use_shamt   : out m32_1bit);  -- Is it a Shift instruction that use shamt?
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
  
  -- The ALU
  component ALU is
    port (data1    : in m32_word;
          data2    : in m32_word;
          alu_code : in m32_4bits;
          result   : out m32_word;
          zero     : out m32_1bit);
  end component;

  -- The two adders for calculating PC+4 and branch target
  component adder is
    port (src1    : in  m32_word;
          src2    : in  m32_word;
          result  : out m32_word);
  end component;
  
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
          ALU_zero  : in  m32_1bit;	-- ALU result is zero?
          NPC       : out m32_word);	-- Next PC
  end component;

  --
  -- Signals in the CPU
  --
  
  -- PC-related signals
  signal PC         : m32_word;		-- PC for the current inst
  signal NPC        : m32_word;		-- PC for the next inst, started with 0x00080000
  signal PC_plus_4  : m32_word;		-- Next PC sequentially
  signal br_target  : m32_word;		-- The target PC for branch
  signal j_target   : m32_word;		-- The jump target


  -- Instruction fields and derives
  signal opcode     : m32_6bits;	-- 6-bit opcode
  -- MORE SIGNALS
  
  -- Control signals
  signal aluop      : m32_3bits;	-- ALU Op (extended to 3-bit)
  -- MORE SIGNALS

  -- Control signals from ALU Ctrl
  signal jr	    : m32_1bit;		-- Is it JR?
  signal use_shamt  : m32_1bit;		-- Is it a shift instruction using shamt?

  -- Signals connected to the data ports of the regfile
  signal rdata1     : m32_word;		-- Register read data 1
  -- MORE SIGNALS
  
  -- Signals connected to the ALU
  signal alu_input1 : m32_word;		-- The first input of ALU
  -- MORE SIGNALS
  
  -- Other signals
  signal dst        : m32_5bits;	-- The output from the mux for Write Register
  -- MORE SIGNALS

begin
  --------------------------------------------
  -- STAGE 1 Instruction Fetch.
  -- For PC: Calculate PC+4 
  --------------------------------------------

  -- Program counter as a register
  PC1 : PC_reg
    port map (
      NPC   => NPC, 
      PC    => PC,
      WE    => '1',	-- Update every clock
      clock => clock);

  -- MORE CODE 

  -- Debugging: Convert instruction from binary to text
  inst_text <= mips2text(inst);

  --------------------------------------------------------------------------------
  -- STAGE 2 Decode and register read. Note: Register write is also located here,
  -- but it happens in STAGE 5.
  -- For PC: Form the jump target
  --------------------------------------------------------------------------------
  
  -- Split the instructions into fields
  SPLIT : block
  begin
    opcode   <= inst(31 downto 26);
    rs       <= inst(25 downto 21);
    -- MORE CODE
  end block;

  -- The derives from the instruction
  ext_imme   <= (31 downto 16 => imme(15)) & imme;	-- Sign extension of immediate
  -- MORE CODE

  -- Control Unit, decode the op-code
  -- CODE DELETED

  -- ALU Control unit, decode the funct code
  -- CODE DELETED

  -- The register file
  -- CODE DELETED

  --------------------------------------------------------------
  -- STAGE 3 ALU execute
  -- For PC: Calculate branch target and form jump target
  --------------------------------------------------------------

  -- ALU_SRC max for the 1st ALU input, selecting rdata1 or extended shamt
  -- CODE DELETED
  
  -- ALU_SRC mux for the 2nd ALU input
  -- CODE DELETED

  -- The ALU
  -- CODE DELETED

  -- The shifter connected to the branch target adder
  br_offset <= ext_imme (29 downto 0) & "00";

  -- The branch targer adder
  -- CODE DELETED

  ------------------------------------------------------------------------
  -- STAGE 4 Data memory access
  -- For PC: Decide the next PC, is it PC_plus_4, br_target, or j_target?
  ------------------------------------------------------------------------

  -- Connect alu_result and rdata2 to memory address and data inputs
  -- CODE DELETED

  -- The MUX choosing the sequentially next PC and the branch target
  -- CODE DELETED

  --------------------------------------------------------------
  -- STAGE 5 Write back to register file
  --------------------------------------------------------------

  -- CODE DELETED

  -- CODE DELETED

  -- Copy register write info for debuging
  reg_write  <= regwrite;
  reg_dst    <= dst;
  reg_wdata  <= wdata;

end SCP;

