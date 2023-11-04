# author Luis Oliveira - provided as a project resource

.include "macros.asm"

.globl handle_input


.text

# Input Handling Function
# -----------------------------------------------------

# handle_input()
#   Sets the variable contents according with button states.

handle_input:
	push_state

	# Get the key state memory
	jal	input_get_keys_held
	move	t1, v0

	# Check for key states
	and	t2, t1, 0x1
	sw	t2, up_pressed

	srl	t1, t1, 1
	and	t2, t1, 0x1
	sw	t2, down_pressed

	srl	t1, t1, 1
	and	t2, t1, 0x1
	sw	t2, left_pressed

	srl	t1, t1, 1
	and	t2, t1, 0x1
	sw	t2, right_pressed

	srl	t1, t1, 1
	and	t2, t1, 0x1
	sw	t2, b_pressed

	srl	t1, t1, 1
	and	t2, t1, 0x1
	sw	t2, z_pressed

	srl	t1, t1, 1
	and	t2, t1, 0x1
	sw	t2, x_pressed

	srl	t1, t1, 1
	and	t2, t1, 0x1
	sw	t2, c_pressed

	move	v0, t2


	pop_state
	jr ra
