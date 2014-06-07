--Uses files:
--ps2_serdes.vhd
--feedback_controller.vhd
--utilities.vhd
--shift_register.vhd
--external_feedback_shift_register.vhd
--clock_controller.vhd
--boot_controller.vhd
--ps2utils.vhd
--spi_serdes_ps2.vhd

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_misc.all;
use IEEE.std_logic_unsigned.all;
use work.key_config.all;

entity PS2_KEYBOARD is
  generic
  (
    --                      Z      X      C      A      S      D      Q      W      E      1      2      3        
    taps_k2 : tap_keys := (X"1A", X"22", X"21", X"1C", X"1B", X"23", X"15", X"1d", X"24", X"16", X"1E", X"26");
    --                      V      B      N      F      G      H      R      T      Y      4      5      6       
    taps_k1 : tap_keys := (X"2A", X"32", X"31", X"2B", X"34", X"33", X"2D", X"2C", X"35", X"25", X"2E", X"36");
    --                      M      ,      .      J      K      L      U      I      O      7      8      9
    taps_k0 : tap_keys := (X"3A", X"41", X"49", X"3B", X"42", X"4B", X"3C", X"43", X"44", X"3D", X"3E", X"46")
  );
  port
  (
    CLOCK     : in std_logic;
    RESET     : in std_logic;
  
    PS2_DATA  : inout std_logic;
    PS2_CLOCK : inout std_logic;
    
    KEYOUT : out std_logic_vector (7 downto 0);
    
    TAPS0     : out std_logic_vector (11 downto 0);
    TAPS1     : out std_logic_vector (11 downto 0);
    TAPS2     : out std_logic_vector (11 downto 0)
  );
end entity PS2_KEYBOARD;

architecture BEHAVIORAL of PS2_KEYBOARD is

  component PS2_SERDES
    generic
    (
      WORD_LENGTH     : natural range 1 to natural'high := 11;
      CLOCK_DIVIDER   : natural range 1 to natural'high := 8;
      CLOCK_POLARITY  : std_logic := '0';
      ENABLE_POLARITY : std_logic := '0'
    );
    port
    (
      CLOCK               : in std_logic;
      RESET               : in std_logic;
   
      PS2_CLOCK        : inout std_logic := not(CLOCK_POLARITY);
      PS2_ENABLE       : inout std_logic := not(ENABLE_POLARITY);
      PS2_DATA         : inout std_logic := '0';

      INCOMING_WORD       : out std_logic_vector(10 downto 0) := (others => '0');
      INCOMING_WORD_VALID : out std_logic
    );
  end component;

  signal TAPS0_I  : std_logic_vector (11 downto 0);
  signal TAPS1_I  : std_logic_vector (11 downto 0);
  signal TAPS2_I  : std_logic_vector (11 downto 0);
  
  signal DATA     : std_logic_vector (10 downto 0); --8 downto 1
  
  signal KEY      : std_logic_vector (7 downto 0);
  signal PARITY   : std_logic;
  
  signal KTYPE    : std_logic;  
  signal EXT      : std_logic;
  signal IN_VALID : std_logic;
begin

  KEYOUT <= KEY;
  TAPS0 <= TAPS0_I;
  TAPS1 <= TAPS1_I;
  TAPS2 <= TAPS2_I;
  
  SCAN_DECODE:
  process (CLOCK) is 
  begin
    if(rising_edge(CLOCK)) then
      if(reset = '1') then
        TAPS0_I <= X"000";
        TAPS1_I <= X"000";
        TAPS2_I <= X"000";
        KTYPE <= '1';
        EXT <= '0';
      elsif(IN_VALID = '1') then
        if (KEY = X"F0") then
          KTYPE <= '0';
        elsif (KEY = X"E0") then
          EXT <= '1';
        else
          for I in 0 to 11 loop
            if(KEY = taps_k0(I)) then
              TAPS0_I(I) <= KTYPE;
            end if;
            if(KEY = taps_k1(I)) then
              TAPS1_I(I) <= KTYPE;
            end if;
            if(KEY = taps_k2(I)) then
              TAPS2_I(I) <= KTYPE;
            end if;
          end loop;
          KTYPE <= '1';
          EXT <= '0';
        end if;
      end if;
    end if;
  end process;
  
  process (CLOCK) is
  begin
    if(rising_edge(CLOCK)) then
      if(RESET = '1') then
        KEY <= X"00";
      elsif(IN_VALID = '0') then
        KEY <= KEY;
      else
        KEY <= DATA(8 downto 1);
      end if;
    
    end if;
  end process;
  
  PS2 : PS2_SERDES
    port map
    (
      CLOCK => CLOCK,
      RESET => RESET,
      PS2_CLOCK => PS2_CLOCK,
      PS2_DATA => PS2_DATA,
      PS2_ENABLE => '0',
      INCOMING_WORD => DATA,
      INCOMING_WORD_VALID => IN_VALID
    );
  

end architecture BEHAVIORAL;