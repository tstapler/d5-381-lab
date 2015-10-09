library IEEE;
use IEEE.std_logic_1164.all;

entity register_file is
    generic(N : integer := 32);
    port(in_addr : in std_logic_vector(4 downto 0);
         data_in : in std_logic_vector(31 downto 0);
         clock : in std_logic;
         reset : in std_logic;
         write_enable : in std_logic;
         read_addr_sel_1 : in std_logic_vector(4 downto 0);
         read_addr_sel_2 : in std_logic_vector(4 downto 0);
         read_out_1 : out std_logic_vector(31 downto 0);
         read_out_2 : out std_logic_vector(31 downto 0));
end register_file;

architecture mixed of register_file is

    read_out_1 <= "00000000000000000000000000000000";
    read_out_2 <= "00000000000000000000000000000000";
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

    signal write_addr, read_addr_1, read_addr_2 :std_logic_vector(31 downto 0);
    type out_array is array(31 downto 0) of std_logic_vector(31 downto 0);
    signal register_out : out_array;
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

    read_select_1: process (read_addr_1)
    begin
        for z in 0 to 31 loop
            if(read_addr_1(z) = '1') then
                read_out_1 <= register_out(z);
            end if;
        end loop;
    end process read_select_1;

    read_select_2: process (read_addr_2)
    begin
        for y in 0 to 31 loop
            if(read_addr_2(y) = '1') then
                read_out_2 <= register_out(y);
            end if;
        end loop;
    end process read_select_2;

end mixed;
