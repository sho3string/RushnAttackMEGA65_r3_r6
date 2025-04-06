----------------------------------------------------------------------------------
-- MiSTer2MEGA65 Framework
--
-- Wrapper for the MiSTer core that runs exclusively in the core's clock domanin
--
-- MiSTer2MEGA65 done by sy2002 and MJoergen in 2022 and licensed under GPL v3
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.video_modes_pkg.all;

entity main is
   generic (
      G_VDNUM                 : natural                     -- amount of virtual drives
   );
   port (
      clk_main_i              : in  std_logic;
      reset_soft_i            : in  std_logic;
      reset_hard_i            : in  std_logic;
      pause_i                 : in  std_logic;

      -- MiSTer core main clock speed:
      -- Make sure you pass very exact numbers here, because they are used for avoiding clock drift at derived clocks
      clk_main_speed_i        : in  natural;

      -- Video output
      video_ce_o              : out std_logic;
      video_ce_ovl_o          : out std_logic;
      video_red_o             : out std_logic_vector(3 downto 0);
      video_green_o           : out std_logic_vector(3 downto 0);
      video_blue_o            : out std_logic_vector(3 downto 0);
      video_vs_o              : out std_logic;
      video_hs_o              : out std_logic;
      video_hblank_o          : out std_logic;
      video_vblank_o          : out std_logic;

      -- Audio output (Signed PCM)
      audio_left_o            : out signed(15 downto 0);
      audio_right_o           : out signed(15 downto 0);

      -- M2M Keyboard interface
      kb_key_num_i            : in  integer range 0 to 79;    -- cycles through all MEGA65 keys
      kb_key_pressed_n_i      : in  std_logic;                -- low active: debounced feedback: is kb_key_num_i pressed right now?

      -- MEGA65 joysticks and paddles/mouse/potentiometers
      joy_1_up_n_i            : in  std_logic;
      joy_1_down_n_i          : in  std_logic;
      joy_1_left_n_i          : in  std_logic;
      joy_1_right_n_i         : in  std_logic;
      joy_1_fire_n_i          : in  std_logic;

      joy_2_up_n_i            : in  std_logic;
      joy_2_down_n_i          : in  std_logic;
      joy_2_left_n_i          : in  std_logic;
      joy_2_right_n_i         : in  std_logic;
      joy_2_fire_n_i          : in  std_logic;

      pot1_x_i                : in  std_logic_vector(7 downto 0);
      pot1_y_i                : in  std_logic_vector(7 downto 0);
      pot2_x_i                : in  std_logic_vector(7 downto 0);
      pot2_y_i                : in  std_logic_vector(7 downto 0);
      
      -- Dipswitches
      dsw_a_i                 : in  std_logic_vector(7 downto 0);
      dsw_b_i                 : in  std_logic_vector(7 downto 0);
      dsw_c_i                 : in  std_logic_vector(7 downto 0);

      dn_clk_i                : in  std_logic;
      dn_addr_i               : in  std_logic_vector(17 downto 0);
      dn_data_i               : in  std_logic_vector(7 downto 0);
      dn_wr_i                 : in  std_logic;

      osm_control_i           : in  std_logic_vector(255 downto 0)
   );
end entity main;

architecture synthesis of main is

-- @TODO: Remove these demo core signals
signal keyboard_n   : std_logic_vector(79 downto 0);
signal pause_cpu    : std_logic;
signal audio        : std_logic_vector(7 downto 0);

signal reset             : std_logic := reset_hard_i or reset_soft_i;

-- highscore system
signal hs_address       : std_logic_vector(15 downto 0);
signal hs_data_in       : std_logic_vector(7 downto 0);
signal hs_data_out      : std_logic_vector(7 downto 0);
signal hs_write_enable  : std_logic;
signal hs_access_read   : std_logic;
signal hs_access_write  : std_logic;

signal hs_pause         : std_logic;
signal options          : std_logic_vector(1 downto 0);

-- Game player inputs
constant m65_1             : integer := 56; --Player 1 Start
constant m65_2             : integer := 59; --Player 2 Start
constant m65_5             : integer := 16; --Insert coin 1
constant m65_6             : integer := 19; --Insert coin 2

-- Offer some keyboard controls in addition to Joy 1 Controls
constant m65_up_crsr       : integer := 73; --Player up
constant m65_vert_crsr     : integer := 7;  --Player down
constant m65_left_crsr     : integer := 74; --Player left
constant m65_horz_crsr     : integer := 2;  --Player right
constant m65_mega          : integer := 61; --Trigger 1
constant m65_space         : integer := 60; --Trigger 2
constant m65_p             : integer := 41; --Pause button
constant m65_s             : integer := 13; --Service 1
constant m65_d             : integer := 18; --Service Mode

-- Menu controls
constant C_MENU_OSMPAUSE   : natural := 2;
constant C_MENU_KONAMI_H1  : integer := 31;
constant C_MENU_KONAMI_H2  : integer := 32;
constant C_MENU_KONAMI_H4  : integer := 33;
constant C_MENU_KONAMI_H8  : integer := 34;
constant C_MENU_KONAMI_H16 : integer := 35;

constant C_MENU_KONAMI_V2  : integer := 41;
constant C_MENU_KONAMI_V4  : integer := 42;
constant C_MENU_KONAMI_V8  : integer := 43;
constant C_MENU_KONAMI_V16 : integer := 44;

signal PCLK_EN             : std_logic;
signal HPOS,VPOS           : std_logic_vector(8 downto 0);
signal POUT                : std_logic_vector(11 downto 0);
signal oRGB                : std_logic_vector(11 downto 0);
signal HOFFS               : std_logic_vector(4 downto 0);
signal VOFFS               : std_logic_vector(3 downto 0);

signal dual_controls       : std_logic;

signal m_up1               : std_logic;
signal m_down1             : std_logic;
signal m_left1             : std_logic;
signal m_right1            : std_logic;
signal m_trig11            : std_logic;
signal m_trig12            : std_logic;

signal m_up2               : std_logic;
signal m_down2             : std_logic;
signal m_left2             : std_logic;
signal m_right2            : std_logic;
signal m_trig21            : std_logic;
signal m_trig22            : std_logic;

begin
    
    process (clk_main_i)
    begin
        if rising_edge(clk_main_i) then
            if not reset then -- workaround ( prevents core from freezing ).Wait for core to reset before connecting inputs.
                dual_controls <= dsw_c_i(1);
                m_up1       <= keyboard_n(m65_up_crsr) and joy_1_up_n_i and joy_2_up_n_i when dual_controls = '1' else joy_1_up_n_i and keyboard_n(m65_up_crsr);
                m_down1     <= keyboard_n(m65_vert_crsr) and joy_1_down_n_i and joy_2_down_n_i when dual_controls = '1' else joy_1_down_n_i and keyboard_n(m65_vert_crsr);
                m_left1     <= keyboard_n(m65_left_crsr) and joy_1_left_n_i and joy_2_left_n_i when dual_controls = '1' else joy_1_left_n_i and keyboard_n(m65_left_crsr);
                m_right1    <= keyboard_n(m65_horz_crsr) and joy_1_right_n_i and joy_2_right_n_i when dual_controls = '1' else joy_1_right_n_i and keyboard_n(m65_horz_crsr);
                m_trig11    <= keyboard_n(m65_mega) and joy_1_fire_n_i and joy_2_fire_n_i when dual_controls = '1' else joy_1_fire_n_i and keyboard_n(m65_mega);
                
                m_up2       <= keyboard_n(m65_up_crsr) and joy_1_up_n_i and joy_2_up_n_i when dual_controls = '1' else joy_2_up_n_i and keyboard_n(m65_up_crsr);
                m_down2     <= keyboard_n(m65_vert_crsr) and joy_1_down_n_i and joy_2_down_n_i when dual_controls = '1' else joy_2_down_n_i and keyboard_n(m65_vert_crsr);
                m_left2     <= keyboard_n(m65_left_crsr) and joy_1_left_n_i and joy_2_left_n_i when dual_controls = '1' else joy_2_left_n_i and keyboard_n(m65_left_crsr);
                m_right2    <= keyboard_n(m65_horz_crsr) and joy_1_right_n_i and joy_2_right_n_i when dual_controls = '1' else joy_2_right_n_i and keyboard_n(m65_horz_crsr);
                m_trig21    <= keyboard_n(m65_mega) and joy_1_fire_n_i and joy_2_fire_n_i when dual_controls = '1' else joy_2_fire_n_i and keyboard_n(m65_mega);
            end if;
        end if;
    end process;
    
    --audio left
    audio_left_o(15) <= not audio(7);
    audio_left_o(14 downto 8) <= signed(audio(6 downto 0));
    audio_left_o(7) <= audio(7);
    audio_left_o(6 downto 0) <= signed(audio(6 downto 0));
    --audio right
    audio_right_o(15) <= not audio(7);
    audio_right_o(14 downto 8) <= signed(audio(6 downto 0));
    audio_right_o(7) <= audio(7);
    audio_right_o(6 downto 0) <= signed(audio(6 downto 0));
    options(0)  <= osm_control_i(C_MENU_OSMPAUSE);

    -- video
    PCLK_EN     <=  video_ce_o;
    oRGB        <=  video_blue_o & video_green_o & video_red_o;

    -- video crt offsets
    HOFFS <=   osm_control_i(C_MENU_KONAMI_H16)  &
               osm_control_i(C_MENU_KONAMI_H8)   &
               osm_control_i(C_MENU_KONAMI_H4)   &
               osm_control_i(C_MENU_KONAMI_H2)   &
               osm_control_i(C_MENU_KONAMI_H1);
               
    VOFFS <=   osm_control_i(C_MENU_KONAMI_V16)  &
               osm_control_i(C_MENU_KONAMI_V8)   &
               osm_control_i(C_MENU_KONAMI_V4)   &
               osm_control_i(C_MENU_KONAMI_V2);
               
    i_pause : entity work.pause
    generic map (
     
        RW  => 4,
        GW  => 4,
        BW  => 4,
        CLKSPD => 48
        
     )         
     port map (
     clk_sys        => clk_main_i,
     reset          => reset,
     user_button    => keyboard_n(m65_p),
     pause_request  => hs_pause,
     options        => options,  -- not status(11 downto 10), - TODO, hookup to OSD.
     OSD_STATUS     => '0',       -- disabled for now - TODO, to OSD
     r              => video_red_o,
     g              => video_green_o,
     b              => video_blue_o,
     pause_cpu      => pause_cpu,
     dim_video      => dim_video_o
     --rgb_out        TODO
    );

    i_hvgen : entity work.hvgen
    port map (
     HPOS       => HPOS,
     VPOS       => VPOS,
     PCLK       => PCLK_EN,
     iRGB       => POUT,
     oRGB       => oRGB,
     HBLK       => video_hblank_o,
     VBLK       => video_vblank_o,
     HSYN       => video_hs_o,
     VSYN       => video_vs_o,
     HOFFS      => HOFFS,
     VOFFS      => VOFFS 
    );
  
    i_GameCore : entity work.greenberet
    port map (
    
    clk48M     => clk_main_i,
    reset      => reset,
   
    INP0(5)    => not keyboard_n(m65_space), -- trigger 2
    INP0(4)    => not m_trig11,              -- trigger 1
    INP0(3)    => not m_left1,               -- left
    INP0(2)    => not m_down1,               -- down    
    INP0(1)    => not m_right1,              -- right      
    INP0(0)    => not m_up1,                 -- up    
  
    INP1(5)    => not keyboard_n(m65_space), -- trigger 2
    INP1(4)    => not m_trig21,              -- trigger 1
    INP1(3)    => not m_left2,               -- left
    INP1(2)    => not m_down2,               -- down    
    INP1(1)    => not m_right2,              -- right      
    INP1(0)    => not m_up2,                 -- up               
   
    INP2(3)    => not keyboard_n(m65_6),     -- coin 2
    INP2(2)    => not keyboard_n(m65_5),     -- coin 1
    INP2(1)    => not keyboard_n(m65_2),     -- start 2
    INP2(0)    => not keyboard_n(m65_1),     -- start 1
    
    -- Loading default DIP settings from config.vhd ( when set to 1) crashes game after completion of power up tests.
    DSW0       => not dsw_a_i,
    DSW1       => not dsw_c_i,
    DSW2       => not dsw_b_i,
    
    TITLE      => "00000000",
    
    PH         => HPOS,
    PV         => VPOS,
    PCLK       => PCLK_EN,
    POUT       => POUT,
    SND        => audio,

    ROMCL      => dn_clk_i,
    ROMAD      => dn_addr_i,
    ROMDT      => dn_data_i,
    ROMEN      => dn_wr_i,
    
    PAUSE      => pause_cpu or pause_i,
    
    hs_address => hs_address,
    hs_data_out=> hs_data_out,
    hs_data_in => hs_data_in,
    hs_write   => hs_write_enable,
    hs_access  => hs_access_read or hs_access_write
   );
 
    /*i_hiscore : entity work.hiscore
    port map (
        clk             => clk_main_i,
        reset           => reset,
        paused          => pause_cpu,
        autosave        => '0',
        ram_address     => hs_address(9 downto 0),
        data_from_ram   => hs_data_out,
        data_from_hps   => dn_data_i,
        data_to_hps     => open,
        ram_write       => hs_write_enable,
        ram_intent_read => hs_access_read,
	    ram_intent_write=> hs_access_write,
	    pause_cpu       => hs_pause,
	    configured      => open,
	    ioctl_upload    => '0',
	    ioctl_download  => '0',
	    ioctl_wr        => dn_wr_i,
	    ioctl_addr      => dn_addr_i,
	    ioctl_index     => "0",
	    OSD_STATUS      => '0'
    );*/

   -- @TODO: Keyboard mapping and keyboard behavior
   -- Each core is treating the keyboard in a different way: Some need low-active "matrices", some
   -- might need small high-active keyboard memories, etc. This is why the MiSTer2MEGA65 framework
   -- lets you define literally everything and only provides a minimal abstraction layer to the keyboard.
   -- You need to adjust keyboard.vhd to your needs
   i_keyboard : entity work.keyboard
      port map (
         clk_main_i           => clk_main_i,

         -- Interface to the MEGA65 keyboard
         key_num_i            => kb_key_num_i,
         key_pressed_n_i      => kb_key_pressed_n_i,

         -- @TODO: Create the kind of keyboard output that your core needs
         -- "example_n_o" is a low active register and used by the demo core:
         --    bit 0: Space
         --    bit 1: Return
         --    bit 2: Run/Stop
         example_n_o          => keyboard_n
      ); -- i_keyboard

end architecture synthesis;

