# author Jacob Sharp

# Directions
.eqv DIR_0	0 # use zero register
.eqv DIR_N	1
.eqv DIR_E	2
.eqv DIR_S	3
.eqv DIR_W	4

# Grid
.eqv GRID_CELL_SIZE 5 # pixels
.eqv GRID_WIDTH  13 # cells
.eqv GRID_HEIGHT 11 # cells
.eqv GRID_CELLS 132 # = GRID_WIDTH * GRID_HEIGHT

# Moves
.eqv MAX_MOVES 200

# MIPS
.eqv BYTE_SIZE 1

# ------------------------------------------------------------------------------------------------

.data
	lost_game: .byte 0 # 1 if player lost game
	moves_taken: .word 0
	
	# A pair of arrays, indexed by direction, to turn a direction into x/y deltas.
	# e.g. direction_delta_x[DIR_E] is 1, because moving east increments X by 1.
	#                        N/A  N  E  S  W
	direction_delta_x: .byte  0   0  1  0 -1
	direction_delta_y: .byte  0  -1  0  1  0

.text

# ------------------------------------------------------------------------------------------------

.include "../utilities/display.asm"

.include "sokoban_player.asm"
.include "sokoban_blocks.asm"
.include "sokoban_levels.asm"
.include "sokoban_textures.asm"

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


# ------------------------------------------------------------------------------------------------
# ----------------------------------  Drawing  ---------------------------------------------------
# ------------------------------------------------------------------------------------------------

# displays on MIPS Keypad and LED Simulator the game of Soku
draw_all:
	push_state
	
	jal draw_level
	jal draw_blocks
	jal draw_player
	jal draw_hud
	
	pop_state
	jr ra


# displays on Simulator the heads up showing the move count
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

# ------------------------------------------------------------------------------------------------
# ----------------------------------  Input  -----------------------------------------------------
# ------------------------------------------------------------------------------------------------
	
# checks for the arrow keys to change the player's direction
# updates player_dir to match key pressed
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


# a0 - x-coordinate (byte)
# a1 - y-coordinate (byte)
# v0, v1 - x and y coordinates of destination
compute_next_pos:
	push_state
	
	lw t0, player_dir

	# v0 = direction_delta_x[player_dir]
	lb t1, direction_delta_x(t0)
	add v0, a0, t1

	# v1 = direction_delta_y[player_dir]
	lb v1, player_y
	lb t1, direction_delta_y(t0)
	add v1, a1, t1
	
	pop_state
	jr ra


# ------------------------------------------------------------------------------------------------
# ----------------------------------  Game Logic  ------------------------------------------------
# ------------------------------------------------------------------------------------------------

# checks if the game is over
# returns 1 when game is over, 0 otherwise
check_game_over:
	push_state
	
	_targets:
	# check if all blocks are on target
	jal check_blocks_on_targets
	beq v0, 0, _continue_game
		j _end_game # all blocks are on the targets
	
	# game continues
	_continue_game:
		li v0, 0
		j _return
	
	_end_game:
		li v0, 1
	
	_return:
	pop_state
	jr ra

# check if (x,y) outside of grid
# a0 - x-coord of location
# a1 - y-coord of location
# returns 1 if outside the grid or 0 otherwise
check_outside_grid:
	push_state
	
	# check if outside bounds
	li t0, GRID_WIDTH
	blt a0, 0, _invalid_move
	bge a0, t0, _invalid_move
	
	li t0, GRID_HEIGHT
	blt s1, 0, _invalid_move
	bge s1, t0, _invalid_move
	
	j _valid_move
	
	_invalid_move:
		li v0, 1
		j _return
	
	_valid_move:
		li v0, 0
	
	_return:
	pop_state
	jr ra


# ------------------------------------------------------------------------------------------------
# ----------------------------------  Game Messages  ---------------------------------------------
# ------------------------------------------------------------------------------------------------

# displays on Simulator message on how to start the game
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
	la_string	a2, "-> key"
	jal	display_draw_text
	li	a0, 5
	li	a1, 36
	la_string	a2, "to begin"
	jal	display_draw_text
	
	pop_state
	jr ra

# shows on Simulator a game over message
show_game_over_message:
	push_state
	
	# clear display
	jal display_update_and_clear

	# check if game was lost
	lb t0, lost_game
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
