library IEEE;
use IEEE.std_logic_1164.all;

package wm8731_defs is
  type WM8731_REGISTER is
    ( LEFT_LINE_IN
    , RIGHT_LINE_IN
    , LEFT_HEADPHONE_OUT
    , RIGHT_HEADPHONE_OUT
    , ANA_PATH_CONTROL
    , DIG_PATH_CONTROL
    , POWER_CONTROL
    , DIG_FORMAT
    , SAMPLING_CONTROL
    , ACTIVE_CONTROL
    , RESET
    );
  type WM8731_REGISTER_ENCODING is array(WM8731_REGISTER) of std_logic_vector(6 downto 0);
  constant ENCODE_WM8731_REGISTER : WM8731_REGISTER_ENCODING;
end package wm8731_defs;

package body wm8731_defs is
  constant ENCODE_WM8731_REGISTER : WM8731_REGISTER_ENCODING := 
    ( LEFT_LINE_IN        => "0000000"
    , RIGHT_LINE_IN       => "0000001"
    , LEFT_HEADPHONE_OUT  => "0000010"
    , RIGHT_HEADPHONE_OUT => "0000011"
    , ANA_PATH_CONTROL    => "0000100"
    , DIG_PATH_CONTROL    => "0000101"
    , POWER_CONTROL       => "0000110"
    , DIG_FORMAT          => "0000111"
    , SAMPLING_CONTROL    => "0001000"
    , ACTIVE_CONTROL      => "0001001"
    , RESET               => "0001111"
    );
end package body;
