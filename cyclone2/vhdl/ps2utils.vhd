library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_misc.all;
use IEEE.std_logic_unsigned.all;

-- fuck everything: this module is atm just going to read the keyboard and output taps

package key_config is

 type tap_keys is array (11 downto 0) of std_logic_vector (7 downto 0);

end package key_config;