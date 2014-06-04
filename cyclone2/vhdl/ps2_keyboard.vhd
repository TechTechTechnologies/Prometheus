library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;

-- fuck everything: this module is atm just going to read the keyboard and output taps

package key_config is

 type tap_keys is array (11 downto 0) of std_logic_vector (7 downto 0);

end package key_config

use work.key_config.all;

entity PS2_KEYBOARD is
  generic
  (
    --                      Z      X      C      A      S      D      Q      W      E      1      2      3        
    taps_k0 : tap_keys := (X"1A", X"22", X"21", X"1C", X"1B", X"23", X"15", X"1d", X"24", X"16", X"1E", X"26");
    --                      V      B      N      F      G      H      R      T      Y      4      5      6       
    taps_k1 : tap_keys := (X"2A", X"32", X"31", X"2B", X"34", X"33", X"2D", X"2C", X"35", X"25", X"2E", X"36");
    --                      M      ,      .      J      K      L      U      I      O      7      8      9
    taps_k2 : tap_keys := (X"3A", X"41", X"49", X"3B", X"42", X"4B", X"3C", X"43", X"44", X"3D", X"3E", X"46");
  );
  port
  (
    PS2_DATA  : inout std_logic;
    PS2_CLOCK : inout std_logic;
    
    TAPS0     : out std_logic_vector (11 downto 0);
    TAPS1     : out std_logic_vector (11 downto 0);
    TAPS2     : out std_logic_vector (11 downto 0);
  );
end entity PS2_KEYBOARD;

architecture BEHAVIORAL of PS2_KEYBOARD is
  signal COUNTER  : std_logic_vector (4 downto 0);
  
  signal DATA     : std_logic_vector (19 downto 0);
    
begin




end architecture BEHAVIORAL;