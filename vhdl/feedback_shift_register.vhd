library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.reduce_pack.all;

entity FEEDBACK_SHIFT_REGISTER is
  generic
  (
    function REDUCE (ARG : std_logic_vector) return std_logic := xor_reduce
  )
  port
  (
    CLOCK     : in  std_logic;
    RESET     : in  std_logic;

    ENABLE    : in  std_logic;
    DIRECTION : in  std_logic;
    BITS      : out std_logic_vector := (others => '0')
    TAPS      : in  std_logic_vector(BITS'range)
  );
end entity FEEDBACK_SHIFT_REGISTER;

architecture BEHAVIORAL of FEEDBACK_SHIFT_REGISTER is
  BITS_REG : std_logic_vector(BITS'range) := (others => '0');
begin
  
  NEXT_BIT <= REDUCE(BITS_REG and TAPS);
  SHIFT_REGISTER : process (CLOCK) is
  begin
    if (rising_edge(CLOCK)) then
      if (RESET = '1') then
        BITS_REG <= (others => '0');
      else
        if (ENABLE = '1') then        
          if (DIRECTION = '1') then
            BITS_REG                <= BITS_REG sll 1; 
            BITS_REG(BITS_REG'low)  <= NEXT_BIT;
          else
            BITS_REG                <= BITS_REG srl 1;
            BITS_REG(BITS_REG'high) <= NEXT_BIT;
          end if;
        else 
          BITS_REG <= BITS_REG;
        end if;
      end if;
    end if;
  end process SHIFT_REGISTER;

end architecture BEHAVIORAL;

