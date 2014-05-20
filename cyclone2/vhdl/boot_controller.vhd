library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;

entity BOOT_CONTROLLER is
  generic
  (
    CLKDIV0 : std_logic_vector (15 downto 0) := X"0BAA"; --5972/2
    CLKDIV1 : std_logic_vector (15 downto 0) := X"1754";  --5972 C's
    CLKDIV2 : std_logic_vector (15 downto 0) := X"2EA9"; --11945
    CLKOFF0 : std_logic_vector (15 downto 0) := X"0000";
    CLKOFF1 : std_logic_vector (15 downto 0) := X"0000";
    CLKOFF2 : std_logic_vector (15 downto 0) := X"0000"
  );
  port
  (
    CLOCK : in std_logic;
    RESET : in std_logic;
    
    CCTRL_RESET  : out std_logic;
    CCTRL_SET    : out std_logic;
    CCTRL_SELECT : out std_logic_vector (2 downto 0);
    CCTRL_DATA   : out std_logic_vector (15 downto 0);

    L0_RESET     : out std_logic;
    L1_RESET     : out std_logic;
    L2_RESET     : out std_logic
  );
end entity BOOT_CONTROLLER;

architecture BEHAVIORAL of BOOT_CONTROLLER is
  type  states is (init, setDiv0, setOff0, setDiv1, setOff1, setDiv2, setOff2, w00, w01, w10, w11, w20, w21, done);

  signal STATE : states := init; 

begin

  L0_RESET <= '0' when STATE = done else '1';
  L1_RESET <= '0' when STATE = done else '1';
  L2_RESET <= '0' when STATE = done else '1';

  CCTRL_RESET <= '1' when STATE = init else '0';
  CCTRL_SET <= '1' when STATE = setDiv0 or
                        STATE = setDiv1 or
                        STATE = setDiv2 or 
                        STATE = setOff0 or
                        STATE = setOff1 or
                        STATE = setOff2 else '0';
  CCTRL_SELECT <= "000" when STATE = setDiv0 else
                  "010" when STATE = setDiv1 else
                  "100" when STATE = setDiv2 else
                  "001" when STATE = setOff0 else
                  "011" when STATE = setOff1 else
                  "101" when STATE = setOff2 else
                  "111" ;

  CCTRL_DATA <= CLKDIV0 when STATE = setDiv0 else
                CLKDIV1 when STATE = setDiv1 else
                CLKDIV2 when STATE = setDiv2 else
                CLKOFF0 when STATE = setOff0 else
                CLKOFF1 when STATE = setOff1 else
                CLKOFF2 when STATE = setOff2 else
                X"0000" ;

  process (CLOCK) is
  begin
    if(rising_edge(CLOCK)) then
      if(RESET = '1') then
        STATE <= init;
      else
        case STATE is
        when init =>
          STATE <= setDiv0;
        when setDiv0 =>
          STATE <= w00;
        when setDiv1 =>
          STATE <= w10;
        when setDiv2 =>
          STATE <= w20;
        when setOff0 =>
          STATE <= w01;
        when setOff1 =>
          STATE <= w11;
        when setOff2 =>
          STATE <= w21;
        when w00 =>
          STATE <= setOff0;
        when w10 =>
          STATE <= setOff1;
        when w20 =>
          STATE <= setOff2;
        when w01 =>
          STATE <= setDiv1;
        when w11 =>
          STATE <= setDiv2;
        when w21 =>
          STATE <= done;
        when done =>
          STATE <= done;
        end case;
      end if;
    end if;
  
  end process;
  

end architecture BEHAVIORAL;