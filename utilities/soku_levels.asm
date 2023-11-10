# author Jacob Sharp

.data
	level:
	.byte	0 0 1 1 1 1 1 0 0 0 0 0 0
	.byte	1 1 1 0 0 0 1 0 0 0 0 0 0
	.byte	1 2 0 0 0 0 1 0 0 0 0 0 0
	.byte	1 1 1 0 0 2 1 0 0 0 0 0 0
	.byte	1 2 1 1 0 0 1 1 0 0 0 0 0
	.byte	1 0 1 0 2 0 0 1 0 0 0 0 0
	.byte	1 0 0 2 0 0 2 1 0 0 0 0 0
	.byte	1 0 0 0 2 0 0 1 0 0 0 0 0
	.byte	1 1 1 1 1 1 1 1 0 0 0 0 0
	.byte	0 0 0 0 0 0 0 0 0 0 0 0 0
	.byte	0 0 0 0 0 0 0 0 0 0 0 0 0

	# first byte is number of blocks
	# blocks are 3 bytes each
	#		block x-coord
	#		block y-coord
	#		block is_on_target
	array_of_blocks:
		.byte 7
	
		.byte 3
		.byte 2
		.byte 0
		
		.byte 4
		.byte 3
		.byte 0
		
		.byte 4
		.byte 4
		.byte 0
		
		.byte 1
		.byte 6
		.byte 0
		
		.byte 3
		.byte 6
		.byte 1
		
		.byte 4
		.byte 6
		.byte 0
		
		.byte 5
		.byte 6
		.byte 0
