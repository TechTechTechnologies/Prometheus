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
use work.utilities.all;


entity PS2_KEYBOARD is
  generic
  (
    WAIT_TIME : natural range 1 to natural'high := 2;
    BUFFER_LENGTH   : natural range 11 to natural'high := 11;
    
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
    PS2_CLOCK : in std_logic;
    
    KEYOUT : out std_logic_vector (23 downto 0);
    BUFFER_OUT : out std_logic_vector (BUFFER_LENGTH-1 downto 0);
    
    STATUS           : out std_logic_vector(4 downto 0);
    
    TAPS0     : out std_logic_vector (11 downto 0);
    TAPS1     : out std_logic_vector (11 downto 0);
    TAPS2     : out std_logic_vector (11 downto 0)
  );
end entity PS2_KEYBOARD;

architecture BEHAVIORAL of PS2_KEYBOARD is

  component PS2_SERDES
    generic
    (
      BUFFER_LENGTH   : natural range 11 to natural'high := BUFFER_LENGTH;
      WORD_LENGTH     : natural range 1 to natural'high := 11;
      CLOCK_DIVIDER   : natural range 1 to natural'high := 4;
      CLOCK_POLARITY  : std_logic := '0'
    );
    port
    (
      CLOCK               : in std_logic;
      RESET               : in std_logic;
   
      PS2_CLOCK        : in std_logic := not(CLOCK_POLARITY);
      PS2_DATA         : inout std_logic := '0';

      BUFFER_OUT       : out std_logic_vector(BUFFER_LENGTH-1 downto 0) := (others => '0');
      
      WORDC_OUT        : out std_logic_vector(7 downto 0);--------------------------------------------------- WORD_COUNTER DEBUG
      
      INCOMING_WORD       : out std_logic_vector(WORD_LENGTH-1 downto 0) := (others => '0');
      INCOMING_WORD_VALID : out std_logic
    );
  end component;

  type STATE_TYPE is (IDLE, DATA_SETTLE, SETAPS);
  signal STATE : STATE_TYPE := IDLE;
  signal COUNTER : std_logic_vector(vector_length(WAIT_TIME)  downto 0) := (others => '0');
  
  signal TAPS0_I  : std_logic_vector (11 downto 0);
  signal TAPS1_I  : std_logic_vector (11 downto 0);
  signal TAPS2_I  : std_logic_vector (11 downto 0);

  signal NTAPS0   : std_logic_vector (11 downto 0);
  signal NTAPS1   : std_logic_vector (11 downto 0);
  signal NTAPS2   : std_logic_vector (11 downto 0);
  
  signal DATA     : std_logic_vector (10 downto 0); --8 downto 1
  
  signal KEY      : std_logic_vector (7 downto 0);
  signal KEYS     : std_logic_vector (23 downto 0);
  --signal PARITY   : std_logic;
  
  signal KTYPE    : std_logic := '1';  
  signal EXT      : std_logic;
  signal IN_VALID : std_logic;
  
  signal WORDC_I : std_logic_vector (7 downto 0); -------------------------------------------------------- WORD_COUNTER DEBUG
  signal WORD_COUNTER : std_logic_vector (7 downto 0) := X"00"; ------------------------------------------ WORD_COUNTER DEBUG
  --signal WORD_DIFF : std_logic_vector (7 downto 0); ------------------------------------------------------ WORD_COUNTER DEBUG
begin

  --PARITY <= xor_reduce(KEY);
  --KEYOUT <= X"FF" when (PARITY = DATA(9)) else X"00";

  KEYOUT <= KEYS;
  TAPS0 <= TAPS0_I;
  TAPS1 <= TAPS1_I;
  TAPS2 <= TAPS2_I;

  --WORD_DIFF <= WORDC_I - WORD_COUNTER; -------------------------------------------------------------- WORD_COUNTER DEBUG
  
  --STATUS <= WORD_DIFF(4 downto 0);  ----------------------------------------------------------------------- WORD_COUNTER DEBUG
  STATUS(2) <= '1' when (WORDC_I > WORD_COUNTER) else '0';  -- more words interface than decoder
  STATUS(3) <= '1' when (WORDC_I < WORD_COUNTER) else '0'; -- more word decoder than interface
  
  STATUS(1 downto 0) <= EXT & KTYPE;
--  STATUS(2) <= '1' when (STATE = IDLE) else '0';
--  STATUS(3) <= '1' when (STATE = DATA_SETTLE) else '0';
--  STATUS(4) <= '1' when (STATE = SETAPS) else '0';
  
  SCAN_LOOKUP :
  for I in 0 to 11 generate
    NTAPS0(I) <= KTYPE when (KEY = taps_k0(I)) else TAPS0_I(i);
    NTAPS1(I) <= KTYPE when (KEY = taps_k1(I)) else TAPS1_I(i);
    NTAPS2(I) <= KTYPE when (KEY = taps_k2(I)) else TAPS2_I(i);  
  end generate SCAN_LOOKUP;
  
  STATE_MACHINE:
  process (CLOCK) is
  begin
    if(rising_edge(CLOCK)) then
      if(reset = '1') then
        STATE <= IDLE;
        WORD_COUNTER <= (others => '0'); ---------------------------------------------------- WORD_COUNTER DEBUG
      elsif (STATE = IDLE) then
        if(IN_VALID = '1') then
          STATE <= DATA_SETTLE;
          WORD_COUNTER <= WORD_COUNTER + 1;  ------------------------------------------------ WORD_COUNTER DEBUG
        else
          STATE <= IDLE;
        end if;
      elsif (STATE = DATA_SETTLE) then
        if(COUNTER = WAIT_TIME and IN_VALID = '0') then
          STATE <= SETAPS;
        else
          STATE <= DATA_SETTLE;
        end if;
      elsif (STATE = SETAPS) then
        STATE <= IDLE;
      else
        STATE <= IDLE;
      end if;
    end if;
  end process;
  
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
        KEY <= X"00";
        COUNTER <= (others => '0');
      else
        if (STATE = IDLE) then
          KTYPE <= KTYPE;
          EXT <= EXT;
          KEY <= KEY;
          COUNTER <= (others => '0');
        elsif(STATE = DATA_SETTLE) then
          if(COUNTER /= WAIT_TIME) then
            COUNTER <= COUNTER + 1;
          end if;
          KEY <= DATA(8 downto 1);
        elsif(STATE = SETAPS) then
          KEY <= KEY;
          KEYS <= KEYS(15 downto 0) & KEY;
          if (KEY = X"F0") then
            KTYPE <= '0';
          elsif (KEY = X"E0") then
            EXT <= '1';
          else          
            TAPS0_I <= NTAPS0;
            TAPS1_I <= NTAPS1;
            TAPS2_I <= NTAPS2;
            KTYPE <= '1';
            EXT <= '0';
          end if;
        end if;
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
      BUFFER_OUT => BUFFER_OUT,
      WORDC_OUT => WORDC_I,----------------------------------------------------------------------------- WORD_COUNTER DEBUG

      INCOMING_WORD => DATA,
      INCOMING_WORD_VALID => IN_VALID
    );
  

end architecture BEHAVIORAL;