library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity pong_graph_st is
   port(
      clk, reset: in std_logic;
      btn: in std_logic_vector(1 downto 0);
      video_on: in std_logic;
      pixel_x, pixel_y: in std_logic_vector(9 downto 0);
      graph_rgb: out std_logic_vector(2 downto 0)
   );
end pong_graph_st;

-- ======================================================================================================
-- ======================================================================================================

architecture rtl of pong_graph_st is

-- Signal used to control speed of ball and how often pushbuttons are checked for paddle movement.
   signal refr_tick: std_logic;

-- x, y coordinates (0,0 to (639, 479)
   signal pix_x, pix_y: unsigned(9 downto 0);

-- Screen dimensions
   constant MAX_X: integer := 640;
   constant MAX_Y: integer := 480;

-- Wall left and right boundary of wall (full height)
   constant WALL_X_L: integer := 212;
   constant WALL_X_R: integer := 215;

   constant WALL2_X_L: integer := 425;
   constant WALL2_X_R: integer := 428;
   
   constant TRUST_X_L: integer := 500;
   constant TRUST_X_R: integer := 599;
   constant TRUST_Y_T: integer := 10;
   constant TRUST_Y_B: integer := 13;
  
   
   constant ROAD1_X_L: integer := 107;
   constant ROAD1_X_R: integer := 108;
   constant ROAD1_Y_T: integer := 40;
   constant ROAD1_Y_B: integer := 120;
   
   constant ROAD2_X_L: integer := 107;
   constant ROAD2_X_R: integer := 108;
   constant ROAD2_Y_T: integer := 200;
   constant ROAD2_Y_B: integer := 280;
   
   constant ROAD3_X_L: integer := 107;
   constant ROAD3_X_R: integer := 108;
   constant ROAD3_Y_T: integer := 360;
   constant ROAD3_Y_B: integer := 440;
   
   constant ROAD4_X_L: integer := 320;
   constant ROAD4_X_R: integer := 321;
   constant ROAD4_Y_T: integer := 120;
   constant ROAD4_Y_B: integer := 200;
   
   constant ROAD5_X_L: integer := 320;
   constant ROAD5_X_R: integer := 321;
   constant ROAD5_Y_T: integer := 280;
   constant ROAD5_Y_B: integer := 360;
   
   constant ROAD6_X_L: integer := 533;
   constant ROAD6_X_R: integer := 534;
   constant ROAD6_Y_T: integer := 40;
   constant ROAD6_Y_B: integer := 120;
   
   constant ROAD7_X_L: integer := 533;
   constant ROAD7_X_R: integer := 534;
   constant ROAD7_Y_T: integer := 200;
   constant ROAD7_Y_B: integer := 280;
   
   constant ROAD8_X_L: integer := 533;
   constant ROAD8_X_R: integer := 534;
   constant ROAD8_Y_T: integer := 360;
   constant ROAD8_Y_B: integer := 440;
   
-- Paddle left, right, top, bottom and height -- left & right are constant. Top & bottom are signals to allow movement. bar_y_t driven by register below.
   constant BAR_Y_T: integer := 440;
   constant BAR_Y_B: integer := 445;
   signal bar_x_l, bar_x_r: unsigned(9 downto 0);
   constant BAR_X_SIZE: integer := 72;

-- Reg to track top boundary (x position is fixed)
   signal bar_x_reg, bar_x_next: unsigned( 9 downto 0);

-- Bar moving velocity when a button is pressed -- the amount the bar is moved.
   constant BAR_V: integer:= 10;

-- Square ball -- ball left, right, top and bottom all vary. Left and top driven by registers below.
   constant BALL_SIZE: integer := 8;
   signal ball_x_l, ball_x_r: unsigned(9 downto 0);
   signal ball_y_t, ball_y_b: unsigned(9 downto 0);

-- Reg to track left and top boundary
   signal ball_x_reg, ball_x_next: unsigned(9 downto 0);
   signal ball_y_reg, ball_y_next: unsigned(9 downto 0);

-- reg to track ball speed
   signal x_delta_reg, x_delta_next: unsigned(9 downto 0);
   signal y_delta_reg, y_delta_next: unsigned(9 downto 0);

-- ball movement can be pos or neg
   constant BALL_V_P: unsigned(9 downto 0):= to_unsigned(2,10);
   constant BALL_V_N: unsigned(9 downto 0):= unsigned(to_signed(-2,10));

-- round ball image
   type rom_type is array(0 to 7) of std_logic_vector(0 to 7);
   constant BALL_ROM: rom_type:= (
      "00000000",
      "00000000",
      "00000000", 
      "00000000", 
      "00000000", 
      "00000000", 
      "00000000",
      "00000000");

   signal rom_addr, rom_col: unsigned(2 downto 0);
   signal rom_data: std_logic_vector(7 downto 0);
   signal rom_bit: std_logic;

-- object output signals -- new signal to indicate if scan coord is within ball
   signal wall_on, wall2_on, bar_on, sq_ball_on, rd_ball_on,trust_on,road1_on, road2_on, road3_on, road4_on, road5_on, road6_on, road7_on, road8_on: std_logic;
   signal wall_rgb, wall2_rgb, bar_rgb, ball_rgb, trust_rgb, road1_rgb, road2_rgb, road3_rgb, road4_rgb, road5_rgb, road6_rgb, road7_rgb, road8_rgb: std_logic_vector(2 downto 0);

-- ======================================================================================================
   begin

   process (clk, reset)
      begin
      if (reset = '1') then
         bar_x_reg <= ("0100011100");
         ball_x_reg <= (others => '0');
         ball_y_reg <= (others => '0');
         x_delta_reg <= ("0000000100");
         y_delta_reg <= ("0000000100");
      elsif (clk'event and clk = '1') then
         bar_x_reg <= bar_x_next;
         ball_x_reg <= ball_x_next;
         ball_y_reg <= ball_y_next;
         x_delta_reg <= x_delta_next;
         y_delta_reg <= y_delta_next;
      end if;
   end process;

-- ======================================================================================================
   pix_x <= unsigned(pixel_x);
   pix_y <= unsigned(pixel_y);

-- Refr_tick: 1-clock tick asserted at start of v_sync, e.g., when the screen is refreshed -- speed is 60 Hz
   refr_tick <= '1' when (pix_y = 1) and (pix_x = 1) else '0';

-- ======================================================================================================
-- wall left vertical stripe
   wall_on <= '1' when (WALL_X_L <= pix_x) and (pix_x <= WALL_X_R) else '0';
   wall_rgb <= "000"; -- blue
   
   wall2_on <= '1' when (WALL2_X_L <= pix_x) and (pix_x <= WALL2_X_R) else '0';
   wall2_rgb <= "000"; -- blue
-- ======================================================================================================
---road stripes
   road1_on <= '1' when (ROAD1_X_L <= pix_x) and (pix_x <= ROAD1_X_R) and (ROAD1_Y_T <= pix_y) and (pix_y <= ROAD1_Y_B) else '0';
   road1_rgb <= "000"; -- green
   
   road2_on <= '1' when (ROAD2_X_L <= pix_x) and (pix_x <= ROAD2_X_R) and (ROAD2_Y_T <= pix_y) and (pix_y <= ROAD2_Y_B) else '0';
   road2_rgb <= "000"; -- green
   
   road3_on <= '1' when (ROAD3_X_L <= pix_x) and (pix_x <= ROAD3_X_R) and (ROAD3_Y_T <= pix_y) and (pix_y <= ROAD3_Y_B) else '0';
   road3_rgb <= "000"; -- green
   
   road4_on <= '1' when (ROAD4_X_L <= pix_x) and (pix_x <= ROAD4_X_R) and (ROAD4_Y_T <= pix_y) and (pix_y <= ROAD4_Y_B) else '0';
   road4_rgb <= "000"; -- green
   
   road5_on <= '1' when (ROAD5_X_L <= pix_x) and (pix_x <= ROAD5_X_R) and (ROAD5_Y_T <= pix_y) and (pix_y <= ROAD5_Y_B) else '0';
   road5_rgb <= "000"; -- green
   
   road6_on <= '1' when (ROAD6_X_L <= pix_x) and (pix_x <= ROAD6_X_R) and (ROAD6_Y_T <= pix_y) and (pix_y <= ROAD6_Y_B) else '0';
   road6_rgb <= "000"; -- green
   
   road7_on <= '1' when (ROAD7_X_L <= pix_x) and (pix_x <= ROAD7_X_R) and (ROAD7_Y_T <= pix_y) and (pix_y <= ROAD7_Y_B) else '0';
   road7_rgb <= "000"; -- green
   
   road8_on <= '1' when (ROAD8_X_L <= pix_x) and (pix_x <= ROAD8_X_R) and (ROAD8_Y_T <= pix_y) and (pix_y <= ROAD8_Y_B) else '0';
   road8_rgb <= "000"; -- green
-- ======================================================================================================
--trust bar
   trust_on <= '1' when (TRUST_X_L <= pix_x) and (pix_x <= TRUST_X_R) and (TRUST_Y_T <= pix_y) and (pix_y <= TRUST_Y_B) else '0';
   trust_rgb <= "101"; -- green
-- ======================================================================================================
-- pixel within paddle
   bar_x_l <= bar_x_reg;
   bar_x_r <= bar_x_l + BAR_X_SIZE - 1;
   bar_on <= '1' when (BAR_X_L <= pix_x) and (pix_x <= BAR_X_R) and (bar_y_t <= pix_y) and (pix_y <= bar_y_b) else '0';
   bar_rgb <= "000"; -- green

-- ======================================================================================================
-- Process bar movement requests
   process( bar_x_reg, bar_x_l, bar_x_r, refr_tick, btn)
      begin
      bar_x_next <= bar_x_reg; -- no move
      if ( refr_tick = '1' ) then

-- if btn 1 pressed and paddle not at bottom yet
         if ( btn(1) = '1' and bar_x_r < (MAX_X - 1 - BAR_V)) then
            bar_x_next <= bar_x_reg + BAR_V; -- move down

-- if btn 0 pressed and bar not at top yet
         elsif ( btn(0) = '1' and bar_x_l > BAR_V) then
            bar_x_next <= bar_x_reg - BAR_V; -- move up
         end if;
      end if;
   end process;

-- ======================================================================================================
-- set coordinates of square ball.
   ball_x_l <= ball_x_reg;
   ball_y_t <= ball_y_reg;
   ball_x_r <= ball_x_l + BALL_SIZE - 1;
   ball_y_b <= ball_y_t + BALL_SIZE - 1;

-- pixel within square ball
   sq_ball_on <= '1' when (ball_x_l <= pix_x) and (pix_x <= ball_x_r) and (ball_y_t <= pix_y) and (pix_y <= ball_y_b) else '0';

-- Map scan coord to ROM addr/col -- use low order three bits of pixel and ball positions. ROM row
   rom_addr <= pix_y(2 downto 0) - ball_y_t(2 downto 0);

-- ROM column
   rom_col <= pix_x(2 downto 0) - ball_x_l(2 downto 0);

-- Get row data
   rom_data <= BALL_ROM(to_integer(rom_addr));

-- Get column bit
   rom_bit <= rom_data(to_integer(rom_col));

-- Turn ball on only if within square and the ROM bit is 1.
   rd_ball_on <= '1' when (sq_ball_on = '1') and (rom_bit = '1') else '0';
   ball_rgb <= "000"; -- red

-- Update the ball position 60 times per second.
   ball_x_next <= ball_x_reg + x_delta_reg when refr_tick = '1' else ball_x_reg;
   ball_y_next <= ball_y_reg + y_delta_reg when refr_tick = '1' else ball_y_reg;

-- Set the value of the next ball position according to the boundaries.
   process(x_delta_reg, y_delta_reg, ball_y_t, ball_x_l, ball_x_r, ball_y_t, ball_y_b, bar_x_l, bar_x_r)
      begin
      x_delta_next <= x_delta_reg;
      y_delta_next <= y_delta_reg;

-- Ball reached top, make offset positive
      if ( ball_y_t < 1 ) then 
         y_delta_next <= BALL_V_P;

-- Reached bottom, make negative
      elsif (ball_y_b > (MAX_Y - 1)) then 
         y_delta_next <= BALL_V_N;

-- Reach wall, bounce back
      elsif (ball_x_l <= WALL_X_R ) then 
         x_delta_next <= BALL_V_P; 

-- Right corner of ball inside bar
      elsif ((BAR_Y_B <= ball_x_r) and (ball_x_r <= BAR_Y_B)) then

-- Some portion of ball hitting paddle, reverse direction
         if ((bar_x_r <= ball_y_b) and (ball_y_t <= bar_x_r)) then
            x_delta_next <= BALL_V_N; 
         end if;
      end if;
   end process;

-- ======================================================================================================
-- turn on the appropriate color depending on the current pixel position.
   process (video_on, wall_on, wall2_on, bar_on, rd_ball_on,trust_on, wall_rgb, wall2_rgb, bar_rgb, ball_rgb,trust_rgb,road1_on, road2_on, road3_on, road4_on, road5_on, road6_on, road7_on, road8_on,road1_rgb, road2_rgb, road3_rgb, road4_rgb, road5_rgb, road6_rgb,road7_rgb, road8_rgb)
      begin
      if (video_on = '0') then
         graph_rgb <= "000"; -- blank
      else 
         if (wall_on = '1') then
            graph_rgb <= wall_rgb;
         elsif (wall2_on = '1') then
            graph_rgb <= wall2_rgb;
         elsif (trust_on = '1') then
            graph_rgb <= trust_rgb;
         elsif (bar_on = '1') then
            graph_rgb <= bar_rgb;
         elsif (road1_on = '1') then
            graph_rgb <= road1_rgb;
         elsif (road2_on = '1') then
            graph_rgb <= road2_rgb;
         elsif (road3_on = '1') then
            graph_rgb <= road3_rgb;
         elsif (road4_on = '1') then
            graph_rgb <= road4_rgb;
         elsif (road5_on = '1') then
            graph_rgb <= road5_rgb;
         elsif (road6_on = '1') then
            graph_rgb <= road6_rgb;
         elsif (road7_on = '1') then
            graph_rgb <= road7_rgb;
         elsif (road8_on = '1') then
            graph_rgb <= road8_rgb;
         elsif (rd_ball_on = '1') then
            graph_rgb <= ball_rgb;
         else
            graph_rgb <= "111"; -- yellow bkgnd
         end if;
      end if;
   end process;

end rtl;
