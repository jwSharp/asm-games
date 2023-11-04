# author Luis Oliveira - provided as a project resource

.include "macros.asm"

.globl up_pressed
.globl down_pressed
.globl left_pressed
.globl right_pressed
.globl b_pressed
.globl z_pressed
.globl x_pressed
.globl c_pressed

# The status of each button I use
.data

up_pressed:	.word	0
down_pressed:	.word	0
left_pressed:	.word	0
right_pressed:	.word	0
b_pressed:	.word	0
z_pressed:	.word	0
x_pressed:	.word	0
c_pressed:	.word	0
