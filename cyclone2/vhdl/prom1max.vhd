library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;

use work.key_config.all;

entity prom1max is 
  port
  (
    CLOCK : in std_logic;
    FSR_OUT : out std_logic_vector (2 downto 0);
    
    RST_OUT : out std_logic;
	 
    BUTTON : in std_logic_vector (3 downto 0);
    LED : out std_logic_vector (7 downto 0);
   
	 PS2_CLK  : in std_logic;
	 PS2_DATA : inout std_logic
	 --D18 data
  );
begin
end;

architecture BEHAVIORAL of prom1max is

  signal RESET : std_logic;
	signal rst : std_logic := '0';
	
	signal CLK0 : std_logic;
	signal CLK1 : std_logic;
	signal CLK2 : std_logic;
	
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

  component CLOCK_CONTROLLER is
    port
    (
      CLOCK : in std_logic;
      RESET : in std_logic;
      SET   : in std_logic;
      
      REG_SELECT : in std_logic_vector (2 downto 0);
      DATA       : in std_logic_vector (15 downto 0);
      
      OUT0 : out std_logic;
      OUT1 : out std_logic;
      OUT2 : out std_logic
    );
  end component;
    
  component BOOT_CONTROLLER is
    generic
    (
      CLKDIV0 : std_logic_vector (15 downto 0) := X"0BAA"; --5972/2
      CLKDIV1 : std_logic_vector (15 downto 0) := X"1754";  --5972 C's
      CLKDIV2 : std_logic_vector (15 downto 0) := X"2EA9"; --11945
      CLKOFF0 : std_logic_vector (15 downto 0) := X"0000";
      CLKOFF1 : std_logic_vector (15 downto 0) := X"0008";
      CLKOFF2 : std_logic_vector (15 downto 0) := X"0010"
    );
    port
    (
      CLOCK : in std_logic;
      RESET : in std_logic;
      
      CCTRL_RESET  : out std_logic;
      CCTRL_SET    : out std_logic;
      CCTRL_SELECT : out std_logic_vector (2 downto 0);
      CCTRL_DATA   : out std_logic_vector (15 downto 0);

      L0_RESET     : out std_logic;
      L1_RESET     : out std_logic;
      L2_RESET     : out std_logic
    );
  end component;

  component PS2_KEYBOARD is
    generic
    (
      WAIT_TIME : natural range 1 to natural'high := 4;
      BUFFER_LENGTH   : natural range 11 to natural'high := 33;   
      
      --                      Z      X      C      A      S      D      Q      W      E      1      2      3        
      taps_k2 : tap_keys := (X"1A", X"22", X"21", X"1C", X"1B", X"23", X"15", X"1d", X"24", X"16", X"1E", X"26");
      --                      V      B      N      F      G      H      R      T      Y      4      5      6       
      taps_k1 : tap_keys := (X"2A", X"32", X"31", X"2B", X"34", X"33", X"2D", X"2C", X"35", X"25", X"2E", X"36");
      --                      M      ,      .      J      K      L      U      I      O      7      8      9
      taps_k0 : tap_keys := (X"3A", X"41", X"49", X"3B", X"42", X"4B", X"3C", X"43", X"44", X"3D", X"3E", X"46")
    );
    port
    (
      CLOCK     : in std_logic;
      RESET     : in std_logic;
      
      PS2_DATA  : inout std_logic;
      PS2_CLOCK : in std_logic;

      KEYOUT : out std_logic_vector (23 downto 0);
      BUFFER_OUT : out std_logic_vector (BUFFER_LENGTH-1 downto 0);
      
      STATUS     : out std_logic_vector(4 downto 0);
      
      TAPS0     : out std_logic_vector (11 downto 0);
      TAPS1     : out std_logic_vector (11 downto 0);
      TAPS2     : out std_logic_vector (11 downto 0)
    );
  end component;
  
  signal CCTRL_RESET  : std_logic;
  signal CCTRL_SET    : std_logic;
  signal CCTRL_SELECT : std_logic_vector (2 downto 0);
  signal CCTRL_DATA   : std_logic_vector (15 downto 0);

  signal L0_RESET     : std_logic;
  signal L1_RESET     : std_logic;
  signal L2_RESET     : std_logic;
    
  signal TAPS0 : std_logic_vector(11 downto 0);
  signal TAPS1 : std_logic_vector(11 downto 0);
  signal TAPS2 : std_logic_vector(11 downto 0);
  
  signal KEYOUT : std_logic_vector(23 downto 0);
  signal BUFFER_OUT : std_logic_vector (32 downto 0);
  
  signal LED_BUFFER : std_logic_vector (7 downto 0);
  signal LFSR_STATUS : std_logic_vector (7 downto 0) := X"00";
  signal PS2_STATUS  : std_logic_vector (4 downto 0);
begin

--  RESET <= not RESET_IN;

  RESET <= '0' when (BUTTON(0) = '1') else '1';

  FSR_OUT <= F_OUT;
	
	RST_OUT <= L0_RESET;
	
  LFSR_STATUS(0) <= '0' when (TAPS0 = X"000") else '1';
  LFSR_STATUS(1) <= '0' when (TAPS1 = X"000") else '1';
  LFSR_STATUS(2) <= '0' when (TAPS2 = X"000") else '1';
  LFSR_STATUS(7 downto 3) <= PS2_STATUS;
  
  --LED <= KEYOUT (7 downto 0) when (BUTTON = not X"0") else KEYOUT (15 downto 8) when (BUTTON = not X"1") else KEYOUT(23 downto 16) when (BUTTON = not X"2") else X"FF";
  -- 30 downto 23, 19 downto 12, 8 downto 1
  LED_BUFFER <= BUFFER_OUT (30 downto 23) when (BUTTON(3 downto 1) = B"110") else
                BUFFER_OUT (19 downto 12) when (BUTTON(3 downto 1) = B"101") else
                BUFFER_OUT (8 downto 1)   when (BUTTON(3 downto 1) = B"011") else
                LFSR_STATUS               when (BUTTON(3 downto 1) = B"111") else
                X"00";
  
  LED <= not LED_BUFFER;
  
  --LED(2 downto 0) <= F_OUT(2 downto 0);
  --LED(7 downto 3) <= KEYOUT(7 downto 3);
  
  KEYBOARD : PS2_KEYBOARD 
    port map
    (
      CLOCK => CLOCK,
      --RESET => not BUTTON(0),
      RESET => RESET,
      KEYOUT => KEYOUT,
      BUFFER_OUT => BUFFER_OUT,
      STATUS => PS2_STATUS,
      PS2_DATA => PS2_DATA,
      PS2_CLOCK => PS2_CLK,
      TAPS0 => TAPS0,
      TAPS1 => TAPS1,
      TAPS2 => TAPS2
    );
  
	BOOT : BOOT_CONTROLLER
    port map
    (
      CLOCK => CLOCK,
      RESET =>RESET,
    
      CCTRL_RESET => CCTRL_RESET,
      CCTRL_SET => CCTRL_SET,
      CCTRL_SELECT => CCTRL_SELECT,
      CCTRL_DATA => CCTRL_DATA,

      L0_RESET => L0_RESET,
      L1_RESET => L1_RESET,
      L2_RESET => L2_RESET
    );
	
	FDBK : FEEDBACK_CONTROLLER
    port map
    (
      MODE     => B"000",
      BITS_IN  => F_OUT,
      BITS_OUT => F_IN
    );

  CLOCK_CTRL : CLOCK_CONTROLLER
    port map
    (
      CLOCK => CLOCK,
      SET => CCTRL_SET,
      RESET => CCTRL_RESET,
      
      REG_SELECT => CCTRL_SELECT,
      DATA => CCTRL_DATA,
      
      OUT0 => CLK0,
      OUT1 => CLK1,
      OUT2 => CLK2
    );
	
	LFSR0 : E_FEEDBACK_SHIFT_REGISTER
		generic map
		(
			SEED	=> X"000"
		)
		port map
		(
			CLOCK	=> CLK0,
			RESET	=>L0_RESET,
			
			ENABLE 		=> '1',
			DIRECTION =>'1',
--			TAPS      => X"080",
			TAPS      => TAPS0,
			BIT_IN    => F_IN(0),
			BIT_OUT   => F_OUT(0)
		);
	
	LFSR1 : E_FEEDBACK_SHIFT_REGISTER
		generic map
		(
			SEED	=> X"000"
		)
		port map
		(
			CLOCK	=> CLK1,
			RESET	=>L1_RESET,
			
			ENABLE 		=> '1',
			DIRECTION =>'1',
			TAPS      => TAPS1,
			BIT_IN    => F_IN(1),
			BIT_OUT   => F_OUT(1)
		);
		
	LFSR2 : E_FEEDBACK_SHIFT_REGISTER
		generic map
		(
			SEED	=> X"000"
		)
		port map
		(
			CLOCK	=> CLK2,
			RESET	=>L2_RESET,
			
			ENABLE 		=> '1',
			DIRECTION =>'1',
			TAPS      => TAPS2,
			BIT_IN    => F_IN(2),
			BIT_OUT   => F_OUT(2)
		);

end architecture BEHAVIORAL;





