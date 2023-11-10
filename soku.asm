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
	
	# player
	player_x: .byte 2
	player_y: .byte 2
	player_dir: .word 0
	
	# A pair of arrays, indexed by direction, to turn a direction into x/y deltas.
	# e.g. direction_delta_x[DIR_E] is 1, because moving east increments X by 1.
	#                        N/A  N  E  S  W
	direction_delta_x: .byte  0   0  1  0 -1
	direction_delta_y: .byte  0  -1  0  1  0

.text
	
# ------------------------------------------------------------------------------------------------

.include "utilities/display.asm"
.include "utilities/soku_textures.asm"
.include "utilities/soku_levels.asm"
		
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
# ----------------------------------  Movement  --------------------------------------------------
# ------------------------------------------------------------------------------------------------


# moves the player legally based on arrow pressed arrow keys
move_player:
	# check if a key was pressed
	lw t0, player_dir
	beq zero, t0, _return
	
	push_state s0, s1, s2, s3
	
	# compute next position
	lb a0, player_x
	lb a1, player_y
	jal compute_next_pos
	move s0, v0 # new x-coord
	move s1, v1 # new y-coord
	
	# check if (x,y) outside of grid
	move a0, s0
	move a1, s1
	jal check_outside_grid
	beq v0, 1, _skip_move
	
	# check if wall collision
	move a0, s0
	move a1, s1
	jal check_wall_collision
	beq v0, 1, _skip_move
	
	# check if block collision
	move a0, s0
	move a1, s1
	jal check_block_collision
	beq v0, 0, _move_forward
		# block collision occurred		
	
		# compute block's new location if pushed
		move a0, s0
		move a1, s1
		jal compute_next_pos
		move s2, v0 # block's new x-coord
		move s3, v1 # block's new y-coord
		
		# check if (x,y) outside of grid
		move a0, s2
		move a1, s3
		jal check_outside_grid
		beq v0, 1, _skip_move
		
		# check if wall collision
		move a0, s2
		move a1, s3
		jal check_wall_collision
		beq v0, 1, _skip_move
		
		# check if block in the path
		move a0, s2
		move a1, s3
		jal check_block_collision
		beq v0, 1, _skip_move
		
		# move block
		move a0, s0
		move a1, s1
		move a2, s2
		move a3, s3
		jal move_block
	
	_move_forward: # legal move
		# update player coordinates
		sb s0, player_x
		sb s1, player_y
		
		# track the move
		lw t0, moves_taken
		increment t0
		sw t0, moves_taken
	
	_skip_move:
	# reset player direction
	sw zero, player_dir
	
	pop_state s0, s1, s2, s3
		
	_return:
	jr ra

# moves a block to a new location
# a0 - x-coord of location
# a1 - y-coord of location
# a2 - new x-coord
# a3 - new y-coord
move_block:
	push_state s0, s1, s2, s3, s4, s5
	move s4, a0 #TODO change to s0/s1 and minimize saved regs
	move s5, a1
	move s6, a2
	move s7, a3
	
	# determine number of blocks
	la s0, array_of_blocks
	lb s1, (s0) # number of blocks
	
	# update specific block
	addi s0, s0, BYTE_SIZE
	li s2, 0 # i
	_loop:
	bge s2, s1, _loop_end
		mul s3, s2, 3 # block start located at [3i]
		
		# block x and y coordinates
		move a0, s0
		move a1, s3
		jal array_element_address
		move t0, v0
		lb t2, (t0) # x-coord
		
		addi t1, v0, BYTE_SIZE
		lb t3, (t1) # y-coord
		
		# check for block
		bne s4, t2, _next_block
		bne s5, t3, _next_block
		
			# block at coordinates
			sb s6, (t0)
			sb s7, (t1)
			
			# check if landed on/ moved off of a target
			move s1, t1 # save
			
			move a0, s6
			move a1, s7
			jal check_target_location
			
			# update block's is_on_target
			addi t0, t1, BYTE_SIZE
			sb v0, (t0)
			
			j _loop_end
		
		# check next block
		_next_block:
		increment s2
		j _loop
	
	_loop_end:
	pop_state s0, s1, s2, s3, s4, s5
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


# displays on Simulator the map's walls and targets
draw_level:
	push_state s0, s1, s2
	
	# draw each component for the current level
	la s0, level
	li s1, 0 # i
	_matrix:
	bge s1, GRID_WIDTH, _matrix_end
		li s2, 0 # j
		_matrix_inner:
		bge s2, GRID_HEIGHT, _matrix_inner_end
			# level[i][j]
			move a0, s0
			move a1, s2
			move a2, s1
			li a3, GRID_WIDTH
			jal matrix_element_address
			lb t0, (v0)
			
			beq t0, 0, _next_spot
			
			# draw walls and targets
			beq t0, 1, _draw_wall
			beq t0, 2, _draw_target
			j _next_spot # ignore
				
			_draw_wall:
				# calculate the location
				mul a0, s1, GRID_CELL_SIZE
				mul a1, s2, GRID_CELL_SIZE
				
				# draw the wall
				la a2, tex_wall
				jal display_blit_5x5_trans
				
				j _next_spot
			
			_draw_target:
				# calculate the location
				mul a0, s1, GRID_CELL_SIZE
				mul a1, s2, GRID_CELL_SIZE
				
				# draw the target
				la a2, tex_target
				jal display_blit_5x5_trans
				
				j _next_spot
			
			# move to next
			_next_spot:
			increment s2
			j _matrix_inner

		_matrix_inner_end:
		
		# move to next row
		increment s1
		j _matrix
		
	_matrix_end:
	
	pop_state s0, s1, s2
	jr ra

# displays on Simulator the movable blocks
draw_blocks:
	push_state s0, s1, s2, s3
	
	# determine number of blocks
	la s0, array_of_blocks
	lb s1, (s0) # number of blocks
	
	# draw each block
	addi s0, s0, BYTE_SIZE
	li s2, 0 # i
	_loop:
	bge s2, s1, _loop_end
		mul s3, s2, 3 # block start located at [3i]
		
		# x and y coordinate
		move a0, s0
		move a1, s3
		jal array_element_address
		lb a0, (v0)
		mul a0, a0, GRID_CELL_SIZE
		
		addi v0, v0, BYTE_SIZE
		lb a1, (v0)
		mul a1, a1, GRID_CELL_SIZE
		
		# check if on target
		addi v0, v0, BYTE_SIZE
		lb t0, (v0)
		
		beq t0, 0, _not_on_target
			la a2, tex_block_on_target # block on target
			j _blit_block
		
		_not_on_target:
			la a2, tex_block # block not on target
		
		# draw the block
		_blit_block:
		jal display_blit_5x5_trans
		
		# move to next block
		increment s2
		j _loop
	
	_loop_end:
	
	pop_state s0, s1, s2, s3
	jr ra
	
# displays on Simulator the user-controlled player
draw_player:
	push_state
	
	# calculate the location
	lb t0, player_x
	mul a0, t0, GRID_CELL_SIZE
	lb t0 player_y
	mul a1, t0, GRID_CELL_SIZE

	# draw the player
	la a2, tex_player
	jal display_blit_5x5_trans
	
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
# ----------------------------------  Calculations  ----------------------------------------------
# ------------------------------------------------------------------------------------------------
	
# checks for the arrow keys to change the player's direction
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


# checks that all blocks are located on a target #--------------------------------------------------------------------------------------------------------------------
# returns 1 when they are all on targets, 0 otherwise
check_blocks_on_targets:
	push_state s0, s1, s2, s3
	
	# determine number of blocks
	la s0, array_of_blocks
	lb s1, (s0) # number of blocks
	
	# draw each block
	addi s0, s0, BYTE_SIZE
	li s2, 0 # i
	_loop:
	bge s2, s1, _loop_end
		mul s3, s2, 3 # block start located at [3i]
		
		# calculate the block struct address
		move a0, s0
		move a1, s3
		jal array_element_address
		
		# check if on target
		li t0, BYTE_SIZE
		mul t0, t0, 2
		add v0, v0, t0 # located 2 bytes
		lb t0, (v0)
		
		beq t0, 0, _not_on_target
			j _next_block
		
		# move to next block
		_next_block:
		increment s2
		j _loop
	
	_loop_end:
	
	# all blocks are on targets
	li v0, 1
	j _return
	
	_not_on_target:
		li v0, 0
	
	_return:
	pop_state s0, s1, s2, s3
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


# check if a wall is located at (x,y)
# a0 - x-coord of location
# a1 - y-coord of location
# returns 1 if there is a wall, 0 otherwise
check_wall_collision:
	push_state
	
	move t0, a0
	move t1, a1
	
	# find grid value
	la a0, level
	move a1, t1 # y axis
	move a2, t0 # x axis
	li a3, GRID_WIDTH
	jal matrix_element_address
	lb v0, (v0)
	
	# check if it is a wall
	beq v0, 1, _wall
		li v0, 0
		j _return
	
	_wall:
		li v0, 1
	
	_return:
	pop_state
	jr ra


# check if a target is located at (x,y)
# a0 - x-coord of location
# a1 - y-coord of location
# returns 1 if there is a target, 0 otherwise
check_target_location:
	push_state
	
	# level[i][j]
	move a2, a0 # a1: y-coord, a2: x-coord
	la a0, level
	li a3, GRID_WIDTH
	jal matrix_element_address
	lb v0, (v0)
	
	# check if it is a target
	beq v0, 2, _target
		li v0, 0
		j _return
	
	_target:
		li v0, 1
	
	_return:
	pop_state
	jr ra


# check if a block is at the coordinates
# a0 - x-coord of location
# a1 - y-coord of location
# returns 1 when there is a block at the coordinates, 0 otherwise
check_block_collision:
	push_state s0, s1, s2, s3, s4, s5
	move s4, a0 #TODO change to s0/s1 and minimize saved regs
	move s5, a1
	
	# determine number of blocks
	la s0, array_of_blocks
	lb s1, (s0) # number of blocks
	
	# draw each block
	addi s0, s0, BYTE_SIZE
	li s2, 0 # i
	_loop:
	bge s2, s1, _loop_end
		mul s3, s2, 3 # block start located at [3i]
		
		# block x and y coordinates
		move a0, s0
		move a1, s3
		jal array_element_address
		lb t0, (v0) # x-coord
		
		addi v0, v0, BYTE_SIZE
		lb t1, (v0) # y-coord
		
		# check for block
		bne s4, t0, _next_block
		bne s5, t1, _next_block
		
			# block at coordinates
			li v0, 1
			j _return
		
		# check next block
		_next_block:
		increment s2
		j _loop
	
	_loop_end:
	li v0, 0
	
	_return:
	pop_state s0, s1, s2, s3, s4, s5
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


# ------------------------------------------------------------------------------------------------
# ----------------------------------  Indexing  --------------------------------------------------
# ------------------------------------------------------------------------------------------------
	
# This function calculates the address an element in a array of words
# Inputs:
#	 a0: The base address of the array
#	 a1: The index of the element
# Outputs:
#	 v0: The address of the element
array_element_address:
	mul t0, a1, BYTE_SIZE # offset
	add v0, a0, t0
	jr ra

# Calculates the address of the element (i, j) in a matrix of words
# Inputs:
#	 a0: The base address of the matrix
#	 a1: The index (i) of the row
#	 a2: The index (j) of the column
#	 a3: The number of elements in a row
# Outputs:
#	 v0: The address of the element
matrix_element_address:
	mul v0, a3, BYTE_SIZE
	mul v0, a1, v0 			# [i][0]
	mul t0, a2, BYTE_SIZE	# [0][j]
	add v0, v0, t0			# [i][j]
	add v0, a0, v0			# a[i][j]
	jr ra
