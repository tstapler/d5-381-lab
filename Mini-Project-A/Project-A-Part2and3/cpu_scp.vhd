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
  signal rs         : m32_5bits;
  signal rt         : m32_5bits;
  signal rd         : m32_5bits;
  signal shamt      : m32_5bits;
  signal funct      : m32_6bits;
  signal imme       : m32_halfword; -- Immediate is signed type
  -- MORE SIGNALS
  
  -- Control signals
  signal regdst     : m32_1bit;
  signal jump       : m32_1bit;
  signal branch     : m32_2bits;
  signal memtoreg   : m32_1bit;
  signal aluop      : m32_3bits;	-- ALU Op (extended to 3-bit)
  signal alusrc     : m32_2bits;
  signal regwrite   : m32_1bit;
  signal link       : m32_1bit;

  -- Control signals from ALU Ctrl
  signal jr	    : m32_1bit;		-- Is it JR?
  signal use_shamt  : m32_1bit;		-- Is it a shift instruction using shamt?
  signal alu_code : m32_4bits;
  -- MORE SIGNALS

  -- Signals connected to the data ports of the regfile
  signal rdata1     : m32_word;  -- Register read data 1
  signal rdata2     : m32_word;  -- Register read data 2
  signal reg_sel    : m32_2bits;

  -- Signals connected to the ALU
  signal lui_result : m32_word;
  signal alu_input_2 : m32_word;
  signal alu_result : m32_word;
  signal alu_zero   : m32_1bit;
  signal ext_imme   : m32_word;

  -- Signals connected to Dmem
  signal wdata     : m32_word;
  signal mem_sel   : m32_2bits;

  -- Other signals
  signal dst        : m32_5bits;	-- The output from the mux for Write Register
  signal br_offset  : m32_word;

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

  -- Calculate PC + 4
  CALC_PC_PLUS_4: adder
    port map ( src1 => PC,
               src2 => x"00000004",
               result => PC_plus_4);

  imem_addr <= PC;

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
    rt       <= inst(20 downto 16);
    rd       <= inst(15 downto 11);
    shamt    <= inst(10 downto 6);
    funct    <= inst(5  downto 0);
    imme     <= inst(15 downto 0);		-- Immediate is signed type
  end block;

  -- The derives from the instruction
  ext_imme   <= (31 downto 16 => imme(15)) & imme;	-- Sign extension of immediate
  j_target   <= PC_plus_4(31 downto 28) & (inst(25 downto 0)) & "00";

  -- Control Unit, decode the op-code
    CTRL : control
    port map(
      opcode     =>  inst(31 downto 26),
      alusrc     => alusrc,
      aluop      => aluop,	-- ALU Op (extended to 3-bit)
      memwrite   => dmem_write,
      memread    => dmem_read,
      regwrite   => regwrite,
      regdst     => regdst,
      memtoreg   => memtoreg,
      link       => link,
      branch     => branch,
      jump       => jump);

  -- ALU Control unit, decode the funct code
    ALU_CONTROL : alu_ctrl
    port map(
        aluop       => aluop,  	-- ALUOp from the main control
        funct       => funct,  -- The funct field
        alu_code    => alu_code,  -- ALU operation code
        jr          => jr,   -- Is it JR inst?
        use_shamt   => use_shamt);  -- Is it a Shift instruction that use shamt?

    reg_sel <= link & regdst;

    REG_MUX : mux4to1
    generic map (M => 5)
    port map(
        input0 => rt,
        input1 => rd,
        input2 => "11111",
        input3 => "00000",
        sel    => reg_sel,
        output => dst);

  -- The register file
    REGS : regfile
    port map(
        src1   => rs,
        src2   => rt,
        dst    => dst,
        wdata  => wdata,
        rdata1 => rdata1,
        rdata2 => rdata2,
        WE     => regwrite,
        clock  => clock);

  --------------------------------------------------------------
  -- STAGE 3 ALU execute"
  -- For PC: Calculate branch target and form jump target
  --------------------------------------------------------------

    lui_result <= imme & x"0000";

    ALU_MUX : mux4to1
    generic map (M => 32)
    port map(
        input0 => rdata2,
        input1 => ext_imme,
        input2 => lui_result,
        input3 => x"00000000",
        sel    => alusrc,
        output => alu_input_2);

  -- The ALU
    ALU1 : ALU
    port map(
        data1 => rdata1,
        data2 => alu_input_2,
        alu_code => alu_code,
        shamt  => shamt,
        result => alu_result,
        zero   => alu_zero);

  -- The shifter connected to the branch target adder
  br_offset <= ext_imme(29 downto 0) & "00";

  -- The branch targer adder
   CALC_BRANCH_TARGET : adder
   port map(
        src1   => PC_plus_4,
        src2   => br_offset,
        result => br_target);

  ------------------------------------------------------------------------
  -- STAGE 4 Data memory access
  -- For PC: Decide the next PC, is it PC_plus_4, br_target, or j_target?
  ------------------------------------------------------------------------

  -- Connect alu_result and rdata2 to memory address and data inputs

    dmem_addr  <= alu_result;

    dmem_wdata <= rdata2;

    dmem_wmask <= "1111";


  -- The MUX choosing the sequentially next PC and the branch target
    PC_MUX1 : pc_mux 
    port map(
        PC_plus_4 => PC_plus_4,
        br_target => br_target,
        j_target  => j_target,
        jr_target => rdata1,
        branch    => branch,
        jump      => jump,
        jr        => jr,
        ALU_zero  => alu_zero,
        NPC       => NPC);

  --------------------------------------------------------------
  -- STAGE 5 Write back to register file
  --------------------------------------------------------------

    mem_sel <= link & memtoreg;
    MEM_MUX : mux4to1
    generic map (M => 32)
    port map(
        input0  => alu_result,
        input1  => dmem_rdata,
        input2  => PC_plus_4,
        input3  => x"00000000",
        sel     => mem_sel,
        output  => wdata);

  -- Copy register write info for debuging
  reg_write  <= regwrite;
  reg_dst    <= dst;
  reg_wdata  <= wdata;

end SCP;

