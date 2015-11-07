library IEEE;
use IEEE.std_logic_1164.all;
use work.mips32.all;

entity nbit_mux32to1 is 
    port(data_in : in m32_regval_array := (others => x"00000000");
         sel     : in m32_word;
         data_out: out m32_word := x"00000000"
         );
end nbit_mux32to1;

architecture behavior of nbit_mux32to1 is

begin
    selection : process (data_in, sel)
    begin
        for y in 1 to 31 loop
            if(sel(y) = '1') then
                data_out <= data_in(y);
            end if;
        end loop;
        if(sel(0) = '1') then
            data_out <= x"00000000";
        end if;
    end process selection;

end behavior;

