library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;

entity SEQUENCE_RECORDER is
  port
  (
    CONTROL : in std_logic;  --toggles start/stop recording

    MODE    : in std_logic_vector (1 downto 0);  -- Configuration data
    CLKDIV0 : in std_logic_vector (15 downto 0);
    CLKDIV1 : in std_logic_vector (15 downto 0);
    CLKDIV2 : in std_logic_vector (15 downto 0);
    CLKOFF0 : in std_logic_vector (15 downto 0);
    CLKOFF1 : in std_logic_vector (15 downto 0);
    CLKOFF2 : in std_logic_vector (15 downto 0);

    SEQ_ID  : in std_logic_vector (7 downto 0); --The name of the sequence
    
    TAPS0 : in std_logic_vector (11 downto 0);
    TAPS1 : in std_logic_vector (11 downto 0);
    TAPS2 : in std_logic_vector (11 downto 0);
    
    CLK0  : in std_logic;
    CLK1  : in std_logic;
    CLK2  : in std_logic;
    
    BYTE_SEL : in std_logic_vector (7 downto 0);  --Data output to memory
    DATA_OUT : out std_logic_vector (7 downto 0);
    
    DATA_READY : out std_logic; --Signals that a page is waiting to be written
    MEM_READY : in std_logic; --Signal from the memory controller that tells whether it's busy writing
    
    STATUS   : out std_logic_vector (3 downto 0) --For status info elise initing and stuff
  );
end entity SEQUENCE_RECORDER;

