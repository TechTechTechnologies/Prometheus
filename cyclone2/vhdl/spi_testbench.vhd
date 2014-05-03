library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;

entity SPI_TESTBENCH is
  generic
  (
    MASTER : boolean := true
  );
begin
end;

architecture SIMULATION of SPI_TESTBENCH is
  constant CLOCK_PERIOD : time := 10 ns;
  signal CLOCK : std_logic := '0';
  signal RESET : std_logic := '1';
  
  signal SERIAL_CLOCK   : std_logic := '0';
  signal SERIAL_ENABLE  : std_logic := '1';
  signal SERIAL_MOSI    : std_logic := '0';
  signal SERIAL_MISO    : std_logic := '0';

  signal BIT_COUNTER    : std_logic_vector(3 downto 0) := (others => '0');
  
  signal READY_FOR_DATA      : std_logic := '0';
  signal WORD_SENDABLE       : std_logic := '0';
  signal OUTGOING_WORD_VALID : std_logic := '0';
  signal OUTGOING_WORD       : std_logic_vector(7 downto 0) := (others => '0');
  signal INCOMING_WORD       : std_logic_vector(7 downto 0) := (others => '0');
  
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
 
      SERIAL_CLOCK        : inout std_logic := not CLOCK_POLARITY;
      SERIAL_ENABLE       : inout std_logic := not ENABLE_POLARITY;
      SERIAL_MOSI         : inout std_logic := '0';
      SERIAL_MISO         : inout std_logic;

      READY_FOR_DATA      : out std_logic;
      OUTGOING_WORD_VALID : in  std_logic;
      OUTGOING_WORD       : in  std_logic_vector(PARALLEL_WIDTH-1 downto 0);
      INCOMING_WORD       : out std_logic_vector(PARALLEL_WIDTH-1 downto 0) := (others => '0')
    );
  end component;
begin
  
  CLOCK <= not CLOCK after (CLOCK_PERIOD/2);
  RESET <= '0' after (3*CLOCK_PERIOD);
  
  STROBE_VALID :
  process (CLOCK) is
  begin
    if (rising_edge(CLOCK)) then
      if (RESET = '1') then 
        WORD_SENDABLE <= '0';
      else
        WORD_SENDABLE <= READY_FOR_DATA;
      end if;
    end if;
  end process STROBE_VALID;
  OUTGOING_WORD_VALID <= WORD_SENDABLE and READY_FOR_DATA;
  OUTGOING_WORD       <= X"DB";
  
  GENERATE_MASTER_SIGNALS :
  if (MASTER) generate
    TOGGLE_MISO :
    process (CLOCK) is
    begin
      if (rising_edge(CLOCK)) then
        if (RESET = '1') then
          SERIAL_MISO <= '0';
        else
          if (SERIAL_CLOCK = '0') then
            SERIAL_MISO <= not(SERIAL_MISO);
          else
            SERIAL_MISO <= SERIAL_MISO;
          end if;
        end if;
      end if;
    end process TOGGLE_MISO;
  end generate GENERATE_MASTER_SIGNALS;

  GENERATE_SLAVE_SIGNALS :
  if (not MASTER) generate
    ASSERT_ENABLE :
    process (CLOCK) is
    begin
      if (rising_edge(CLOCK)) then
        if (RESET = '1') then
          BIT_COUNTER   <= (others => '0');
          SERIAL_ENABLE <= '1';
          SERIAL_CLOCK  <= '0';
        else
          if (BIT_COUNTER = 9) then
            BIT_COUNTER   <= (others => '0');
            SERIAL_ENABLE <= '1';
          else
            BIT_COUNTER   <= BIT_COUNTER + 1;
            SERIAL_ENABLE <= '0';
          end if;

          if (SERIAL_ENABLE = '0') then
            SERIAL_CLOCK <= not SERIAL_CLOCK;
          end if;
        end if;
      end if;
    end process ASSERT_ENABLE;

    TOGGLE_MOSI :
    process (CLOCK) is
    begin
      if (rising_edge(CLOCK)) then
        if (RESET = '1') then
          SERIAL_MOSI <= '0';
        else
          if (SERIAL_ENABLE = '0') then
            if (SERIAL_CLOCK = '0') then
              SERIAL_MOSI <= not(SERIAL_MOSI);
            else
              SERIAL_MOSI <= SERIAL_MOSI;
            end if;
          else
            SERIAL_MOSI <= '0';
          end if;
        end if;
      end if;
    end process TOGGLE_MOSI;
  end generate GENERATE_SLAVE_SIGNALS;

  DUT :
  SPI_SERDES 
    generic map
    (
      SERIAL_WIDTH    => 8,
      PARALLEL_WIDTH  => 8,
      WORDS           => 2,
    
      CLOCK_DIVIDER   => 1,
      CLOCK_POLARITY  => '0',
      ENABLE_POLARITY => '0',

      MASTER          => MASTER,
      LSB_FIRST       => '1'
    )
    port map
    (
      CLOCK               => CLOCK,
      RESET               => RESET,
 
      SERIAL_CLOCK        => SERIAL_CLOCK,
      SERIAL_ENABLE       => SERIAL_ENABLE,
      SERIAL_MOSI         => SERIAL_MOSI,
      SERIAL_MISO         => SERIAL_MISO,

      READY_FOR_DATA      => READY_FOR_DATA,
      OUTGOING_WORD_VALID => OUTGOING_WORD_VALID,
      OUTGOING_WORD       => OUTGOING_WORD,
      INCOMING_WORD       => INCOMING_WORD
    );
  
end architecture SIMULATION;

