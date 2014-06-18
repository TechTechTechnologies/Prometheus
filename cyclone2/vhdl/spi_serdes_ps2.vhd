library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;

use work.utilities.all;

entity PS2_SERDES is
  generic
  (
    BUFFER_LENGTH   : natural range 11 to natural'high := 11;
    WORD_LENGTH     : natural range 1 to natural'high := 11;
    CLOCK_DIVIDER   : natural range 1 to natural'high := 8;
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
end entity;

architecture BEHAVIORAL of PS2_SERDES is

  type   SERIAL_INTERFACE_STATE_TYPE is (IDLE, CLK_LO, CLK_HI, DATA_VALID, DATA_IDLE);
  signal SERIAL_INTERFACE_STATE : SERIAL_INTERFACE_STATE_TYPE := IDLE;

  signal INCOMING_WORD_VALID_I : std_logic := '0';
  signal INCOMING_WORD_I       : std_logic_vector(INCOMING_WORD'range) := (others => '0');
  
  signal RX_BITS : std_logic_vector(BUFFER_LENGTH-1 downto 0) := (others => '0');
  
  signal CLOCK_COUNTER : std_logic_vector(vector_length(CLOCK_DIVIDER)  downto 0) := (others => '0');
  
  signal WORD_COUNTER : std_logic_vector(7 downto 0) := X"00";-------------------------------------------- WORD_COUNTER DEBUG
  
  signal BIT_COUNTER   : std_logic_vector(3 downto 0) := (others => '0');
  
  signal WORD_REGISTER  : std_logic_vector(BUFFER_LENGTH-1 downto 0) := (others => '0');
  
  component SHIFT_REGISTER is
    generic
    (
      INIT           : std_logic_vector;
      DIRECTIONALITY : integer range -1 to 1
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
  end component SHIFT_REGISTER;
begin

  INCOMING_WORD       <= INCOMING_WORD_I;
  INCOMING_WORD_VALID <= INCOMING_WORD_VALID_I; 
 
  BUFFER_OUT <= RX_BITS;
  WORDC_OUT <= WORD_COUNTER;--------------------------------------------------------------------------------- WORD_COUNTER DEBUG
 
  SERIAL_INTERFACE :
  process (CLOCK) is
  begin
    if (rising_edge(CLOCK)) then
      if (RESET = '1') then
        SERIAL_INTERFACE_STATE <= IDLE;
        CLOCK_COUNTER <= (others => '0');
        BIT_COUNTER   <= (others => '0');
        WORD_COUNTER  <= (others => '0'); ------------------------------------------------------------------- WORD_COUNTER DEBUG
      else
        case (SERIAL_INTERFACE_STATE) is
          when IDLE =>
            INCOMING_WORD_VALID_I <= '0';
            CLOCK_COUNTER <= (others => '0');
            BIT_COUNTER   <= (others => '0');
            
            if (PS2_CLOCK = CLOCK_POLARITY) then
              SERIAL_INTERFACE_STATE <= CLK_HI;
              WORD_COUNTER <= WORD_COUNTER + 1; ------------------------------------------------------------- WORD_COUNTER DEBUG
            else
              SERIAL_INTERFACE_STATE <= IDLE;
            end if;

          when CLK_HI =>
            CLOCK_COUNTER <= CLOCK_COUNTER + 1;          
          
            if (PS2_CLOCK = not(CLOCK_POLARITY)) then
              SERIAL_INTERFACE_STATE <= CLK_LO;
            else
              if(CLOCK_COUNTER = CLOCK_DIVIDER) then
                SERIAL_INTERFACE_STATE <= DATA_VALID;
              else
                SERIAL_INTERFACE_STATE <= CLK_HI;
              end if;
            end if;

          when DATA_VALID =>
            BIT_COUNTER <= BIT_COUNTER + 1;
            RX_BITS <= PS2_DATA & RX_BITS(BUFFER_LENGTH-1 downto 1);          
          
            if (PS2_CLOCK = not(CLOCK_POLARITY)) then
              SERIAL_INTERFACE_STATE <= CLK_LO;
            else
              SERIAL_INTERFACE_STATE <= DATA_IDLE;
            end if;
            
          when DATA_IDLE =>                               --latched in data and waiting for next transition
            if(BIT_COUNTER = WORD_LENGTH) then
              INCOMING_WORD_VALID_I <= '1';
            end if;
            if (PS2_CLOCK = not(CLOCK_POLARITY)) then
              if(BIT_COUNTER = WORD_LENGTH) then
                SERIAL_INTERFACE_STATE <= IDLE;
                INCOMING_WORD_I <= RX_BITS(BUFFER_LENGTH-1 downto BUFFER_LENGTH-WORD_LENGTH);
              else
                SERIAL_INTERFACE_STATE <= CLK_LO;
              end if;
            else
              SERIAL_INTERFACE_STATE <= DATA_IDLE;
            end if;
            
          when CLK_LO =>
            if (PS2_CLOCK = CLOCK_POLARITY) then
              SERIAL_INTERFACE_STATE <= CLK_HI;
              CLOCK_COUNTER <= (others => '0');      -- Rising edge of clock, reset clock counter
            else
              SERIAL_INTERFACE_STATE <= CLK_LO;
            end if;
          
          when others =>
            SERIAL_INTERFACE_STATE <= IDLE;
            
        end case;
      end if;
    end if;
  end process SERIAL_INTERFACE;

  PS2_DATA   <= 'Z';

end architecture BEHAVIORAL;

