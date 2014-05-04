library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;

entity WM871_TESTBENCH is
begin
end;

architecture SIMULATION of WM871_TESTBENCH is
  constant CLOCK_PERIOD : time := 10 ns;
  signal CLOCK : std_logic := '0';
  signal RESET : std_logic := '1';

  signal SPI_CLOCK : std_logic;
  signal SPI_MISO  : std_logic;
  signal SPI_MOSI  : std_logic;
  signal LEFT_ADC  : std_logic_vector(15 downto 0);
  signal RIGHT_ADC : std_logic_vector(15 downto 0);

  component WM8731_CODEC is
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
  end component;
begin
  
  CLOCK <= not CLOCK after (CLOCK_PERIOD/2);
  RESET <= '0' after (3*CLOCK_PERIOD);
  

  DUT :
  WM8731_CODEC
    generic map
    ( 
      BITDEPTH => 16
    )
    port map
    (
      CLOCK => CLOCK,
      RESET => RESET,

      WR_RATE => '0',
      RATE    => (others => '0'),
      WR_GAIN => '0',
      GAIN    => (others => '0'),

      WR_DATA   => '0',
      LEFT_DAC  => (others => '0'),
      RIGHT_DAC => (others => '0'),
      LEFT_ADC  => LEFT_ADC,
      RIGHT_ADC => RIGHT_ADC,

      -- physical interface signals
      BCLK   => SPI_CLOCK,
      ADCLRC => open,
      DACLRC => open,
      ADCDAT => SPI_MISO,
      DACDAT => SPI_MOSI
    );
  
end architecture SIMULATION;
