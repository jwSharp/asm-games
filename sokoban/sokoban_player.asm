# author Jacob Sharp

.globl move_player
.globl draw_player

.globl player_x
.globl player_y
.globl player_dir

# ------------------------------------------------------------------------------------------------

.data
	player_x: .byte 1
	player_y: .byte 1
	player_dir: .word 0
	
.text

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
