library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity prom1max is 

begin
end;

architecture BEHAVIORAL of prom1max is

	constant clkPeriod : time := 10ns;

	signal clk : std_logic := '0';
	signal rst : std_logic := '1';
	
	signal F_OUT : std_logic_vector (2 downto 0); --feedback out from fsr
  signal F_IN : std_logic_vector (2 downto 0);  --feedback in to fsr

  component E_FEEDBACK_SHIFT_REGISTER is
    generic
    (
      DEPTH : natural := 12;
      SEED : std_logic_vector(11 downto 0)
    );
    port
    (
      CLOCK     : in  std_logic;
      RESET     : in  std_logic;

      ENABLE    : in  std_logic;
      DIRECTION : in  std_logic;
      BITS      : out std_logic_vector(11 downto 0);
      TAPS      : in  std_logic_vector(11 downto 0);
      BIT_IN	  : in std_logic;
      BIT_OUT   : out std_logic
    );
  end component;
	
	component FEEDBACK_CONTROLLER is
  generic
  (
    DEPTH: natural := 3
  );
  port
  (
    MODE : in std_logic_vector (2 downto 0);
  
    BITS_IN : in std_logic_vector ( DEPTH-1 downto 0);
    BITS_OUT : out std_logic_vector ( DEPTH-1 downto 0)
  );
  end component;
	
begin

	clk <= not clk after (clkPeriod/2);
	rst <= '0' after (3*clkPeriod);
	
	FDBK : FEEDBACK_CONTROLLER
    port map
    (
      MODE     => B"000",
      BITS_IN  => F_OUT,
      BITS_OUT => F_IN
    );
	
	LFSR0 : E_FEEDBACK_SHIFT_REGISTER
		generic map
		(
			SEED	=> X"FFF"
		)
		port map
		(
			CLOCK	=> clk,
			RESET	=>rst,
			
			ENABLE 		=> '1',
			DIRECTION =>'1',
			--BITS      => BITS,
			TAPS      => X"0D8",
			BIT_IN    => F_IN(0),
			BIT_OUT   => F_OUT(0)
		);
	
	LFSR1 : E_FEEDBACK_SHIFT_REGISTER
		generic map
		(
			SEED	=> X"FFF"
		)
		port map
		(
			CLOCK	=> clk,
			RESET	=>rst,
			
			ENABLE 		=> '1',
			DIRECTION =>'1',
			--BITS      => BITS,
			TAPS      => X"0D8",
			BIT_IN    => F_IN(1),
			BIT_OUT   => F_OUT(1)
		);
		
	LFSR2 : E_FEEDBACK_SHIFT_REGISTER
		generic map
		(
			SEED	=> X"FFF"
		)
		port map
		(
			CLOCK	=> clk,
			RESET	=>rst,
			
			ENABLE 		=> '1',
			DIRECTION =>'1',
			--BITS      => BITS,
			TAPS      => X"0D8",
			BIT_IN    => F_IN(2),
			BIT_OUT   => F_OUT(2)
		);

end architecture BEHAVIORAL;





