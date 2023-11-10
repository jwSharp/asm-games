# author Jacob Sharp

.globl move_block
.globl draw_blocks
.globl check_blocks_on_targets
.globl check_block_collision

.globl array_of_blocks

# ------------------------------------------------------------------------------------------------

.data
	# first byte is number of blocks
	# blocks are 3 bytes each
	#		block x-coord
	#		block y-coord
	#		block is_on_target
	array_of_blocks:
		.byte 8
	
		.byte 3
		.byte 2
		.byte 0
		
		.byte 2
		.byte 3
		.byte 0

		.byte 4
		.byte 3
		.byte 0
		
		.byte 3
		.byte 4
		.byte 0
		
		.byte 3
		.byte 6
		.byte 0
		
		.byte 2
		.byte 7
		.byte 0
		
		.byte 4
		.byte 7
		.byte 0

		.byte 3
		.byte 8
		.byte 0

.text

# ------------------------------------------------------------------------------------------------


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



# checks that all blocks are located on a target
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