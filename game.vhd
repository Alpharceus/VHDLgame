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

-- Sankalpa Created: Architecture definition for pong_graph_st entity
architecture rtl of pong_graph_st is

   -- Signal for controlling the refresh rate or update speed of the game, particularly the ball's movement and paddle control.
   signal refr_tick: std_logic;

   -- Pixel coordinates on the screen, ranging from (0,0) to (639,479). These signals represent the current pixel being processed.
   signal pix_x, pix_y: unsigned(9 downto 0);

   -- Constants defining the screen dimensions. MAX_X and MAX_Y are the maximum values for the x and y coordinates, respectively.
   constant MAX_X: integer := 640;
   constant MAX_Y: integer := 480;

   -- Sankalpa added: Constants and signals for defining the winning area's dimensions on the screen.
   constant win_x_l: integer := 0;      -- Left boundary of the winning area
   constant win_x_r: integer := 640;    -- Right boundary of the winning area
   constant win_y_t: integer := 0;      -- Top boundary of the winning area
   constant win_y_b: integer := 480;    -- Bottom boundary of the winning area
   signal win_on: std_logic;            -- Signal to indicate if the winning area is active
   signal win_rgb: std_logic_vector (2 downto 0); -- RGB color for the winning area

   -- Sankalpa added: Constants and signals for defining the losing area's dimensions on the screen.
   constant lose_x_l: integer := 0;     -- Left boundary of the losing area
   constant lose_x_r: integer := 640;   -- Right boundary of the losing area
   constant lose_y_t: integer := 0;     -- Top boundary of the losing area
   constant lose_y_b: integer := 480;   -- Bottom boundary of the losing area
   signal lose_on: std_logic;           -- Signal to indicate if the losing area is active
   signal lose_rgb: std_logic_vector (2 downto 0); -- RGB color for the losing area

   -- Constants defining the x-coordinates for the left and right boundaries of the game's walls or lanes.
   constant WALL_X_L: integer := 212;   -- Left boundary of the first wall
   constant WALL_X_R: integer := 215;   -- Right boundary of the first wall
   constant WALL2_X_L: integer := 425;  -- Left boundary of the second wall
   constant WALL2_X_R: integer := 428;  -- Right boundary of the second wall

   -- Raman added: Constants and signals for a trust bar, a gameplay element. Includes position and dynamic size.
   constant TRUST_X_L: integer := 485;  -- Left boundary of the trust bar
   signal TRUST_X_R: unsigned(9 downto 0); -- Right boundary (variable)
   signal trust_x_reg, trust_x_next: unsigned(9 downto 0); -- Registers for trust bar position
   constant TRUST_Y_T: integer := 10;   -- Top boundary of the trust bar
   constant TRUST_Y_B: integer := 13;   -- Bottom boundary of the trust bar

     --  Raman added: Constants for defining the positions and dimensions of road stripes in the game.
   -- Each ROAD constant pair defines the x-coordinates (left and right) for the vertical road stripes.
   constant ROAD1_X_L: integer := 107;  -- Left x-coordinate for road stripe 1
   constant ROAD1_X_R: integer := 108;  -- Right x-coordinate for road stripe 1
   constant ROAD1_Y_T: integer := 40;   -- Top y-coordinate for road stripe 1
   constant ROAD1_Y_B: integer := 120;  -- Bottom y-coordinate for road stripe 1

   constant ROAD2_X_L: integer := 107;  -- Left x-coordinate for road stripe 2
   constant ROAD2_X_R: integer := 108;  -- Right x-coordinate for road stripe 2
   constant ROAD2_Y_T: integer := 200;  -- Top y-coordinate for road stripe 2
   constant ROAD2_Y_B: integer := 280;  -- Bottom y-coordinate for road stripe 2

   constant ROAD3_X_L: integer := 107;  -- Left x-coordinate for road stripe 3
   constant ROAD3_X_R: integer := 108;  -- Right x-coordinate for road stripe 3
   constant ROAD3_Y_T: integer := 360;  -- Top y-coordinate for road stripe 3
   constant ROAD3_Y_B: integer := 440;  -- Bottom y-coordinate for road stripe 3

   constant ROAD4_X_L: integer := 320;  -- Left x-coordinate for road stripe 4
   constant ROAD4_X_R: integer := 321;  -- Right x-coordinate for road stripe 4
   constant ROAD4_Y_T: integer := 120;  -- Top y-coordinate for road stripe 4
   constant ROAD4_Y_B: integer := 200;  -- Bottom y-coordinate for road stripe 4

   constant ROAD5_X_L: integer := 320;  -- Left x-coordinate for road stripe 5
   constant ROAD5_X_R: integer := 321;  -- Right x-coordinate for road stripe 5
   constant ROAD5_Y_T: integer := 280;  -- Top y-coordinate for road stripe 5
   constant ROAD5_Y_B: integer := 360;  -- Bottom y-coordinate for road stripe 5

   constant ROAD6_X_L: integer := 533;  -- Left x-coordinate for road stripe 6
   constant ROAD6_X_R: integer := 534;  -- Right x-coordinate for road stripe 6
   constant ROAD6_Y_T: integer := 40;   -- Top y-coordinate for road stripe 6
   constant ROAD6_Y_B: integer := 120;  -- Bottom y-coordinate for road stripe 6

   constant ROAD7_X_L: integer := 533;  -- Left x-coordinate for road stripe 7
   constant ROAD7_X_R: integer := 534;  -- Right x-coordinate for road stripe 7
   constant ROAD7_Y_T: integer := 200;  -- Top y-coordinate for road stripe 7
   constant ROAD7_Y_B: integer := 280;  -- Bottom y-coordinate for road stripe 7

   constant ROAD8_X_L: integer := 533;  -- Left x-coordinate for road stripe 8
   constant ROAD8_X_R: integer := 534;  -- Right x-coordinate for road stripe 8
   constant ROAD8_Y_T: integer := 360;  -- Top y-coordinate for road stripe 8
   constant ROAD8_Y_B: integer := 440;  -- Bottom y-coordinate for road stripe 8
   
   -- Constants and signals for the game's paddle (player-controlled bar).
   constant BAR_Y_T: integer := 440;    -- Top boundary of the paddle
   constant BAR_Y_B: integer := 445;    -- Bottom boundary of the paddle
   signal bar_x_l, bar_x_r: unsigned(9 downto 0); -- Left and right boundaries (variable)
   constant BAR_X_SIZE: integer := 72;  -- Horizontal size of the paddle

   -- Registers for tracking the horizontal position of the paddle.
   signal bar_x_reg, bar_x_next: unsigned(9 downto 0);

   -- Constant for paddle movement velocity when a control button is pressed.
   constant BAR_V: integer := 10;

   -- Constants and signals for the square-shaped ball, including its size and position.
   constant BALL_SIZE: integer := 8;
   signal ball_x_l, ball_x_r: unsigned(9 downto 0);
   signal ball_y_t, ball_y_b: unsigned(9 downto 0);

   -- Registers for tracking the position of the ball.
   signal ball_x_reg, ball_x_next: unsigned(9 downto 0);
   signal ball_y_reg, ball_y_next: unsigned(9 downto 0);

   -- Registers for tracking the ball's speed in both x and y directions.
   signal x_delta_reg, x_delta_next: unsigned(9 downto 0);
   signal y_delta_reg, y_delta_next: unsigned(9 downto 0);

   -- Constant for the positive velocity of the ball.
   constant BALL_V_P: unsigned(9 downto 0) := to_unsigned(5, 10);
 

   -- Definition of a custom type for representing a round ball image as an 8x8 matrix.
   type rom_type is array(0 to 7) of std_logic_vector(0 to 7);
   -- ROM representation of the first ball's appearance using a matrix of bits.
   constant BALL_ROM: rom_type:= (
      "11100111",
      "11100111",
      "10111101", 
      "10011001", 
      "10011001", 
      "10000001", 
      "10000001",
      "10000001");
   -- Signals for addressing and accessing ROM data.
   signal rom_addr, rom_col: unsigned(2 downto 0);
   signal rom_data: std_logic_vector(7 downto 0);
   signal rom_bit: std_logic;


 --Raman added:
   -- Declaration of constants and signals for the second ball.
   constant BALL2_SIZE: integer := 8;  -- Size of the second ball
   -- Signals for the second ball's position and boundaries.
   signal ball2_x_l, ball2_x_r: unsigned(9 downto 0);
   signal ball2_y_t, ball2_y_b: unsigned(9 downto 0);

   -- Registers for tracking the position of the second ball.
   signal ball2_x_reg, ball2_x_next: unsigned(9 downto 0);
   signal ball2_y_reg, ball2_y_next: unsigned(9 downto 0);

   -- Registers for tracking the second ball's speed in both x and y directions.
   signal x2_delta_reg, x2_delta_next: unsigned(9 downto 0);
   signal y2_delta_reg, y2_delta_next: unsigned(9 downto 0);

   -- Constant for the positive velocity of the second ball.
   constant BALL2_V_P: unsigned(9 downto 0) := to_unsigned(5, 10);

   -- ROM type and definition for the second ball's appearance.
   type rom_type2 is array(0 to 7) of std_logic_vector(0 to 7);
   constant BALL2_ROM: rom_type2 := (
       "11111111",
       "11111111",
       "00111000", 
       "00111000", 
       "00111000", 
       "00111000", 
       "00111000",
       "00111000");
   
   -- Signals for addressing and accessing the second ball's ROM data.
   signal rom2_addr, rom2_col: unsigned(2 downto 0);
   signal rom2_data: std_logic_vector(7 downto 0);
   signal rom2_bit: std_logic;

   -- Declaration of constants and signals for the third ball.
   constant BALL3_SIZE: integer := 8;  -- Size of the third ball
   -- Signals for the third ball's position and boundaries.
   signal ball3_x_l, ball3_x_r: unsigned(9 downto 0);
   signal ball3_y_t, ball3_y_b: unsigned(9 downto 0);

   -- Registers for tracking the position of the third ball.
   signal ball3_x_reg, ball3_x_next: unsigned(9 downto 0);
   signal ball3_y_reg, ball3_y_next: unsigned(9 downto 0);

   -- Registers for tracking the third ball's speed in both x and y directions.
   signal x3_delta_reg, x3_delta_next: unsigned(9 downto 0);
   signal y3_delta_reg, y3_delta_next: unsigned(9 downto 0);

   -- Constant for the positive velocity of the third ball.
   constant BALL3_V_P: unsigned(9 downto 0) := to_unsigned(5, 10);

   -- ROM type and definition for the third ball's appearance.
   type rom_type3 is array(0 to 7) of std_logic_vector(0 to 7);
   constant BALL3_ROM: rom_type3 := (
       "11111111",
       "11100111", 
       "11000011", 
       "10000001", 
       "10000001", 
       "11000011", 
       "11100111",
       "11111111");
   
   -- Signals for addressing and accessing the third ball's ROM data.
   signal rom3_addr, rom3_col: unsigned(2 downto 0);
   signal rom3_data: std_logic_vector(7 downto 0);
   signal rom3_bit: std_logic;

   -- Output signals indicating whether the current scan coordinates are within the bounds of each game object.
   signal wall_on, wall2_on, bar_on, sq_ball_on, rd_ball_on, sq_ball2_on, rd_ball2_on, sq_ball3_on, rd_ball3_on, trust_on, road1_on, road2_on, road3_on, road4_on, road5_on, road6_on, road7_on, road8_on: std_logic;

   -- RGB color signals for each game object.
   signal wall_rgb, wall2_rgb, bar_rgb, ball_rgb, ball2_rgb, ball3_rgb, trust_rgb, road1_rgb, road2_rgb, road3_rgb, road4_rgb, road5_rgb, road6_rgb, road7_rgb, road8_rgb: std_logic_vector(2 downto 0);

-- ======================================================================================================
  --Sankalpa added:
   begin

   process (clk, reset)
      begin
      if (reset = '1') then
         bar_x_reg <= ("0100011100");
         trust_x_reg <= ("0111110101");
         --trust_delta_reg <= ("0000000000");
         ball_x_reg <= ("0100111100");
         ball_y_reg <= (others => '0');
         x_delta_reg <= ("0000000000");
         y_delta_reg <= BALL_V_P;
         
         
         ball2_x_reg <= ("1000010001");
         ball2_y_reg <= (others => '0');
         x2_delta_reg <= ("0000000000");
         y2_delta_reg <= BALL2_V_P;
         
         ball3_x_reg <= ("0001100111");
         ball3_y_reg <= (others => '0');
         x3_delta_reg <= ("0000000000");
         y3_delta_reg <= BALL3_V_P;
         
      elsif (clk'event and clk = '1') then
         bar_x_reg <= bar_x_next;
         trust_x_reg <= trust_x_next;
         --trust_delta_reg <= trust_delta_next;
         
         ball_x_reg <= ball_x_next;
         ball_y_reg <= ball_y_next;
         x_delta_reg <= x_delta_next;
         y_delta_reg <= y_delta_next;
         
         ball2_x_reg <= ball2_x_next;
         ball2_y_reg <= ball2_y_next;
         x2_delta_reg <= x2_delta_next;
         y2_delta_reg <= y2_delta_next;
         
         
         ball3_x_reg <= ball3_x_next;
         ball3_y_reg <= ball3_y_next;
         x3_delta_reg <= x3_delta_next;
         y3_delta_reg <= y3_delta_next;
      end if;
   end process;

-- ======================================================================================================
   pix_x <= unsigned(pixel_x);
   pix_y <= unsigned(pixel_y);

-- Refr_tick: 1-clock tick asserted at start of v_sync, e.g., when the screen is refreshed -- speed is 60 Hz
   refr_tick <= '1' when (pix_y = 1) and (pix_x = 1) else '0';
   



-- ======================================================================================================
   -- Logic for displaying the left vertical wall stripe.
   -- The wall is on when the current pixel's x-coordinate is within the wall's boundaries.
   wall_on <= '1' when (WALL_X_L <= pix_x) and (pix_x <= WALL_X_R) else '0';
   wall_rgb <= "000"; -- Assigning the color black to the wall

   -- Logic for displaying the right vertical wall stripe.
   -- Similar to the left wall, but for the right wall's position.
   wall2_on <= '1' when (WALL2_X_L <= pix_x) and (pix_x <= WALL2_X_R) else '0';
   wall2_rgb <= "000"; -- Assigning the color black to the second wall

   -- ======================================================================================================
   -- Logic for road stripes rendering. Each road stripe is active when the current pixel coordinates
   -- fall within its defined area.
   road1_on <= '1' when (ROAD1_X_L <= pix_x) and (pix_x <= ROAD1_X_R) and (ROAD1_Y_T <= pix_y) and (pix_y <= ROAD1_Y_B) else '0';
   road1_rgb <= "000"; -- Assigning the color black to road stripe 1

   -- Similar logic for other road stripes, each with its own specified coordinates.
   road2_on <= '1' when (ROAD2_X_L <= pix_x) and (pix_x <= ROAD2_X_R) and (ROAD2_Y_T <= pix_y) and (pix_y <= ROAD2_Y_B) else '0';
   road2_rgb <= "000"; -- Assigning the color black to road stripe 2

   road3_on <= '1' when (ROAD3_X_L <= pix_x) and (pix_x <= ROAD3_X_R) and (ROAD3_Y_T <= pix_y) and (pix_y <= ROAD3_Y_B) else '0';
   road3_rgb <= "000"; -- Assigning the color black to road stripe 3

   road4_on <= '1' when (ROAD4_X_L <= pix_x) and (pix_x <= ROAD4_X_R) and (ROAD4_Y_T <= pix_y) and (pix_y <= ROAD4_Y_B) else '0';
   road4_rgb <= "000"; -- Assigning the color black to road stripe 4

   road5_on <= '1' when (ROAD5_X_L <= pix_x) and (pix_x <= ROAD5_X_R) and (ROAD5_Y_T <= pix_y) and (pix_y <= ROAD5_Y_B) else '0';
   road5_rgb <= "000"; -- Assigning the color black to road stripe 5

   road6_on <= '1' when (ROAD6_X_L <= pix_x) and (pix_x <= ROAD6_X_R) and (ROAD6_Y_T <= pix_y) and (pix_y <= ROAD6_Y_B) else '0';
   road6_rgb <= "000"; -- Assigning the color black to road stripe 6

   road7_on <= '1' when (ROAD7_X_L <= pix_x) and (pix_x <= ROAD7_X_R) and (ROAD7_Y_T <= pix_y) and (pix_y <= ROAD7_Y_B) else '0';
   road7_rgb <= "000"; -- Assigning the color black to road stripe 7

   road8_on <= '1' when (ROAD8_X_L <= pix_x) and (pix_x <= ROAD8_X_R) and (ROAD8_Y_T <= pix_y) and (pix_y <= ROAD8_Y_B) else '0';
   road8_rgb <= "000"; -- Assigning the color black to road stripe 8

   -- ======================================================================================================
   -- Logic for the trust bar, a gameplay element. It is active when the current pixel coordinates fall
   -- within its defined area.
   trust_x_r <= trust_x_reg;
   trust_on <= '1' when (TRUST_X_L <= pix_x) and (pix_x <= TRUST_X_R) and (TRUST_Y_T <= pix_y) and (pix_y <= TRUST_Y_B) else '0';
   trust_rgb <= "010"; -- Assigning the color green to the trust bar

   -- ======================================================================================================
   -- Logic for the paddle rendering. The paddle is active when the current pixel coordinates are within
   -- its defined boundaries.
   bar_x_l <= bar_x_reg;
   bar_x_r <= bar_x_l + BAR_X_SIZE - 1;
   bar_on <= '1' when (BAR_X_L <= pix_x) and (pix_x <= BAR_X_R) and (bar_y_t <= pix_y) and (pix_y <= bar_y_b) else '0';
   bar_rgb <= "000"; -- Assigning the color black to the paddle


-- ======================================================================================================
    --trust_x_next <= trust_x_reg + trust_delta_reg;
    
    
    
    --process(trust_delta_reg, ball_x_l, ball_x_r, ball_y_b, bar_x_r, bar_x_l, refr_tick)
    --begin
    --trust_delta_next <= trust_delta_reg;
    --if ( refr_tick2 = '1' ) then
      --  if (bar_x_l <= ball_x_l AND ball_x_r <= bar_x_r AND bar_y_t = ball_y_b) then
       --     trust_delta_next <=trust_delta_reg - 10;
        --elsif (bar_x_l <= ball2_x_l AND ball2_x_r <= bar_x_r AND bar_y_t = ball2_y_b) then
         --   trust_delta_next <=trust_delta_reg + 10;
        --elsif (bar_x_l <= ball3_x_l AND ball3_x_r <= bar_x_r AND bar_y_t = ball3_y_b) then
          --  trust_delta_next <="0000001010";
        --end if;
    --end if;    
    --end process;
    
 
    --Raman & Sankalpa added:
    process( ball_x_l, ball_x_r, ball_y_b, ball2_x_l, ball2_x_r, ball2_y_b, bar_x_r, bar_x_l, refr_tick)
    begin
        if (bar_x_l <= ball_x_l AND ball_x_r <= bar_x_r AND bar_y_t = ball_y_b AND refr_tick = '1') then
            trust_x_next <= trust_x_reg - 10;
        elsif (bar_x_l <= ball2_x_l AND ball2_x_r <= bar_x_r AND bar_y_t = ball2_y_b AND refr_tick = '1') then
          trust_x_next <= trust_x_reg + 10;
        else
            trust_x_next <= trust_x_reg;
        end if;
    end process;
    
  --trust_x_next <= trust_x_reg + 10 when (bar_x_l <= ball_x_l AND ball_x_r <= bar_x_r AND bar_y_t = ball_y_b AND refr_tick = '1') else trust_x_reg;
  --=====================================================================================================
 --Sankalpa added:
   --Win Lose Conditions
   win_on <= '1' when (win_x_l <= pix_x) and (pix_x <= win_x_r) and (win_y_t <= pix_y) and (pix_y <= win_y_b) and ( "1001001001" <= trust_x_r)  else '0';
   win_rgb <= "001";
   
   lose_on <= '1' when (lose_x_l <= pix_x) and (pix_x <= lose_x_r) and (lose_y_t <= pix_y) and (pix_y <= lose_y_b) and
                        ((bar_x_l <= ball3_x_l AND ball3_x_r <= bar_x_r AND bar_y_t = ball3_y_b) OR (trust_x_r <= "0111101111")) else '0';
   lose_rgb <= "100";
--=======================================================================================================
-- Process bar movement requests
   process( bar_x_reg, bar_x_l, bar_x_r, refr_tick, btn)
      begin
      bar_x_next <= bar_x_reg; -- no move
      if ( refr_tick = '1' ) then

-- if btn 1 pressed and paddle not at bottom yet
         if ( btn(1) = '1' and bar_x_l > BAR_V) then
            bar_x_next <= bar_x_reg - BAR_V; -- move up
            
-- if btn 0 pressed and bar not at top yet
         elsif ( btn(0) = '1' and bar_x_r < (MAX_X - 1 - BAR_V)) then
            bar_x_next <= bar_x_reg + BAR_V; -- move down
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
   rd_ball_on <= '1' when (sq_ball_on = '1') and (rom_bit = '1') and not(bar_x_l <= ball_x_l AND ball_x_r <= bar_x_r AND bar_y_t <= ball_y_b) else '0';
   ball_rgb <= "100"; -- red

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



   
      end if;
   end process;
   
 --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 --Raman added:
    ball2_x_l <= ball2_x_reg;
    ball2_y_t <= ball2_y_reg;
    ball2_x_r <= ball2_x_l + BALL2_SIZE - 1;
    ball2_y_b <= ball2_y_t + BALL2_SIZE - 1;
    
    sq_ball2_on <= '1' when (ball2_x_l <= pix_x) and (pix_x <= ball2_x_r) and (ball2_y_t <= pix_y) and (pix_y <= ball2_y_b) else '0';
    
    rom2_addr <= pix_y(2 downto 0) - ball2_y_t(2 downto 0);
    rom2_col <= pix_x(2 downto 0) - ball2_x_l(2 downto 0);
    
    rom2_data <= BALL2_ROM(to_integer(rom2_addr));
    rom2_bit <= rom2_data(to_integer(rom2_col));
    
    rd_ball2_on <= '1' when (sq_ball2_on = '1') and (rom2_bit = '1') and not(bar_x_l <= ball2_x_l AND ball2_x_r <= bar_x_r AND bar_y_t <= ball2_y_b)  else '0';
    ball2_rgb <= "010";
    
    ball2_x_next <= ball2_x_reg + x2_delta_reg when refr_tick = '1' else ball2_x_reg;
    ball2_y_next <= ball2_y_reg + y2_delta_reg when refr_tick = '1' else ball2_y_reg;
    
    process(x2_delta_reg, y2_delta_reg, ball2_y_t, ball2_x_l, ball2_x_r, ball2_y_t, ball2_y_b, bar_x_l, bar_x_r)
    begin
       x2_delta_next <= x2_delta_reg;
       y2_delta_next <= y2_delta_reg;
    
       if (ball2_y_t < 1) then 
          y2_delta_next <= BALL2_V_P;
 

       end if;
    end process;

 
 --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 
 
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  --Raman added:
    ball3_x_l <= ball3_x_reg;
    ball3_y_t <= ball3_y_reg;
    ball3_x_r <= ball3_x_l + BALL3_SIZE - 1;
    ball3_y_b <= ball3_y_t + BALL3_SIZE - 1;
    
    sq_ball3_on <= '1' when (ball3_x_l <= pix_x) and (pix_x <= ball3_x_r) and (ball3_y_t <= pix_y) and (pix_y <= ball3_y_b) else '0';
    
    rom3_addr <= pix_y(2 downto 0) - ball3_y_t(2 downto 0);
    rom3_col <= pix_x(2 downto 0) - ball3_x_l(2 downto 0);
    
    rom3_data <= BALL3_ROM(to_integer(rom3_addr));
    rom3_bit <= rom3_data(to_integer(rom3_col));
    
    rd_ball3_on <= '1' when (sq_ball3_on = '1') and (rom3_bit = '1') and not(bar_x_l <= ball3_x_l AND ball3_x_r <= bar_x_r AND bar_y_t <= ball3_y_b)  else '0';
    ball3_rgb <= "001";
    
    ball3_x_next <= ball3_x_reg + x3_delta_reg when refr_tick = '1' else ball3_x_reg;
    ball3_y_next <= ball3_y_reg + y3_delta_reg when refr_tick = '1' else ball3_y_reg;
    
    process(x3_delta_reg, y3_delta_reg, ball3_y_t, ball3_x_l, ball3_x_r, ball3_y_t, ball3_y_b, bar_x_l, bar_x_r)
    begin
       x3_delta_next <= x3_delta_reg;
       y3_delta_next <= y3_delta_reg;
    
       if (ball3_y_t < 1) then 
          y3_delta_next <= BALL3_V_P;


       end if;
    end process;

 
 --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

-- ======================================================================================================

 --Sankalpa added:
-- turn on the appropriate color depending on the current pixel position.
   process (video_on, win_on, lose_on, wall_on, wall2_on, bar_on, rd_ball_on, rd_ball2_on,rd_ball3_on,trust_on, 
            win_rgb, lose_rgb, wall_rgb, wall2_rgb, bar_rgb, ball_rgb,trust_rgb,road1_on, road2_on, road3_on, 
            road4_on, road5_on, road6_on, road7_on, road8_on,road1_rgb, road2_rgb, road3_rgb, road4_rgb, 
            road5_rgb, road6_rgb,road7_rgb, road8_rgb)
      begin
      if (video_on = '0') then
         graph_rgb <= "000"; -- blank
      else 
         if (win_on = '1') then
            graph_rgb <= win_rgb;
         elsif (lose_on = '1') then
            graph_rgb <= lose_rgb;      
         elsif (wall_on = '1') then
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
         elsif (rd_ball2_on = '1') then
            graph_rgb <= ball2_rgb;   
         elsif (rd_ball3_on = '1') then
            graph_rgb <= ball3_rgb;
         else
            graph_rgb <= "111"; -- yellow bkgnd
         end if;
      end if;
   end process;

end rtl;
