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
    
    KEYOUT : out std_logic_vector (15 downto 0);
    
    TAPS0     : out std_logic_vector (11 downto 0);
    TAPS1     : out std_logic_vector (11 downto 0);
    TAPS2     : out std_logic_vector (11 downto 0)
  );
end entity PS2_KEYBOARD;

architecture BEHAVIORAL of PS2_KEYBOARD is
  signal COUNTER  : std_logic_vector (4 downto 0) := "00000";
  
  signal DATA     : std_logic_vector (21 downto 0); --19 downto 12 and 8 downto 1
  
  signal KTYPE    : std_logic;  
begin


  process(PS2_CLOCK)is
  begin
    if(falling_edge(PS2_CLOCK)) then
      PS2_DATA <= 'Z';
      DATA <= PS2_DATA & DATA(21 downto 1);
      
      if(DATA(19 downto 12) = X"F0") then
        KTYPE <= '0';
      else
        KTYPE <= '1';
      end if;

      if(COUNTER = "10101") then
        COUNTER <= "00000";
        
        KEYOUT <= DATA(19 downto 12) & DATA(8 downto 1);
        
        for I in 0 to 11 loop
          if(DATA(8 downto 1) = taps_k0(I)) then
            TAPS0(I) <= KTYPE;
          end if;
          if(DATA(8 downto 1) = taps_k1(I)) then
            TAPS1(I) <= KTYPE;
          end if;
          if(DATA(8 downto 1) = taps_k2(I)) then
            TAPS2(I) <= KTYPE;
          end if;
        end loop;
        
      else
        COUNTER <= COUNTER + "00001";
      end if;
    
    end if;
  
  end process;
  
  

end architecture BEHAVIORAL;