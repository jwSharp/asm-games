# author Jacob Sharp

# Directions
.eqv DIR_N 0
.eqv DIR_E 1
.eqv DIR_S 2
.eqv DIR_W 3

# Grid
.eqv GRID_CELL_SIZE 5 # pixels
.eqv GRID_WIDTH  12 # cells
.eqv GRID_HEIGHT 11 # cells
.eqv GRID_CELLS 132 # = GRID_WIDTH * GRID_HEIGHT

# Moves
.eqv MAX_MOVES 20

# ------------------------------------------------------------------------------------------------

.data
	lost_game: .word 0 # 1 if player lost game
	moves_taken: .word 0
	
	# player
	player_x: .word 2
	player_y: .word 2
	player_dir: .word 0
	
	# grid
	level: .word
		0 0 1 1 1 1 1 0 0 0 0 0
		1 1 1 0 0 0 1 0 0 0 0 0
		1 3 5 2 0 0 1 0 0 0 0 0
		1 1 1 0 2 3 1 0 0 0 0 0
		1 3 1 1 2 0 1 1 0 0 0 0
		1 0 1 0 3 0 0 1 0 0 0 0
		1 2 0 4 2 2 3 1 0 0 0 0
		1 0 0 0 3 0 0 1 0 0 0 0
		1 1 1 1 1 1 1 1 0 0 0 0
		0 0 0 0 0 0 0 0 0 0 0 0
		0 0 0 0 0 0 0 0 0 0 0 0

.text
	
# ------------------------------------------------------------------------------------------------

.include "utilities/display.asm"
.include "utilities/soku_textures.asm"
		
.text

# ------------------------------------------------------------------------------------------------

.globl main
main:
	# pause for user to begin
	jal wait_for_game_start

	_game_loop:
		jal	check_input
		jal move_player
		jal draw_all
		jal display_update_and_clear
		jal wait_for_next_frame
		
		# check for loss
		jal check_game_over
		beq v0, 0, _game_loop

	jal show_game_over_message
	exit
	
	
# checks for the arrow keys to change the snake's direction.
check_input:
	push_state

	# determine which key was pressed
	jal input_get_keys_pressed
	beq v0, KEY_U, _north
	beq v0, KEY_D, _south
	beq v0, KEY_R, _east
	beq v0, KEY_L, _west
	j _break

	# set a new direction
	_north:
		li t0, DIR_N
		sw t0, player_dir
		j _break

	_south:
		li t0, DIR_S
		sw t0, player_dir
		j _break

	_east:
		li t0, DIR_E
		sw t0, player_dir
		j _break

	_west:
		li t0, DIR_W
		sw t0, player_dir
		j _break

	_break:
	pop_state
	jr ra
	
move_player:
	push_state
	
	# check if player needs to move
	la t0, player_dir
	lw t0, (t0)
	beq t0, zero, _break
	
	
	# determine direction of movement
	beq t0, DIR_N, _north
	beq t0, DIR_S, _south
	beq t0, DIR_E, _east
	beq t0, DIR_W, _west
	j _break # error if this happens

	# update the player location
	_north:
		lw t1, player_y
		decrement t1
		sw t1, player_y
		j _break

	_south:
		lw t1, player_y
		increment t1
		sw t1, player_y
		j _break

	_east:
		lw t1, player_x
		increment t1
		sw t1, player_x
		j _break

	_west:
		lw t1, player_x
		decrement t1
		sw t1, player_x
		j _break
	
	
	_break:
	sw zero, player_dir
	pop_state
	jr ra
	
move_block:
	push_state
	
	pop_state
	jr ra

draw_all:
	push_state
	
	jal draw_walls
	jal draw_targets
	jal draw_blocks
	jal draw_player
	jal draw_hud
	
	pop_state
	jr ra


draw_walls:
	push_state
	
	pop_state
	jr ra


draw_targets:
	push_state
	
	pop_state
	jr ra

draw_blocks:
	push_state
	
	pop_state
	jr ra
	

draw_player:
	push_state
	
	# player coordinates
	lw t0, player_x
	mul a0, t0, GRID_CELL_SIZE
	lw t0 player_y
	mul a1, t0, GRID_CELL_SIZE

	# texture
	la a2, tex_player

	jal display_blit_5x5_trans
	
	pop_state
	jr ra

draw_hud:
	push_state
	
	# draw a horizontal line above the HUD
	li  a0, 0
	li  a1, GRID_HEIGHT
	mul a1, a1, GRID_CELL_SIZE
	li  a2, DISPLAY_W
	li  a3, COLOR_WHITE
	jal display_draw_hline

	# draw moves taken
	li   a0, 1
	li   a1, 58
	la_string a2, "moves:"
	li   a3, COLOR_WHITE
	jal  display_draw_colored_text
	
	li a0, 45
	li a1, 58
	lw a2, moves_taken
	jal display_draw_int
	
	pop_state
	jr ra
	

# --------------------- Game Start and End ----------------
	
# returns 1 if the game is over
check_game_over:
	push_state
	
	li v0, 0

	# check user hit the maximum moves
	lw t0, moves_taken
	blt t0, MAX_MOVES, _endif
		li v0, 1
		j _return
	_endif:

	# update lost_game
	lw t0, lost_game
	beq t0, 0, _return
		li v0, 1
	
	_return: # return v0
	
	pop_state
	jr ra

show_game_over_message:
	push_state
	
	# clear display
	jal display_update_and_clear

	# check if game was lost
	lw t0, lost_game
	bne t0, 0, _lost
		# game won
		li   a0, 7
		li   a1, 25
		la_string a2, "Good job,"
		li   a3, COLOR_GREEN
		jal  display_draw_colored_text
		li   a0, 12
		li   a1, 31
		la_string a2, "u win :)"
		li   a3, COLOR_GREEN
		jal  display_draw_colored_text

		j _endif
	
	_lost:
		# game lost
		li   a0, 5
		li   a1, 30
		la_string a2, "oof, u lose"
		li   a3, COLOR_RED
		jal  display_draw_colored_text
	
	_endif:

	jal display_update_and_clear
	pop_state
	jr ra


# waits for the user to press a key to start the game
wait_for_game_start:
	push_state
	_loop: # while no keys are pressed
		jal show_game_start_message
		jal display_update_and_clear
		jal wait_for_next_frame
		jal input_get_keys_pressed
		beq v0, 0, _loop # != 0 when key pressed
	pop_state
	jr ra

show_game_start_message:
	push_state
	
	# draw underlined SOKU
	li	a0, 30
	li	a1, 5
	la_string	a2, "Soku!"
	jal	display_draw_text
	li  a0, 0
	li  a1, 15
	li  a2, DISPLAY_W
	li  a3, COLOR_LIGHT_GREY
	jal display_draw_hline
	
	# draw instructions to start
	li	a0, 5
	li	a1, 20
	la_string	a2, "press any"
	jal	display_draw_text
	li	a0, 10
	li	a1, 28
	la_string	a2, "key to"
	jal	display_draw_text
	li	a0, 20
	li	a1, 36
	la_string	a2, "begin"
	jal	display_draw_text
	
	pop_state
	jr ra
