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

  component FEEDBACK_SHIFT_REGISTER is
    generic
    (
	  DEPTH : std_logic := 12;
      SEED : std_logic_vector(11 downto 0)
    );
    port
    (
      CLOCK     : in  std_logic;
      RESET     : in  std_logic;

      ENABLE    : in  std_logic;
      DIRECTION : in  std_logic;
      BITS      : out std_logic_vector(11 downto 0);
      TAPS      : in  std_logic_vector(11 downto 0)
    );
  end component;
	
begin

	clk <= not clk after (clkPeriod/2);
	rst <= '0' after (3*clkPeriod);
	
	LFSR1 : FEEDBACK_SHIFT_REGISTER
		generic map
		(
			SEED	=> X"FF"
		)
		port map
		(
			CLOCK	=> clk,
			RESET	=>rst,
			
			ENABLE 		=> '1',
			DIRECTION 	=>'1',
			BITS 		=> BITS,
			TAPS		=> X"D8";
			BIT_IN      => BIT_OUT;
		);
	

end architecture BEHAVIORAL;





