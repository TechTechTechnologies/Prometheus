library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity LFSR_TESTBENCH is
begin
end;

architecture BEHAVIORAL of LFSR_TESTBENCH is
  constant CLOCK_PERIOD : time := 10 ns;
  signal CLOCK : std_logic := '0';
  signal RESET : std_logic := '1';
  
  signal BITS  : std_logic_vector(7 downto 0);

  component FEEDBACK_SHIFT_REGISTER is
    generic
    (
      SEED : std_logic_vector(7 downto 0)
    );
    port
    (
      CLOCK     : in  std_logic;
      RESET     : in  std_logic;

      ENABLE    : in  std_logic;
      DIRECTION : in  std_logic;
      BITS      : out std_logic_vector(7 downto 0);
      TAPS      : in  std_logic_vector(7 downto 0)
    );
  end component;
begin
  
  CLOCK <= not CLOCK after (CLOCK_PERIOD/2);
  RESET <= '0' after (3*CLOCK_PERIOD);
  
  LFSR : FEEDBACK_SHIFT_REGISTER 
    generic map
    (
      SEED      => X"FF"
    )
    port map
    (
      CLOCK     => CLOCK,
      RESET     => RESET,

      ENABLE    => '1',
      DIRECTION => '1',
      BITS      => BITS,
      TAPS      => X"D8"
    );
end architecture BEHAVIORAL;
