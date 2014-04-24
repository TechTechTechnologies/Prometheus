entity SPI_SERDES is
  generic
  (
    SERIAL_BITS     : natural range 1 to 32 := 8;
    PARALLEL_WIDTH  : natural range 1 to 32 := BITS;
    WORDS           : natural range 1 to natural'high := 2;
    
    CLOCK_DIVISOR   : natural range 1 to natural'high := 1;
    CLOCK_POLARITY  : std_logic := '0';
    ENABLE_POLARITY : std_logic := '0'
  );
  port
  (
    CLOCK               : in std_logic;
    RESET               : in std_logic;
 
    SERIAL_CLOCK        : out std_logic := '0';
    SERIAL_ENABLE       : out std_logic := not ENABLE_POLARITY;
    SERIAL_MOSI         : out std_logic := '0';
    SERIAL_MISO         : in  std_logic;

    READY_FOR_DATA      : out std_logic;
    OUTGOING_WORD_VALID : in  std_logic;
    OUTGOING_WORD       : in  std_logic_vector(PARALLEL_WIDTH-1 downto 0);
    INCOMING_WORD_VALID : out std_logic := '0';
    INCOMING_WORD_OUT   : out std_logic_vector(PARALLEL_WIDTH-1 downto 0) := (others => '0')
  );
end entity;

architecture BEHAVIORAL of SPI_SERDES is
  type   INTERFACE_STATE_TYPE is (READY, XMIT);
  signal INTERFACE_STATE : INTERFACE_STATE_TYPE := IDLE;

  signal DIVIDE_CLOCK    : 
begin

  PARALLEL_INTERFACE : process (CLOCK) is
  begin
    if (rising_edge(CLOCK)) then
      if (RESET = '1') then
        INTERFACE_STATE     <= IDLE;

        OUTGOING_WORD_VALID <= '0';
        OUTGOING_WORD       <= (others => '0');
      else
        case (INTERFACE_STATE) is
          when IDLE   =>
          when READY  =>
          when XMIT   =>
          when others =>
        end case;
      end if;
    end if;
  end process PARALLEL_INTERFACE; 

end architecture BEHAVIORAL;
