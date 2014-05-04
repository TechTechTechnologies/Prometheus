library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;

use work.wm8731_defs.all;

entity WM8731_CODEC is
  generic 
  ( 
    BITDEPTH : natural range 1 to 16 := 16
  );
  port
  (
    CLOCK : in  std_logic;
    RESET : in  std_logic;

    WR_RATE : in  std_logic;
    RATE    : in  std_logic_vector(BITDEPTH-1 downto 0);
    WR_GAIN : in  std_logic;
    GAIN    : in  std_logic_vector(BITDEPTH-1 downto 0);
  
    WR_DATA   : in  std_logic;
    LEFT_DAC  : in  std_logic_vector(BITDEPTH-1 downto 0);
    RIGHT_DAC : in  std_logic_vector(BITDEPTH-1 downto 0);
    LEFT_ADC  : out std_logic_vector(BITDEPTH-1 downto 0);
    RIGHT_ADC : out std_logic_vector(BITDEPTH-1 downto 0);

    -- physical interface signals
    BCLK   : inout std_logic := 'Z';
    ADCLRC : inout std_logic := 'Z';
    DACLRC : inout std_logic := 'Z';
    ADCDAT : in    std_logic;
    DACDAT : out   std_logic := '0'
  );
end entity WM8731_CODEC;

architecture BEHAVIORAL of WM8731_CODEC is
  type STATE_TYPE is (IDLE, CONFIG, DATA);
  signal STATE : STATE_TYPE := IDLE;

  signal SPI_READY   : std_logic := '0';
  signal SPI_VALID   : std_logic := '0';
  signal ADC_WORD    : std_logic_vector(BITDEPTH-1 downto 0);
  signal DAC_WORD    : std_logic_vector(BITDEPTH-1 downto 0) := (others => '0');
  signal SERDES_MOSI : std_logic := '0';
  signal SERDES_MISO : std_logic := '0';

  component SPI_SERDES is
    generic
    (
      SERIAL_WIDTH    : natural range 1 to 32 := 8;
      PARALLEL_WIDTH  : natural range 1 to 32 := 8;
      WORDS           : natural range 1 to natural'high := 2;
    
      CLOCK_DIVIDER   : natural range 1 to natural'high := 1;
      CLOCK_POLARITY  : std_logic := '0';
      ENABLE_POLARITY : std_logic := '0';

      MASTER          : boolean   := true;
      LSB_FIRST       : std_logic := '1'
    );
    port
    (
      CLOCK               : in std_logic;
      RESET               : in std_logic;

      SERIAL_CLOCK        : inout std_logic := not(CLOCK_POLARITY);
      SERIAL_ENABLE       : inout std_logic := not(ENABLE_POLARITY);
      SERIAL_MOSI         : inout std_logic := '0';
      SERIAL_MISO         : inout std_logic := '0';

      READY_FOR_DATA      : out std_logic;
      OUTGOING_WORD_VALID : in  std_logic;
      OUTGOING_WORD       : in  std_logic_vector(PARALLEL_WIDTH-1 downto 0);
      INCOMING_WORD       : out std_logic_vector(PARALLEL_WIDTH-1 downto 0) := (others => '0')
    );
  end component SPI_SERDES;
begin
  
  WRITE_TEST_DATA :
  process (CLOCK) is
  begin
    if (rising_edge(CLOCK)) then
      if (RESET = '1') then
        STATE    <= IDLE;
        DAC_WORD <= (others => '0');
      else
        case (STATE) is
          when IDLE =>
            if (SPI_READY = '1') then
              STATE <= DATA;
              SPI_VALID <= '1';
              if (DAC_WORD = DAC_WORD'high) then
                DAC_WORD <= (others => '0');
              else
                DAC_WORD <= DAC_WORD + 1;
              end if;
            else
              STATE <= IDLE;
              SPI_VALID <= '0';
            end if;

          when DATA =>
            STATE <= IDLE;
            SPI_VALID <= '0';

          when others =>
            STATE <= IDLE;
            SPI_VALID <= '0';
            
        end case;
      end if;
    end if;
  end process;

  STATE_MACHINE_COMBINATIONAL :
  process (RESET, STATE) is
  begin
    if (RESET = '1') then
      
    else
      case (STATE) is
        when IDLE =>
        when DATA =>
        when others =>
          
      end case;
    end if;
  end process STATE_MACHINE_COMBINATIONAL;

  DACDAT      <= SERDES_MOSI;
  SERDES_MISO <= ADCDAT;
  WM8731_SERDES :
  SPI_SERDES
    generic map
    (
      SERIAL_WIDTH    => 16,
      PARALLEL_WIDTH  => 16,
    
      CLOCK_DIVIDER   => 3,
      CLOCK_POLARITY  => '0',
      ENABLE_POLARITY => '0',

      MASTER          => true,
      LSB_FIRST       => '0'
    )
    port map
    (
      CLOCK               => CLOCK,
      RESET               => RESET,

      SERIAL_CLOCK        => BCLK,
      SERIAL_ENABLE       => open,
      SERIAL_MOSI         => SERDES_MOSI,
      SERIAL_MISO         => SERDES_MISO,

      READY_FOR_DATA      => SPI_READY,
      OUTGOING_WORD_VALID => SPI_VALID,
      OUTGOING_WORD       => DAC_WORD,
      INCOMING_WORD       => ADC_WORD
    );


end architecture BEHAVIORAL;
