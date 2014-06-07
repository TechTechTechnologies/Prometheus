library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_misc.all;
use IEEE.std_logic_unsigned.all;
use work.key_config.all;

entity PS2_KEYBOARD is
  generic
  (
    --                      Z      X      C      A      S      D      Q      W      E      1      2      3        
    taps_k0 : tap_keys := (X"1A", X"22", X"21", X"1C", X"1B", X"23", X"15", X"1d", X"24", X"16", X"1E", X"26");
    --                      V      B      N      F      G      H      R      T      Y      4      5      6       
    taps_k1 : tap_keys := (X"2A", X"32", X"31", X"2B", X"34", X"33", X"2D", X"2C", X"35", X"25", X"2E", X"36");
    --                      M      ,      .      J      K      L      U      I      O      7      8      9
    taps_k2 : tap_keys := (X"3A", X"41", X"49", X"3B", X"42", X"4B", X"3C", X"43", X"44", X"3D", X"3E", X"46")
  );
  port
  (
    PS2_DATA  : inout std_logic;
    PS2_CLOCK : inout std_logic;
    
    KEYOUT : out std_logic_vector (7 downto 0);
    
    TAPS0     : out std_logic_vector (11 downto 0);
    TAPS1     : out std_logic_vector (11 downto 0);
    TAPS2     : out std_logic_vector (11 downto 0)
  );
end entity PS2_KEYBOARD;

architecture BEHAVIORAL of PS2_KEYBOARD is
  signal COUNTER  : std_logic_vector (3 downto 0) := X"0";
  
  signal DATA     : std_logic_vector (10 downto 0); --8 downto 1
  
  signal KEY      : std_logic_vector (7 downto 0);
  signal PARITY   : std_logic;
  
  signal KTYPE    : std_logic;  
  signal EXT      : std_logic;
begin

  KEY <= DATA(9 downto 2);
  PARITY <= DATA(1);
  
  process(PS2_CLOCK)is
  begin
    if(rising_edge(PS2_CLOCK)) then
      PS2_DATA <= 'Z';
      DATA <= PS2_DATA & DATA(10 downto 1);
      
      if(COUNTER = X"A") then
        COUNTER <= X"0";
        
        --KEYOUT <= KEY;
        if(not xor_reduce(KEY) = PARITY) then
          KEYOUT <= X"FF";
        else
          KEYOUT <= X"00";
        end if;
          
        
        if (KEY = X"F0") then
          KTYPE <= '1';
        elsif (KEY = X"E0") then
          EXT <= '1';
        else
          for I in 0 to 11 loop
            if(KEY = taps_k0(I)) then
              TAPS0(I) <= not KTYPE;
            end if;
            if(KEY = taps_k1(I)) then
              TAPS1(I) <= not KTYPE;
            end if;
            if(KEY = taps_k2(I)) then
              TAPS2(I) <= not KTYPE;
            end if;
          end loop;
          KTYPE <= '0';
          EXT <= '0';
        end if;
        
      else
        COUNTER <= COUNTER + X"1";
      end if;
    
    end if;
  
  end process;
  
  

end architecture BEHAVIORAL;