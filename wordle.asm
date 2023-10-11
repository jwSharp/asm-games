# author Jacob Sharp

.include "macros.asm"

.data
	user_guess:	.asciiz "01234"
	word:		.asciiz "tests"
.text

.eqv GUESS_SIZE 6 # 5 letters
.eqv MAX_GUESSES 5

.globl main
main:
	jal print_opening_message
	
	_opening:
		jal print_play_prompt
		
		# prompt user to continue
		input_int
		beq v0, 2, _exit
		bne v0, 1, _opening

		li s0, 0
		_guess:
			# check if user has guesses left
			bge s0, MAX_GUESSES, _loss

			# prompt user guess
			print_str "Guess a word\t"
			la a0, user_guess
			li a1, GUESS_SIZE
			li v0, 8
			syscall				#TODO Write Macro
			print_newline
			
			# count guess towards total
			increment s0
			j _guess
		
	_loss:
		la a0, word
		lw a0, 0(a0)
		jal print_loss
		
		j _opening
	
	_win:
		la a0, word
		lw a0, 0(a0)
		jal print_win
	
	_exit:
		exit



# ------------
# - Printing -
# ------------

print_opening_message:
	push_state
	
	println_str "===================================================="
	println_str "Welcome to that one game that the newspaper owns now"
	println_str "===================================================="
	
	pop_state
	jr ra


print_play_prompt:
	push_state
	println_str "Would you like to get started?"
	println_str "\t(1) Play"
	println_str "\t(2) Quit"
	
	pop_state
	jr ra



# --------------------------
# - Wins and Loss Messages -
# --------------------------

# a0 - correct word
print_loss:
	move s0, a0
	push_state
	
	println_str "Unlucky. You did not guess the word"
	print_str	"The correct word was: "
	print_strv s0
	
	pop_state
	jr ra

# a0 - correct word
print_win:
	move s0, a0
	push_state
	
	println_str "Well done chap! Your answer was correct."
	print_str	"The word was: "
	print_strv s0
	
	pop_state
	jr ra