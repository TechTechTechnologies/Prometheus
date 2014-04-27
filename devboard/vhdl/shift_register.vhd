library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity SHIFT_REGISTER is
  generic
  (
    INIT           : std_logic_vector;
	 DIRECTIONALITY : integer range -1 to 1 := 0
  );
  port
  (
    CLOCK     : in  std_logic;
	 RESET     : in  std_logic;
	 
	 LOAD      : in  std_logic;
	 BITS_IN   : in  std_logic_vector(INIT'range);
	 
	 STEP      : in  std_logic;
	 DIRECTION : in  std_logic;
	 BITS_OUT  : out std_logic_vector(INIT'range) := INIT;
	 NEXT_BIT  : in  std_logic
  );
end entity SHIFT_REGISTER;

architecture BEHAVIORAL of SHIFT_REGISTER is
  signal BITS_REG : std_logic_vector(INIT'range) := INIT;
begin

  BITS_OUT <= BITS_REG;
  
  GENERATE_BIDIRECTIONAL_SHIFT_REGISTER : 
  if (DIRECTIONALITY = 0) generate
    BIDIRECTIONAL_SHIFT_REGISTER : process (CLOCK) is
    begin
      if (rising_edge(CLOCK)) then
        if (RESET = '1') then
          BITS_REG <= INIT;
        else
		    if (LOAD = '1') then
			   BITS_REG <= BITS_IN;
		    else
            if (STEP = '1') then        
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
      end if;
    end process BIDIRECTIONAL_SHIFT_REGISTER;
  end generate GENERATE_BIDIRECTIONAL_SHIFT_REGISTER;
  
  GENERATE_LEFT_SHIFT_REGISTER : 
  if (DIRECTIONALITY = -1) generate
    LEFT_SHIFT_REGISTER : process (CLOCK) is
    begin
      if (rising_edge(CLOCK)) then
        if (RESET = '1') then
          BITS_REG <= INIT;
        else
		    if (LOAD = '1') then
			   BITS_REG <= BITS_IN;
		    else
            if (STEP = '1') then        
              BITS_REG                 <= std_logic_vector(unsigned(BITS_REG) sll 1); 
              BITS_REG(BITS_REG'right) <= NEXT_BIT;
            else 
              BITS_REG <= BITS_REG;
            end if;
		    end if;
        end if;
      end if;
    end process LEFT_SHIFT_REGISTER;
  end generate GENERATE_LEFT_SHIFT_REGISTER;
  
  GENERATE_RIGHT_SHIFT_REGISTER : 
  if (DIRECTIONALITY = 1) generate
    RIGHT_SHIFT_REGISTER : process (CLOCK) is
    begin
      if (rising_edge(CLOCK)) then
        if (RESET = '1') then
          BITS_REG <= INIT;
        else
		    if (LOAD = '1') then
			   BITS_REG <= BITS_IN;
		    else
            if (STEP = '1') then  
              BITS_REG                 <= std_logic_vector(unsigned(BITS_REG) srl 1); 
              BITS_REG(BITS_REG'left)  <= NEXT_BIT;
            else 
              BITS_REG <= BITS_REG;
            end if;
		    end if;
        end if;
      end if;
    end process RIGHT_SHIFT_REGISTER;
  end generate GENERATE_RIGHT_SHIFT_REGISTER;

end architecture BEHAVIORAL;