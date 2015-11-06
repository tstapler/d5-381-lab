library IEEE;
use IEEE.std_logic_1164.all;

type out_array is array(31 downto 0) of std_logic_vector(31 downto 0);

entity nbit_mux32to1 is 
    generic(N : integer := 32)
    port(data_in : in out_array;
         sel     : in std_logic_vector (31 downto 0);
         data_out: in std_logic_vector (31 downto 0);
         );
end nbit_mux32to1;

architecture mixed of nbit_mux32to1 is

    selection : process (data_in, sel)
    begin
        for y in 0 to 31 loop
            if(sel(y) = '1') then
                data_out <= data_in(y);
            end if;
        end loop;
    end process selection;

end behavior;

