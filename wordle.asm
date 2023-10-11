# author Jacob Sharp

.include "macros.asm"

.data
	user_guess: .asciiz "01234"
.text

.eqv GUESS_SIZE 6 # 5 letters

.globl main
main:
	_opening:
		jal print_opening_message
		
		# prompt user response
		input_int
		beq v0, 2, _exit
		bne v0, 1, _opening
	
	_guess:
		print_str "Guess a word\t"
		la a0, user_guess
		li a1, GUESS_SIZE
		li v0, 8
		syscall
	
	_exit:
		exit



print_opening_message:
	push_state
	
	println_str "===================================================="
	println_str "Welcome to that one game that the newspaper owns now"
	println_str "===================================================="
	
	println_str "Would you like to get started?"
	println_str "\t(1) Play"
	println_str "\t(2) Quit"
	
	pop_state
	jr ra