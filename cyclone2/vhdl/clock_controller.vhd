library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity CLOCK_CONTROLLER is
  port
  (
    CLOCK : in std_logic;
    RESET : in std_logic;
    SET   : in std_logic;
    
    REG_SELECT : in std_logic_vector (2 downto 0);
    DATA       : in std_logic_vector (15 downto 0);
    
    CLK0 : out std_logic;
    CLK1 : out std_logic;
    CLK2 : out std_logic
  );
end entity CLOCK_CONTROLLER;

architecture BEHAVIORAL of CLOCK_CONTROLLER is
  
  type SEL is (Div0, Div1, Div2, Off0, Off1, Off2);
  
  signal COUNTER0 : std_logic_vector (15 downto 0) := X"0000";
  signal COUNTER1 : std_logic_vector (15 downto 0) := X"0000";
  signal COUNTER2 : std_logic_vector (15 downto 0) := X"0000";
  
  signal EQ0 : boolean := FALSE;
  signal EQ1 : boolean := FALSE;
  signal EQ2 : boolean := FALSE;  
  
  signal DIVIDER0 : std_logic_vector (15 downto 0) := X"0001";
  signal DIVIDER1 : std_logic_vector (15 downto 0) := X"0001";
  signal DIVIDER2 : std_logic_vector (15 downto 0) := X"0001";  

  signal OFFSET0 : std_logic_vector (15 downto 0) := X"0000";
  signal OFFSET1 : std_logic_vector (15 downto 0) := X"0000";
  signal OFFSET2 : std_logic_vector (15 downto 0) := X"0000"; 

  signal RATIO0 : std_logic_vector (15 downto 0);
  signal RATIO1 : std_logic_vector (15 downto 0);
  signal RATIO2 : std_logic_vector (15 downto 0);
begin

  RATIO0 <= std_logic_vector(signed(DIVIDER0) + signed(OFFSET0));
  RATIO1 <= std_logic_vector(signed(DIVIDER1) + signed(OFFSET1));
  RATIO2 <= std_logic_vector(signed(DIVIDER2) + signed(OFFSET2));

  EQ0 <= (unsigned(COUNTER0) = unsigned(RATIO0));
  EQ1 <= (unsigned(COUNTER1) = unsigned(RATIO1));
  EQ2 <= (unsigned(COUNTER2) = unsigned(RATIO2));

  process (CLOCK) is
  begin
    if(rising_edge(CLOCK)) then
      if(RESET = '1') then
        COUNTER0 <= X"0000";
        COUNTER1 <= X"0000";
        COUNTER2 <= X"0000";
        CLK0 <= '0';
        CLK1 <= '0';
        CLK2 <= '0';
      elsif(SET = '1') then
        case REG_SELECT is
        when Div0 =>
          DIVIDER0 <= DATA;
          COUNTER0 <= X"0000";
        when Div1 =>
          DIVIDER1 <= DATA;
          COUNTER1 <= X"0000";
        when Div2 =>
          DIVIDER2 <= DATA;
          COUNTER2 <= X"0000";
        when Off0 =>
          OFFSET0  <= DATA;
          COUNTER0 <= X"0000";
        when Off1 =>
          OFFSET1  <= DATA;
          COUNTER1 <= X"0000";
        when Off2 =>
          OFFSET2  <= DATA;
          COUNTER2 <= X"0000";
        end case;
      else
        if(EQ0) then
          COUNTER0 <= X"0000";
          CLK0 <= not CLK0;
        else
          COUNTER0 <= COUNTER0+ X"0001";
        end if;

        if(EQ1) then
          COUNTER1 <= X"0000";
          CLK1 <= not CLK1;
        else
          COUNTER1 <= COUNTER1+ X"0001";
        end if;

        if(EQ2) then
          COUNTER2 <= X"0000";
          CLK2 <= not CLK2;
        else
          COUNTER2 <= COUNTER2+ X"0001";
        end if;

      end if;
    end if;
  end process;


end architecture BEHAVIORAL;