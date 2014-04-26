entity SPI_SERDES is
  generic
  (
    SERIAL_BITS     : natural range 1 to 32 := 8;
    PARALLEL_WIDTH  : natural range 1 to 32 := BITS;
    WORDS           : natural range 1 to natural'high := 2;
    
    CLOCK_DIVISOR   : natural range 1 to natural'high := 1;
    CLOCK_POLARITY  : std_logic := '0';
    ENABLE_POLARITY : std_logic := '0';
    MSB_FIRST       : std_logic := '1'
  );
  port
  (
    CLOCK               : in std_logic;
    RESET               : in std_logic;
 
    SERIAL_CLOCK        : out std_logic := not CLOCK_POLARITY;
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
  type   PARALLEL_INTERFACE_STATE_TYPE is (READY, XMIT);
  signal PARALLEL_INTERFACE_STATE : INTERFACE_STATE_TYPE := READY;

  type   SERIAL_INTERFACE_STATE_TYPE is (IDLE, CLK_LO, CLK_HI);
  signal SERIAL_INTERFACE_STATE : SERIAL_INTERFACE_STATE_TYPE := IDLE;

begin

--  PARALLEL_INTERFACE : process (CLOCK) is
--  begin
--    if (rising_edge(CLOCK)) then
--      if (RESET = '1') then
--        INTERFACE_STATE     <= IDLE;
--
--      OUTGOING_WORD_VALID <= '0';
--        OUTGOING_WORD       <= (others => '0');
--      else
--        case (INTERFACE_STATE) is
--          when IDLE   =>
--          when READY  =>
--          when XMIT   =>
--          when others =>
--        end case;
--      end if;
--    end if;
--  end process PARALLEL_INTERFACE; 

  SERIAL_INTERFACE : process (CLOCK) is
  begin
    if (rising_edge(CLOCK)) then
      if (RESET = '1') then
        SERIAL_INTERFACE_STATE <= IDLE;
        
        SERIAL_CLOCK <= not CLOCK_POLARITY;
        SERIAL_MOSI  <= '0';

        TX_SHIFT_REG  <= (others => '0');
        RX_SHIFT_REG  <= (others => '0');
                
        CLOCK_COUNTER <= (others => '0');
        BIT_COUNTER   <= (others => '0');
      else
        case (SERIAL_INTERFACE_STATE) is
          when IDLE =>
            if (TRANSMISSION_ACTIVE = '1') then
              SERIAL_INTERFACE_STATE <= CLK_LO;
              TX_SHIFT_REG           <= OUTGOING_WORD;
            else
              SERIAL_INTERFACE_STATE <= IDLE;
            end if;
          when CLK_LO =>
            if (MSB_FIRST = '1') then generate
              TX_SHIFT_REG
          when CLK_HI =>
        end case;
      end if;
    end if;
  end process SERIAL_INTERFACE;

end architecture BEHAVIORAL;
