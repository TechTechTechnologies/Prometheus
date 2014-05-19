library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

use work.utilities.all;

entity FEEDBACK_CONTROLLER is
  generic
  (
    DEPTH: natural range 2 to natural'high := 3
  );
  port
  (
    MODE : in std_logic_vector (vector_length(DEPTH) downto 0);
  
    BITS_IN : in std_logic_vector ( DEPTH-1 downto 0);
    BITS_OUT : out std_logic_vector ( DEPTH-1 downto 0)
  );
end entity FEEDBACK_CONTROLLER;


architecture BEHAVIORAL of FEEDBACK_CONTROLLER is
begin

  BITS_OUT <= std_logic_vector(unsigned(BITS_IN) rol unsigned(MODE)); --nonzero modes pass feedback from LFSRx to LFSR(x+MODE)

end architecture BEHAVIORAL;
