library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;

use work.wm8731_defs.all;

entity WM8731_CODEC is
  generic 
  ( 
    BITDEPTH : natural range 1 to 16 := 24
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
    DACDAT : out   std_logic := '0';

    CONTROL_MODE : out   std_logic := '1'; -- select 3-wire/SPI mode
    CSB          : out   std_logic := '0';
    SCLK         : inout std_logic := '0';
    SDIN         : inout std_logic := '0'
  );
end entity WM8731_CODEC;

architecture BEHAVIORAL of WM8731_CODEC is
  type AUDIO_STATE_TYPE is (IDLE, CONFIG, DATA);
  signal AUDIO_STATE : AUDIO_STATE_TYPE := IDLE;
  
  type CONTROL_STATE_TYPE is (IDLE, CONFIG, DONE);
  signal CONTROL_STATE : CONTROL_STATE_TYPE := IDLE;

  signal AUDIO_SPI_READY   : std_logic := '0';
  signal AUDIO_SPI_VALID   : std_logic := '0';
  signal ADC_WORD          : std_logic_vector(BITDEPTH-1 downto 0);
  signal DAC_WORD          : std_logic_vector(BITDEPTH-1 downto 0) 
                               := (others => '0');
  signal AUDIO_SERDES_MOSI : std_logic := '0';
  signal AUDIO_SERDES_MISO : std_logic := '0';

  signal CONTROL_SERDES_ENABLE : std_logic := '0';
  signal CONTROL_SERDES_READY  : std_logic := '0';
  signal CONTROL_SERDES_VALID  : std_logic := '0';
  signal CONTROL_WORD          : std_logic_vector(15 downto 0);

  component BIDIR_SERDES is
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
      INCOMING_WORD       : out std_logic_vector(PARALLEL_WIDTH-1 downto 0) 
                                  := (others => '0')
    );
  end component BIDIR_SERDES;
begin
  
  WRITE_TEST_DATA :
  process (CLOCK) is
  begin
    if (rising_edge(CLOCK)) then
      if (RESET = '1') then
        AUDIO_STATE    <= IDLE;
        DAC_WORD <= (others => '0');
      else
        case (AUDIO_STATE) is
          when IDLE =>
            if (AUDIO_SPI_READY = '1') then
              AUDIO_STATE <= DATA;
              AUDIO_SPI_VALID <= '1';
              if (DAC_WORD = (BITDEPTH-1 downto 0 => '1')) then
                DAC_WORD <= (others => '0');
              else
                DAC_WORD <= DAC_WORD + 1;
              end if;
            else
              AUDIO_STATE <= IDLE;
              AUDIO_SPI_VALID <= '0';
            end if;

          when DATA =>
            AUDIO_STATE <= IDLE;
            AUDIO_SPI_VALID <= '0';

          when others =>
            AUDIO_STATE <= IDLE;
            AUDIO_SPI_VALID <= '0';
            
        end case;
      end if;
    end if;
  end process;

  AUDIO_STATE_MACHINE_COMBINATIONAL :
  process (RESET, AUDIO_STATE) is
  begin
    if (RESET = '1') then
      
    else
      case (AUDIO_STATE) is
        when IDLE =>
        when DATA =>
        when others =>
          
      end case;
    end if;
  end process AUDIO_STATE_MACHINE_COMBINATIONAL;

  DACDAT            <= AUDIO_SERDES_MOSI;
  AUDIO_SERDES_MISO <= ADCDAT;
  AUDIO_SERDES :
  BIDIR_SERDES
    generic map
    (
      SERIAL_WIDTH    => BITDEPTH,
      PARALLEL_WIDTH  => BITDEPTH,
    
      CLOCK_DIVIDER   => 2500,
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
      SERIAL_MOSI         => AUDIO_SERDES_MOSI,
      SERIAL_MISO         => AUDIO_SERDES_MISO,

      READY_FOR_DATA      => AUDIO_SPI_READY,
      OUTGOING_WORD_VALID => AUDIO_SPI_VALID,
      OUTGOING_WORD       => DAC_WORD,
      INCOMING_WORD       => ADC_WORD
    );

  CONTROL_STATE_MACHINE :
  process (CLOCK) is
  begin
  end process CONTROL_STATE_MACHINE;

  CONTROL_STATE_MACHINE_COMBINATIONAL :
  process (RESET, CONTROL_STATE) is
  begin
    CONTROL_SERDES_VALID <= '0';
    CONTROL_WORD         <= (others => '0');
  end process CONTROL_STATE_MACHINE_COMBINATIONAL;

  CONTROL_MODE <= '1'; -- select 3-wire/SPI mode
  CSB          <= CONTROL_SERDES_ENABLE;
  CONTROL_SERDES :
  BIDIR_SERDES
    generic map
    (
      SERIAL_WIDTH    => 16,
      PARALLEL_WIDTH  => 16,
    
      CLOCK_DIVIDER   => 2,
      CLOCK_POLARITY  => '0',
      ENABLE_POLARITY => '1',

      MASTER          => true,
      LSB_FIRST       => '0'
    )
    port map
    (
      CLOCK               => CLOCK,
      RESET               => RESET,

      SERIAL_CLOCK        => SCLK,
      SERIAL_ENABLE       => CONTROL_SERDES_ENABLE,
      SERIAL_MOSI         => SDIN,
      SERIAL_MISO         => open,

      READY_FOR_DATA      => CONTROL_SERDES_READY,
      OUTGOING_WORD_VALID => CONTROL_SERDES_VALID,
      OUTGOING_WORD       => CONTROL_WORD,
      INCOMING_WORD       => open
    );

end architecture BEHAVIORAL;
