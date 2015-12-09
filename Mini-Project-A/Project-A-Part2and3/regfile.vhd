-- regfile.vhd: Register file for the MIPS processor
--
-- Zhao Zhang, Fall 2013
--

--
-- MIPS regfile, clock version for SCP
--
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.mips32.all;

entity regfile is
	generic (DELAY : time := 9.5 ns; N : integer := 32);
	port(src1   : in  m32_5bits:= "00000";
	     src2   : in  m32_5bits:= "00000";
	     dst    : in  m32_5bits := "00000";
	     wdata  : in  m32_word := x"00000000";
	     rdata1 : out m32_word := x"00000000";
	     rdata2 : out m32_word := x"00000000";
	     WE     : in  m32_1bit := '0';
	     clock  : in  m32_1bit);
end regfile;

--architecture behavior of regfile is
--  signal reg_array : m32_regval_array := (others => x"00000000");
--begin
--  -- Register reset/write logic, guarded by clock rising edge
--  P_WRITE : process (clock)
--    variable r : integer;
--  begin
--    -- Write/reset logic. It is guarded by clock.
--    if (rising_edge(clock)) then
--      if (WE = '1') then
--        r := to_integer(unsigned(dst));
--        if r /= 0 then         -- Don't write to $0
--          reg_array(r) <= wdata;
--        end if;
--      end if;
--    end if;
--  end process;
--  
--  -- Register read logic. It is not clocked.
--  P_READ : process (reg_array, src1, src2)
--    variable r1, r2 : integer;
--  begin
--    -- Convert src1 and src2 to integer type
--    r1 := to_integer(unsigned(src1));
--    r2 := to_integer(unsigned(src2));
--
--    -- Read r1, return fixed zero if r1 = 0
--    if r1 /= 0 then
--      rdata1 <= reg_array(r1) after DELAY;
--    else
--      rdata1 <= x"00000000" after DELAY;
--    end if;
--
--    -- Read r2, return fixed zero if r1 = 0
--    if r2 /= 0 then
--      rdata2 <= reg_array(r2) after DELAY;
--    else
--      rdata2 <= x"00000000" after DELAY;
--    end if;
--  end process;
--end behavior;
architecture structural of regfile is
	signal write_addr, read_addr_1, read_addr_2 :m32_word;
	signal register_out : m32_regval_array := (others => x"00000000");
	signal internal_enable : m32_1bit;

	component decoder5to32
		port (i_D  : in m32_5bits;
		      o_D  : out m32_word);
	end component;


	component reg
	generic (M  : integer := 32);			-- Size of the register
	port (D     : in  m32_vector(M-1 downto 0);  	-- Data input
	      Q     : out m32_vector(M-1 downto 0);  	-- Data output
	      WE    : in  m32_1bit;                  	-- Write enableenable
	      clock : in  m32_1bit);                 	-- The reset signal
	end component;

	component n_in_lab3_multiplexer_struct
		port(i_A  : in m32_word;
		     i_B  : in m32_word;
		     i_C  : in m32_1bit;
		     o_F  : out m32_word);
	end component;

	component nbit_mux32to1
		port(data_in : in m32_regval_array;
		     sel     : in m32_word;
		     data_out: out m32_word := x"00000000");
	end component;

begin

	in_decoder : decoder5to32
	port map(i_D => dst,
		 o_D => write_addr);

	G1: for j in 1 to N-1 generate
	begin
		internal_enable <=   (write_addr(j) and WE);
		register_j : reg
		port map(clock        => clock,     -- Clock input
			 WE         => internal_enable,     -- Write enable input
			 D          => wdata,     -- Data value input
			 Q          => register_out(j));   -- Data value output
	end generate;

	out_decoder_1 : decoder5to32
	port map(i_D => src1,
		 o_D => read_addr_1);

	out_decoder_2 : decoder5to32
	port map(i_D => src2,
		 o_D => read_addr_2);

	out_mux_1: nbit_mux32to1
	port map(data_in => register_out,
		 sel => read_addr_1,
		 data_out => rdata1
	 );

	out_mux_2: nbit_mux32to1
	port map(data_in => register_out,
		 sel => read_addr_2,
		 data_out => rdata2
	 );


end structural;
