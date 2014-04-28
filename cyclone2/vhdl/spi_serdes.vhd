library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;

use work.utilities.all;

entity SPI_SERDES is
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
 
    SERIAL_CLOCK        : out std_logic := not(CLOCK_POLARITY);
    SERIAL_ENABLE       : out std_logic := not(ENABLE_POLARITY);
    SERIAL_MOSI         : out std_logic := '0';
    SERIAL_MISO         : in  std_logic;

    READY_FOR_DATA      : out std_logic;
    OUTGOING_WORD_VALID : in  std_logic;
    OUTGOING_WORD       : in  std_logic_vector(PARALLEL_WIDTH-1 downto 0);
    INCOMING_WORD       : out std_logic_vector(PARALLEL_WIDTH-1 downto 0) := (others => '0')
  );
end entity;

architecture BEHAVIORAL of SPI_SERDES is
  constant OUTGOING_DIRECTIONALITY : integer := to_integer(unsigned'("" & LSB_FIRST))*2 - 1;

  type   PARALLEL_INTERFACE_STATE_TYPE is (IDLE, BUSY, FULL);
  signal PARALLEL_INTERFACE_STATE : PARALLEL_INTERFACE_STATE_TYPE := IDLE;

  type   SERIAL_INTERFACE_STATE_TYPE is (IDLE, CLK_LO, CLK_HI);
  signal SERIAL_INTERFACE_STATE : SERIAL_INTERFACE_STATE_TYPE := IDLE;

  signal READY_FOR_DATA_I      : std_logic := '0'; 
  signal INCOMING_WORD_VALID_I : std_logic := '0';
  signal INCOMING_WORD_I       : std_logic_vector(INCOMING_WORD'range) := (others => '0');
  
  signal LOAD_SHIFT_REGS : std_logic := '0';
  signal STEP_SHIFT_REGS : std_logic := '0'; 
  signal TX_BITS : std_logic_vector(PARALLEL_WIDTH-1 downto 0) := (others => '0');
  signal RX_BITS : std_logic_vector(PARALLEL_WIDTH-1 downto 0) := (others => '0');
  
  signal CLOCK_COUNTER : std_logic_vector(vector_length(CLOCK_DIVIDER)-1  downto 0) := (others => '0');
  signal BIT_COUNTER   : std_logic_vector(vector_length(PARALLEL_WIDTH)-1 downto 0) := (others => '0');
  
  signal WORD_PENDING   : std_logic := '0';
  signal WORD_REGISTER  : std_logic_vector(PARALLEL_WIDTH-1 downto 0) := (others => '0');
  signal SERIAL_BUSY    : std_logic := '0';
  
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

  READY_FOR_DATA      <= READY_FOR_DATA_I;
  INCOMING_WORD       <= INCOMING_WORD_I;
  
  PARALLEL_INTERFACE : 
  process (CLOCK) is
  begin
    if (rising_edge(CLOCK)) then
      if (RESET = '1') then
        PARALLEL_INTERFACE_STATE <= IDLE;
      else
        case (PARALLEL_INTERFACE_STATE) is
          when IDLE  =>
            if (OUTGOING_WORD_VALID = '1') then
              PARALLEL_INTERFACE_STATE <= BUSY;
              WORD_REGISTER            <= OUTGOING_WORD;
            else
              PARALLEL_INTERFACE_STATE <= IDLE;
            end if;

          when BUSY  =>
            if (SERIAL_BUSY = '1') then
              if (OUTGOING_WORD_VALID =  '1') then
                PARALLEL_INTERFACE_STATE <= FULL;
                WORD_REGISTER            <= OUTGOING_WORD;
              else 
                PARALLEL_INTERFACE_STATE <= BUSY;
              end if;
            else
              PARALLEL_INTERFACE_STATE <= IDLE;
              if (OUTGOING_WORD_VALID =  '1') then
                WORD_REGISTER <= OUTGOING_WORD;
              end if;
            end if;

          when FULL  =>
            if (SERIAL_BUSY = '0') then
              PARALLEL_INTERFACE_STATE <= IDLE;
            else
              PARALLEL_INTERFACE_STATE <= FULL;
            end if;

        end case;
      end if;
    end if;
  end process PARALLEL_INTERFACE; 
  
  PARALLEL_INTERFACE_COMBINATIONAL :
  process (RESET, PARALLEL_INTERFACE_STATE) is
  begin
    if (RESET = '1') then
      READY_FOR_DATA_I <= '0';
      WORD_PENDING     <= '0';
	 else
	   case (PARALLEL_INTERFACE_STATE) is
		  when IDLE =>
	       READY_FOR_DATA_I <= '1';
			 WORD_PENDING     <= '0';
		  when BUSY =>
	       READY_FOR_DATA_I <= '1';
			 WORD_PENDING     <= '1';
		  when FULL =>
	       READY_FOR_DATA_I <= '0';
			 WORD_PENDING     <= '1';
		end case;
	 end if;
  end process PARALLEL_INTERFACE_COMBINATIONAL;
  
  GENERATE_SPI_MASTER :
  if (MASTER) generate
    SERIAL_INTERFACE : 
    process (CLOCK) is
    begin
      if (rising_edge(CLOCK)) then
        if (RESET = '1') then
          SERIAL_INTERFACE_STATE <= IDLE;
          
          CLOCK_COUNTER <= (others => '0');
          BIT_COUNTER   <= (others => '0');

          INCOMING_WORD_I <= (others => '0');
        else
          case (SERIAL_INTERFACE_STATE) is
            when IDLE =>
              if (WORD_PENDING = '1') then
                SERIAL_INTERFACE_STATE <= CLK_LO;
                LOAD_SHIFT_REGS        <= '1';
              else
                SERIAL_INTERFACE_STATE <= IDLE;
                LOAD_SHIFT_REGS        <= '0';
              end if;
            when CLK_LO =>
              if (CLOCK_COUNTER = CLOCK_DIVIDER-1) then
                SERIAL_INTERFACE_STATE <= CLK_HI;
                CLOCK_COUNTER          <= (others => '0');
              else
                SERIAL_INTERFACE_STATE <= CLK_LO;
                CLOCK_COUNTER          <= CLOCK_COUNTER + 1;
              end if;
              LOAD_SHIFT_REGS <= '0';
            when CLK_HI =>
              if (CLOCK_COUNTER = CLOCK_DIVIDER-1) then
                if (BIT_COUNTER = PARALLEL_WIDTH-1) then
                  SERIAL_INTERFACE_STATE <= IDLE;
                  BIT_COUNTER <= (others => '0');

                  INCOMING_WORD_I <= RX_BITS;
                else
                  SERIAL_INTERFACE_STATE <= CLK_LO;
                  BIT_COUNTER <= BIT_COUNTER + 1;
                end if;
                CLOCK_COUNTER          <= (others => '0');
              else
                SERIAL_INTERFACE_STATE <= CLK_HI;
                CLOCK_COUNTER          <= CLOCK_COUNTER + 1;
              end if;
              LOAD_SHIFT_REGS <= '0';
          end case;
        end if;
      end if;
    end process SERIAL_INTERFACE;

    SERIAL_ENABLE <=      ENABLE_POLARITY 
                     when (SERIAL_BUSY = '1') 
                     else not(ENABLE_POLARITY);
    SERIAL_INTERFACE_COMBINATIONAL : 
    process (RESET, SERIAL_INTERFACE_STATE) is
    begin
      if (RESET = '1') then
        SERIAL_CLOCK    <= not(CLOCK_POLARITY);
        SERIAL_BUSY     <= '0';
        STEP_SHIFT_REGS <= '0';
      else
        case (SERIAL_INTERFACE_STATE) is
          when IDLE   =>
            SERIAL_CLOCK    <= not(CLOCK_POLARITY);
            SERIAL_BUSY     <= '0';
            STEP_SHIFT_REGS <= '0';
          when CLK_LO =>
            SERIAL_CLOCK    <= not(CLOCK_POLARITY);
            SERIAL_BUSY     <= '1';
            STEP_SHIFT_REGS <= '1';
          when CLK_HI =>
            SERIAL_CLOCK    <= CLOCK_POLARITY;
            SERIAL_BUSY     <= '1';
            STEP_SHIFT_REGS <= '0';
        end case;
      end if;
    end process SERIAL_INTERFACE_COMBINATIONAL;

    GENERATE_LSB_FIRST :
    if (LSB_FIRST = '1') generate
      SERIAL_MOSI <= TX_BITS(TX_BITS'right);
    end generate GENERATE_LSB_FIRST;

    GENERATE_MSB_FIRST :
    if (LSB_FIRST = '0') generate
      SERIAL_MOSI <= TX_BITS(TX_BITS'left);
    end generate GENERATE_MSB_FIRST;
  end generate GENERATE_SPI_MASTER;

  OUTGOING_SHIFT_REGISTER : 
  SHIFT_REGISTER
    generic map
    (
      INIT           => (OUTGOING_WORD'range => '0'),
      DIRECTIONALITY => OUTGOING_DIRECTIONALITY
    )
    port map
    (   
      CLOCK     => CLOCK,
      RESET     => RESET,

      LOAD      => LOAD_SHIFT_REGS,
      BITS_IN   => WORD_REGISTER,

      STEP      => STEP_SHIFT_REGS,
      DIRECTION => '0',
      BITS_OUT  => TX_BITS,
      NEXT_BIT  => '0'
    );

  INCOMING_SHIFT_REGISTER : 
  SHIFT_REGISTER
    generic map
    (
      INIT           => (INCOMING_WORD'range => '0'),
      DIRECTIONALITY => -OUTGOING_DIRECTIONALITY
    )
    port map
    (
      CLOCK     => CLOCK,
      RESET     => RESET,

      LOAD      => '0',
      BITS_IN   => (others => '0'),

      STEP      => STEP_SHIFT_REGS,
      DIRECTION => '0',
      BITS_OUT  => RX_BITS,
      NEXT_BIT  => SERIAL_MISO
    );

end architecture BEHAVIORAL;

