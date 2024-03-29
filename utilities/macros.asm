# author Jacob Sharp

# ---------- INDEXING ----------
.eqv BYTE_SIZE 1
.eqv WORD_SIZE 4

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


# ---------- PRINTING ----------

# Prints a newline.
.macro print_newline
	print_chari '\n'
.end_macro

# Prints a single character from a register
.macro print_char (%char)
	push v0
	push a0
	
	move a0, %char
	li v0, 11
	syscall
	
	pop a0
	pop v0
.end_macro

# Prints a single character from a literal
.macro print_chari (%char)
	push v0
	push a0
	
	li a0, %char
	li v0, 11
	syscall
	
	pop a0
	pop v0
.end_macro

# Prints a string.
.macro print_str (%str)
	push v0
	push a0
	
	.data
	temp: .asciiz %str
	
	.text
	la a0, temp
	li v0, 4
	syscall
	
	pop a0
	pop v0
.end_macro

# Prints a string followed by a newline.
.macro println_str (%str)
	print_str %str
	print_newline
.end_macro

.macro la_string %dest, %str
	.data
	temp: .asciiz %str
	.text
	la %dest, temp
.end_macro

# Prints a string from a register.
.macro print_strv (%str)
	push v0
	
	li v0, 4
	syscall
	
	pop v0
.end_macro

# Prints a string from a register followed by a newline.
.macro println_strv (%str)
	print_strv %str
	print_newline
.end_macro

# Loads the address of a string.
.macro la_string %dest, %str
	.data
	temp: .asciiz %str
	.text
	la %dest, temp
.end_macro

# Prints an integer form a register
.macro print_int (%int)
	push v0
	push a0
	
	add a0, zero, %int
	li v0, 1
	syscall
	
	pop a0
	pop v0
.end_macro

# Prints an integer from a literal
.macro print_inti (%int)
	push v0
	push a0
	
	lw a0, %int
	li v0, 1
	syscall
	
	pop a0
	pop v0
.end_macro

# Prints an integer in hexidecimal from a register
.macro print_hex (%int)
	push v0
	push a0

	add a0, zero, %int
	li v0, 34
	syscall
		
	pop a0
	pop v0
.end_macro


# ---------- INPUT ----------

# Prompt integer input. Stored in v0.
.macro input_int
	li v0, 5
	syscall
.end_macro

# Prompt string input. Stored at %destination of length %length.
.macro input_str (%destination, %length)
	add a0, zero, %destination
	li a1, %length
	li v0, 8
	syscall
.end_macro
	


# ---------- FUNCTIONS ----------

# Push ra to the stack.
.macro push_state
	addi sp, sp, -4
	sw ra, 0(sp)
.end_macro

# Push ra and s0 to the stack.
.macro push_state %s0
	addi sp, sp, -8
	sw ra, 0(sp)
	sw %s0, 4(sp)
.end_macro

# Push ra and s0-s1 to the stack.
.macro push_state (%s0, %s1)
	addi sp, sp, -12
	sw ra, 0(sp)
	sw %s0, 4(sp)
	sw %s1, 8(sp)
.end_macro

# Push ra and s0-s2 to the stack.
.macro push_state (%s0, %s1, %s2)
	addi sp, sp, -16
	sw ra, 0(sp)
	sw %s0, 4(sp)
	sw %s1, 8(sp)
	sw %s2, 12(sp)
.end_macro

# Push ra and s0-s3 to the stack.
.macro push_state (%s0, %s1, %s2, %s3)
	addi sp, sp, -20
	sw ra, 0(sp)
	sw %s0, 4(sp)
	sw %s1, 8(sp)
	sw %s2, 12(sp)
	sw %s3, 16(sp)
.end_macro

# Push ra and s0-s4 to the stack.
.macro push_state (%s0, %s1, %s2, %s3, %s4)
	addi sp, sp, -24
	sw ra, 0(sp)
	sw %s0, 4(sp)
	sw %s1, 8(sp)
	sw %s2, 12(sp)
	sw %s3, 16(sp)
	sw %s4, 20(sp)
.end_macro

# Push ra and s0-s5 to the stack.
.macro push_state (%s0, %s1, %s2, %s3, %s4, %s5)
	addi sp, sp, -28
	sw ra, 0(sp)
	sw %s0, 4(sp)
	sw %s1, 8(sp)
	sw %s2, 12(sp)
	sw %s3, 16(sp)
	sw %s4, 20(sp)
	sw %s5, 24(sp)
.end_macro

# Push ra and s0-s6 to the stack.
.macro push_state (%s0, %s1, %s2, %s3, %s4, %s5, %s6)
	addi sp, sp, -32
	sw ra, 0(sp)
	sw %s0, 4(sp)
	sw %s1, 8(sp)
	sw %s2, 12(sp)
	sw %s3, 16(sp)
	sw %s4, 20(sp)
	sw %s5, 24(sp)
	sw %s6, 28(sp)
.end_macro

# Push ra and s0-s7 to the stack.
.macro push_state (%s0, %s1, %s2, %s3, %s4, %s5, %s6, %s7)
	addi sp, sp, -36
	sw ra, 0(sp)
	sw %s0, 4(sp)
	sw %s1, 8(sp)
	sw %s2, 12(sp)
	sw %s3, 16(sp)
	sw %s4, 20(sp)
	sw %s5, 24(sp)
	sw %s6, 28(sp)
	sw %s7, 32(sp)
.end_macro

# Pull ra from the stack.
.macro pop_state
	lw ra, 0(sp)
	addi sp, sp, 4
.end_macro

# Pull ra and s0 from the stack.
.macro pop_state (%s0)
	lw ra, 0(sp)
	lw %s0, 4(sp)
	addi sp, sp, 8
.end_macro

# Pull ra and s0-s1 from the stack.
.macro pop_state (%s0, %s1)
	lw ra, 0(sp)
	lw %s0, 4(sp)
	lw %s1, 8(sp)
	addi sp, sp, 12
.end_macro

# Pull ra and s0-s2 from the stack.
.macro pop_state (%s0, %s1, %s2)
	lw ra, 0(sp)
	lw %s0, 4(sp)
	lw %s1, 8(sp)
	lw %s2, 12(sp)
	addi sp, sp, 16
.end_macro

# Pull ra and s0-s3 from the stack.
.macro pop_state (%s0, %s1, %s2, %s3)
	lw ra, 0(sp)
	lw %s0, 4(sp)
	lw %s1, 8(sp)
	lw %s2, 12(sp)
	lw %s3, 16(sp)
	addi sp, sp, 20
.end_macro

# Pull ra and s0-s4 from the stack.
.macro pop_state (%s0, %s1, %s2, %s3, %s4)
	lw ra, 0(sp)
	lw %s0, 4(sp)
	lw %s1, 8(sp)
	lw %s2, 12(sp)
	lw %s3, 16(sp)
	lw %s4, 20(sp)
	addi sp, sp, 24
.end_macro

# Pull ra and s0-s5 from the stack.
.macro pop_state (%s0, %s1, %s2, %s3, %s4, %s5)
	lw ra, 0(sp)
	lw %s0, 4(sp)
	lw %s1, 8(sp)
	lw %s2, 12(sp)
	lw %s3, 16(sp)
	lw %s4, 20(sp)
	lw %s5, 24(sp)
	addi sp, sp, 28
.end_macro

# Pull ra and s0-s6 from the stack.
.macro pop_state (%s0, %s1, %s2, %s3, %s4, %s5, %s6)
	lw ra, 0(sp)
	lw %s0, 4(sp)
	lw %s1, 8(sp)
	lw %s2, 12(sp)
	lw %s3, 16(sp)
	lw %s4, 20(sp)
	lw %s5, 24(sp)
	lw %s6, 28(sp)
	addi sp, sp, 32
.end_macro

# Pull ra and s0-s7 from the stack.
.macro pop_state (%s0, %s1, %s2, %s3, %s4, %s5, %s6, %s7)
	lw ra, 0(sp)
	lw %s0, 4(sp)
	lw %s1, 8(sp)
	lw %s2, 12(sp)
	lw %s3, 16(sp)
	lw %s4, 20(sp)
	lw %s5, 24(sp)
	lw %s6, 28(sp)
	lw %s7, 32(sp)
	addi sp, sp, 36
.end_macro


# ---------- MATH ----------

.macro increment (%address)
	addi %address, %address, 1
.end_macro

.macro decrement (%address)
	addi %address, %address, -1
.end_macro

# Set v0 to a random integer
.macro random_int (%seed, %upper_bound)
	li a0, %seed
	li a1, %upper_bound
	li v0, 42
	syscall
.end_macro


# ---------- GENERAL ----------

# End the program.
.macro exit
	li v0, 10
	syscall
.end_macro

.macro time
	li v0, 30
	syscall
.end_macro
