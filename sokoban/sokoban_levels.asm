# author Jacob Sharp

.globl draw_level
.globl check_wall_collision
.globl check_target_location

.globl level

# ------------------------------------------------------------------------------------------------

.data
	# byte matrix for each 5x5 box to display
	# boxes are one of the following
	#		0: nothing
	#		1: wall
	#		2: target
	level:
		.byte	1 1 1 1 1 1 1 0 0 0 0 0 0
		.byte	1 0 0 0 0 0 1 0 0 0 0 0 0
		.byte	1 0 2 0 2 0 1 0 0 0 0 0 0
		.byte	1 0 0 1 0 0 1 0 0 0 0 0 0
		.byte	1 0 2 0 2 0 1 0 0 0 0 0 0
		.byte	1 0 0 1 0 0 1 0 0 0 0 0 0
		.byte	1 0 2 0 2 0 1 0 0 0 0 0 0
		.byte	1 0 0 1 0 0 0 1 0 0 0 0 0
		.byte	1 0 2 0 2 0 0 1 0 0 0 0 0
		.byte	1 0 0 0 0 0 1 0 0 0 0 0 0
		.byte	1 1 1 1 1 1 1 0 0 0 0 0 0

.text

# ------------------------------------------------------------------------------------------------

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