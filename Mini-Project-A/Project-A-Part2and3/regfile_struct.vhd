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
  generic (DELAY : time := 9.5 ns);
  port(src1   : in  m32_5bits;
       src2   : in  m32_5bits;
       dst    : in  m32_5bits;
       wdata  : in  m32_word;
       rdata1 : out m32_word;
       rdata2 : out m32_word;
       WE     : in  m32_1bit;
       clock  : in  m32_1bit);
end regfile;

architecture structural of regfile is
    signal write_addr, read_addr_1, read_addr_2 :std_logic_vector(31 downto 0);
    type out_array is array(31 downto 0) of std_logic_vector(31 downto 0);
    signal register_out : out_array;

    component decoder5to32
        port (i_D  : in std_logic_vector(4 downto 0);
              o_D  : out std_logic_vector(31 downto 0));
    end component;

    component n_bit_register
      port(i_CLK        : in std_logic;     -- Clock input
           i_RST        : in std_logic;     -- Reset input
           i_WE         : in std_logic;     -- Write enable input
           i_Data          : in std_logic_vector(31 downto 0);     -- Data value input
           o_Data          : out std_logic_vector(31 downto 0));   -- Data value output
    end component;

    component n_in_lab3_multiplexer_struct
        port(i_A  : in std_logic_vector(31 downto 0);
             i_B  : in std_logic_vector(31 downto 0);
             i_C  : in std_logic;
             o_F  : out std_logic_vector(31 downto 0));
    end component;

    component nbit_mux32to1
        port(data_in : in out_array;
             sel     : in std_logic_vector (31 downto 0);
             data_out: in std_logic_vector (31 downto 0));
    end component;


begin

    in_decoder : decoder5to32
        port map(i_D => in_addr,
                o_D => write_addr);

    G1: for j in 0 to N-1 generate
        signal internal_enable :std_logic ;
        internal_enable <=   (write_addr(j) and write_enable);
        register_j : n_bit_register
            port map(i_CLK        => clock,     -- Clock input
                     i_RST        => reset,     -- Reset input
                     i_WE         => internal_enable,     -- Write enable input
                     i_Data          => data_in,     -- Data value input
                     o_Data          => register_out(j));   -- Data value output
    end generate;

    out_decoder_1 : decoder5to32
        port map(i_D => read_addr_sel_1,
                o_D => read_addr_1);

    out_decoder_2 : decoder5to32
        port map(i_D => read_addr_sel_2,
                o_D => read_addr_2);

        out_mux_1: nbit_mux32to1
        port map(data_in => register_out,
                 sel => read_addr_1;
                data_out => data1;
        );

        out_mux_2: nbit_mux32
        port map(data_in => register_out,
                 sel => read_addr_2;
                data_out => data2;
    );


end structural;
