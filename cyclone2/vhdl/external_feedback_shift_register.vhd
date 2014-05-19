library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_misc.all;

entity E_FEEDBACK_SHIFT_REGISTER is
  generic
  (
    DEPTH  : natural range 2 to natural'high := 8;
    SEED   : std_logic_vector
  );
  port
  (
    CLOCK     : in  std_logic;
    RESET     : in  std_logic;

    ENABLE    : in  std_logic;
    DIRECTION : in  std_logic;
    BITS      : out std_logic_vector(DEPTH-1 downto 0);
    TAPS      : in  std_logic_vector(DEPTH-1 downto 0);
    
    BIT_IN	  : in std_logic;
    BIT_OUT   : out std_logic;
  );
end entity FEEDBACK_SHIFT_REGISTER;

architecture BEHAVIORAL of FEEDBACK_SHIFT_REGISTER is
  signal BITS_I : std_logic_vector(BITS'range) := SEED;
  signal NEXT_BIT : std_logic := '0';
  
  component SHIFT_REGISTER is
    generic
    (
      INIT           : std_logic_vector;
      DIRECTIONALITY : integer range -1 to 1 := 0
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
  
  BIT_OUT    <= xor_reduce(BITS_I and TAPS);
  NEXT_BIT <= BIT_IN;
  BITS     <= BITS_I;
  
  SHIFTER : SHIFT_REGISTER 
    generic map
    (
      INIT           => SEED,
      DIRECTIONALITY => 0
    )
    port map
    (
      CLOCK     => CLOCK,
      RESET     => RESET,

      LOAD      => '0',
      BITS_IN   => SEED,

      STEP      => ENABLE,
      DIRECTION => DIRECTION,
      BITS_OUT  => BITS_I,
      NEXT_BIT  => NEXT_BIT
    );

end architecture BEHAVIORAL;

