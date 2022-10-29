# Jacob Sharp
# jws146

# Directions
.eqv DIR_N 0
.eqv DIR_E 1
.eqv DIR_S 2
.eqv DIR_W 3

# Grid
.eqv GRID_CELL_SIZE 4 # pixels
.eqv GRID_WIDTH  16 # cells
.eqv GRID_HEIGHT 14 # cells
.eqv GRID_CELLS 224 # = GRID_WIDTH * GRID_HEIGHT

# Snake
.eqv SNAKE_MAX_LEN GRID_CELLS # max snake length
.eqv SNAKE_MOVE_DELAY 12 # frames between movements

# Apples
.eqv APPLES_NEEDED 20 # apples to win

# Sizes
.eqv WORD_SIZE 4

# ------------------------------------------------------------------------------------------------

.data
	# Game State
	lost_game: .word 0 # 1 if player lost game
	
	# Snake Attributes
	snake_dir: .word DIR_N 				# the direction the snake is facing (# Directions)
	snake_len: .word 2 					# snake length in grid cells
	snake_x: .byte 0 : SNAKE_MAX_LEN 	# arrays of coordinates of snake segments
	snake_y: .byte 0 : SNAKE_MAX_LEN
	snake_move_timer: .word 0 			# pause before move
	snake_dir_changed: .word 0 			# 1 if the snake changed direction since last move
	
	# Apples
	apples_eaten: .word 0 				# how many apples have been eaten.
	apple_x: .word 3 					# coordinates of the (displayed) apple
	apple_y: .word 2
	
	# A pair of arrays, indexed by direction, to turn a direction into x/y deltas.
	# e.g. direction_delta_x[DIR_E] is 1, because moving east increments X by 1.
	#                         N  E  S  W
	direction_delta_x: .byte  0  1  0 -1
	direction_delta_y: .byte -1  0  1  0

.text

# ------------------------------------------------------------------------------------------------

# Display
.include "display_2211_0822.asm"
.include "textures.asm"
.text

# ------------------------------------------------------------------------------------------------

.globl main
main:
	jal setup_snake

	# pause for user to move
	jal wait_for_game_start

	_loop: # main game loop
		jal check_input
		jal update_snake
		jal draw_all
		jal display_update_and_clear
		jal wait_for_next_frame
		jal check_game_over
		
		beq v0, 0, _loop

	jal show_game_over_message
syscall_exit

# ------------------------------------------------------------------------------------------------
# Misc game logic
# ------------------------------------------------------------------------------------------------

# waits for the user to press a key to start the game
wait_for_game_start:
enter
	_loop: # while no keys are pressed
		jal draw_all
		jal display_update_and_clear
		jal wait_for_next_frame
		jal input_get_keys_pressed
		
		beq v0, 0, _loop # != 0 when key pressed
leave

# ------------------------------------------------------------------------------------------------

# returns 1 if the game is over
check_game_over:
enter
	li v0, 0

	# check if enough apples have been eaten
	lw t0, apples_eaten
	blt t0, APPLES_NEEDED, _endif
		li v0, 1
		j _return
	_endif:

	# update lost_game
	lw t0, lost_game
	beq t0, 0, _return
		li v0, 1
	
	_return: # return v0
leave

# ------------------------------------------------------------------------------------------------

show_game_over_message:
enter
	# clear display
	jal display_update_and_clear

	# check if game was lost
	lw t0, lost_game
	bne t0, 0, _lost # game won
		# display 1st line
		li   a0, 7
		li   a1, 25
		lstr a2, "yay! you"
		li   a3, COLOR_GREEN
		jal  display_draw_colored_text

		# display 2nd line
		li   a0, 12
		li   a1, 31
		lstr a2, "did it!"
		li   a3, COLOR_GREEN
		jal  display_draw_colored_text

		j _endif
	
	_lost: # game lost
		# display centered line
		li   a0, 5
		li   a1, 30
		lstr a2, "oh no :("
		li   a3, COLOR_RED
		jal  display_draw_colored_text
	
	_endif:

	jal display_update_and_clear
leave

# ------------------------------------------------------------------------------------------------
# Snake
# ------------------------------------------------------------------------------------------------

# sets up the snake so the first two segments are in the middle of the screen.
setup_snake:
enter
	# snake head in the middle, tail below it
	li  t0, GRID_WIDTH
	div t0, t0, 2
	sb  t0, snake_x
	sb  t0, snake_x + 1

	li  t0, GRID_HEIGHT
	div t0, t0, 2
	sb  t0, snake_y
	add t0, t0, 1
	sb  t0, snake_y + 1
leave

# ------------------------------------------------------------------------------------------------

# checks for the arrow keys to change the snake's direction.
check_input:
enter
	# only check once per update TODO***********************************************
	lw t0, snake_dir_changed
	bne t0, 0, _break

	# determine which key was pressed
	jal input_get_keys_held

	lw t0, snake_dir

	beq v0, KEY_U, _north
	beq v0, KEY_D, _south
	beq v0, KEY_R, _east
	beq v0, KEY_L, _west
	j _break

	_north:
		# invalid moves
		beq t0, DIR_N, _break # already facing north
		beq t0, DIR_S, _break # facing opposite direction, illegal

		# set new direction
		li t0, DIR_N
		sw t0, snake_dir
		j _new_dir

	_south:
		# invalid moves
		beq t0, DIR_S, _break # already facing south
		beq t0, DIR_N, _break # facing opposite direction, illegal

		# set new direction
		li t0, DIR_S
		sw t0, snake_dir
		j _new_dir

	_east:
		# invalid moves
		beq t0, DIR_E, _break # already facing east
		beq t0, DIR_W, _break # facing opposite direction, illegal

		# set new direction
		li t0, DIR_E
		sw t0, snake_dir
		j _new_dir

	_west:
		# invalid moves
		beq t0, DIR_W, _break # already facing west
		beq t0, DIR_E, _break # facing opposite direction, illegal

		# set new direction
		li t0, DIR_W
		sw t0, snake_dir
		j _new_dir

	_new_dir:
		li t0, 1
		sw t0, snake_dir_changed

	_break:
leave

# ------------------------------------------------------------------------------------------------

update_snake:
enter
	lw t0, snake_move_timer
	_if: # check if time is up
		beq t0, 0, _else
		
		# pause between moves
		sub t0, t0, 1
		sw t0, snake_move_timer

		j _break
	_else:
		# reset
		li t0, SNAKE_MOVE_DELAY
		sw t0, snake_move_timer

		li t0, 0
		sw t0, snake_dir_changed

		# move the snake
		jal move_snake
	_break:
leave

# ------------------------------------------------------------------------------------------------

move_snake:
enter s0, s1
	# compute next position
	jal compute_next_snake_pos
	move s0, v0
	move s1, v1

	# check if (x,y) outside of grid
	li t0, GRID_WIDTH
	blt s0, 0, _game_over
	bge s0, t0, _game_over

	li t0, GRID_HEIGHT
	blt s1, 0, _game_over
	bge s1, t0, _game_over

	# check if intersecting itself
	move a0, s0
	move a1, s1
	jal is_point_on_snake
	beq v0, 1, _game_over
	
	# check if intersecting apple (x and y)
	lw t0, apple_x
	bne s0, t0, _move_forward
	lw t0, apple_y
	bne s1, t0, _move_forward
	j _eat_apple

	_game_over: # outside of the grid
		# set lost_game to True
		li t1, 1
		sw t1, lost_game
		j _break

	_eat_apple:
		# increment apples eaten and snake length
		lw t0, apples_eaten
		add t0, t0, 1
		sw t0, apples_eaten

		lw t0, snake_len
		add t0, t0, 1
		sw t0, snake_len

		# update snake segment coordinates
		jal shift_snake_segments

		# update snake head coordinates
		sb s0, snake_x
		sb s1, snake_y

		# move the apple
		jal move_apple

		j _break
	
	_move_forward: # legal move
		# update snake segment coordinates
		jal shift_snake_segments

		# update snake head coordinates
		sb s0, snake_x
		sb s1, snake_y

	_break:
leave s0, s1

# ------------------------------------------------------------------------------------------------

shift_snake_segments:
enter
	lw t0, snake_len
	sub t0, t0, 1 # i = snake_len -1
	_for: # i >= 1
		blt t0, 1, _break

		# snake_x[i] = snake_x[i - 1]
		sub t1, t0, 1 # [i - 1]
		lb t1, snake_x(t1)

		sb t1, snake_x(t0)

		# snake_y[i] = snake_y[i - 1]
		sub t1, t0, 1 # [i - 1]
		lb t1, snake_y(t1)

		sb t1, snake_y(t0)

		# increment loop
		sub t0, t0, 1
		j _for
	_break:

leave

# ------------------------------------------------------------------------------------------------

move_apple:
enter
	_loop:
		# Generate random x and y
		li a0, 0
		li a1, GRID_WIDTH
		li v0, 42
		syscall
		move s0, v0

		li a0, 0
		li a1, GRID_HEIGHT
		li v0, 42
		syscall
		move s1, v0

		# check if intersecting snake
		move a0, s0
		move a1, s1
		jal is_point_on_snake
		beq v0, 1, _loop # intersects snake
	
	sw s0, apple_x
	sw s1, apple_y
leave

# ------------------------------------------------------------------------------------------------

compute_next_snake_pos:
enter
	lw t9, snake_dir

	# v0 = direction_delta_x[snake_dir]
	lb v0, snake_x
	lb t0, direction_delta_x(t9)
	add v0, v0, t0

	# v1 = direction_delta_y[snake_dir]
	lb v1, snake_y
	lb t0, direction_delta_y(t9)
	add v1, v1, t0
leave # return v0, v1

# ------------------------------------------------------------------------------------------------

# a0 = x, a1 = y
# returns if coordinate is on the snake
is_point_on_snake:
enter
	# for i = 0 to snake_len
	li t9, 0
	_loop:
		lb t0, snake_x(t9)
		bne t0, a0, _differ
		lb t0, snake_y(t9)
		bne t0, a1, _differ # check if on snake
			# coordinate on snake
			li v0, 1
			j _return

		_differ:
		
		# increment
		add t9, t9, 1
		lw  t0, snake_len
		blt t9, t0, _loop
	
	# coordinate not on snake
	li v0, 0
_return:
leave # return v0


# ------------------------------------------------------------------------------------------------
# Drawing functions
# ------------------------------------------------------------------------------------------------

draw_all:
enter
	# check if lost
	lw t0, lost_game
	bne t0, 0, _return
		# draw
		jal draw_snake
		jal draw_apple
		jal draw_hud

_return:
leave

# ------------------------------------------------------------------------------------------------

draw_snake:
enter
	li s0, 0 # i
	_for: # i < snake_len
		lw t0, snake_len
		bge s0, t0, _break_for

		# a0 = snake_x[s0] * grid_cell_size
		lb a0, snake_x(s0)
		mul a0, a0, GRID_CELL_SIZE

		# a1 = snake_y[s0] * grid_cell_size
		lb a1, snake_y(s0)
		mul a1, a1, GRID_CELL_SIZE

		# check if head of snake
		bne s0, zero, _else # s0 == 0
			# a2 = tex_snake_head[snake_dir]
			lw t0, snake_dir
			mul t0, t0, WORD_SIZE
			lw a2, tex_snake_head(t0) # ### why not la??

			j _break_if
		_else:
			la a2, tex_snake_segment
		
		_break_if:
		
		# blit segment
		jal display_blit_5x5_trans # blit segment

		# increment loop
		add s0, s0, 1 # s0++
		j _for
	_break_for:
leave

# ------------------------------------------------------------------------------------------------

draw_apple:
enter
	# apple coordinates
	lw t0, apple_x
	mul a0, t0, GRID_CELL_SIZE
	lw t0 apple_y
	mul a1, t0, GRID_CELL_SIZE

	# texture
	la a2, tex_apple

	jal display_blit_5x5_trans
leave

# ------------------------------------------------------------------------------------------------

draw_hud:
enter
	# draw a horizontal line above the HUD showing the lower boundary of the playfield
	li  a0, 0
	li  a1, GRID_HEIGHT
	mul a1, a1, GRID_CELL_SIZE
	li  a2, DISPLAY_W
	li  a3, COLOR_WHITE
	jal display_draw_hline

	# draw apples collected out of remaining
	li a0, 1
	li a1, 58
	lw a2, apples_eaten
	jal display_draw_int

	li a0, 13
	li a1, 58
	li a2, '/'
	jal display_draw_char

	li a0, 19
	li a2, 58
	li a2, APPLES_NEEDED
	jal display_draw_int
leave
