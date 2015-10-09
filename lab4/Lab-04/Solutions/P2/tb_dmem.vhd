library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;

entity test_bench is
end entity test_bench;

architecture test_mem of test_bench is
    signal address  : std_logic_vector (9 downto 0);
    signal byteena  : std_logic_vector (3 downto 0):= (OTHERS => '1');
	signal clock	: STD_LOGIC := '1';
	signal data		: STD_LOGIC_VECTOR (31 DOWNTO 0) := (OTHERS => '0');
	signal wren		: STD_LOGIC := '0';
	signal q		: STD_LOGIC_VECTOR (31 DOWNTO 0);

begin 
    mem1: entity work.mem
            port map (address, byteena, clock, data, wren, q);

    stimulus: process is
    begin
        address <= "0000000000";
        wait for 20  ns;
        address <= "0000000001";
        wait for 20  ns;
        address <= "0000000010";
        wait for 20  ns;
        address <= "0000000011";
        wait for 20  ns;
        address <= "0000000100";
        wait for 20  ns;
        address <= "0000000101";
        wait for 20  ns;
        address <= "0000000110";
        wait for 20  ns;
        address <= "0000000111";
        wait for 20  ns;
        address <= "0000001000";
        wait for 20  ns;
        address <= "0000001001";
        wait for 20  ns;

        wait for 200 ns;

        --Address 0 - 100
        address <= "0000000000";
        wait for 20  ns;
        data <= q;
        wait for 20  ns;
        address <= "0001100100";
        wait for 20 ns;
        wren <= '1';
        wait for 200  ns;

        --Address 1 - 101
        wren <= '0';
        address <= "0000000001";
        wait for 20  ns;
        data <= q;
        wait for 20  ns;
        address <= "0001100101";
        wait for 20  ns;
        wren <= '1';
        wait for 200  ns;

        --Address 2 - 102
        wren <= '0';
        wait for 20  ns;
        address <= "0000000010";
        wait for 20  ns;
        data <= q;
        wait for 20  ns;
        address <= "0001100110";
        wait for 20  ns;
        wren <= '1';
        wait for 200  ns;

        --Address 3 - 103
        wren <= '0';
        wait for 20  ns;
        address <= "0000000011";
        wait for 20  ns;
        data <= q;
        wait for 20  ns;
        address <= "0001100111";
        wait for 20  ns;
        wren <= '1';
        wait for 200  ns;

        --Address 4 - 104
        wren <= '0';
        wait for 20  ns;
        address <= "0000000100";
        wait for 20  ns;
        data <= q;
        wait for 20  ns;
        address <= "0001101000";
        wait for 20  ns;
        wren <= '1';
        wait for 200  ns;

        --Address 5 - 105
        wren <= '0';
        wait for 20  ns;
        address <= "0000000101";
        wait for 20  ns;
        data <= q;
        wait for 20  ns;
        address <= "0001101001";
        wait for 20  ns;
        wren <= '1';
        wait for 200  ns;

        --Address 6 - 106
        wren <= '0';
        wait for 20  ns;
        address <= "0000000110";
        wait for 20  ns;
        data <= q;
        wait for 20  ns;
        address <= "0001101010";
        wait for 20  ns;
        wren <= '1';
        wait for 200  ns;

        --Address 7 - 107
        wren <= '0';
        wait for 20  ns;
        address <= "0000000111";
        wait for 20  ns;
        data <= q;
        wait for 20  ns;
        address <= "0001101011";
        wait for 20  ns;
        wren <= '1';
        wait for 200  ns;

        wren <= '0';
        wait for 20  ns;
        address <= "0000001000";
        wait for 20  ns;
        data <= q;
        wait for 20  ns;
        address <= "0001101100";
        wait for 20  ns;
        wren <= '1';
        wait for 200  ns;

        wren <= '0';
        wait for 20  ns;
        address <= "0000001001";
        wait for 20  ns;
        data <= q;
        wait for 20  ns;
        address <= "0001101101";
        wait for 20  ns;
        wren <= '1';
        wait for 200 ns;

        wren <= '0';
        wait for 20  ns;
    end process stimulus;
end architecture test_mem;
