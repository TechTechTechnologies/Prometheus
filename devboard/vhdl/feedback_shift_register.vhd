library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_misc.all;

entity FEEDBACK_SHIFT_REGISTER is
  generic
  (
    DEPTH  : natural range 2 to natural'high := 8;
    SEED   : std_logic_vector;
  );
  port
  (
    CLOCK     : in  std_logic;
    RESET     : in  std_logic;

    ENABLE    : in  std_logic;
    DIRECTION : in  std_logic;
    BITS      : out std_logic_vector(DEPTH-1 downto 0);
    TAPS      : in  std_logic_vector(DEPTH-1 downto 0)
  );
end entity FEEDBACK_SHIFT_REGISTER;

architecture BEHAVIORAL of FEEDBACK_SHIFT_REGISTER is
  signal BITS_REG : std_logic_vector(BITS'range) := SEED;
  signal NEXT_BIT : std_logic := '0';
begin
  
  NEXT_BIT <= xor_reduce(BITS_REG and TAPS);
  BITS     <= BITS_REG;
  SHIFT_REGISTER : process (CLOCK) is
  begin
    if (rising_edge(CLOCK)) then
      if (RESET = '1') then
        BITS_REG <= SEED;
      else
        if (ENABLE = '1') then        
          if (DIRECTION = '1') then
            BITS_REG                 <= std_logic_vector(unsigned(BITS_REG) sll 1); 
            BITS_REG(BITS_REG'right) <= NEXT_BIT;
          else
            BITS_REG                 <= std_logic_vector(unsigned(BITS_REG) srl 1); 
            BITS_REG(BITS_REG'left)  <= NEXT_BIT;
          end if;
        else 
          BITS_REG <= BITS_REG;
        end if;
      end if;
    end if;
  end process SHIFT_REGISTER;

end architecture BEHAVIORAL;

