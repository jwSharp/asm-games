# author Jacob Sharp

.include "macros.asm"

.data
	user_guess:	.asciiz "abcde"
	word:		.asciiz "tests"
.text

.eqv WORD_LENGTH 5 # 5 letters
.eqv MAX_GUESSES 5

.globl main
main:
	jal print_opening_message
	
	_opening:
		jal print_play_prompt
		
		# prompt user to continue
		input_int
		beq v0, 2, _exit			# input() == 2
		bne v0, 1, _opening			# input() == 1

		li s0, 0
		_guess:
			# check if user has guesses left
			bge s0, MAX_GUESSES, _loss		# i < max

			# prompt user guess
			print_str "\nGuess a word\t"
			la a0, user_guess
			li a1, WORD_LENGTH
			increment a1 # terminator
			li v0, 8
			syscall							# user_guess = input() limited to size of word_length + 1
			print_newline

			# print out which letters were correct
			la a0, user_guess
			la a1, word
			jal compare_words
			
			# check accuracy
			beq v0, 1, _win					# compare_words() == 1
			
			# go to next guess
			increment s0
			j _guess
		
	_loss:
		la a0, word
		jal print_loss_message
		
		j _opening
	
	_win:
		la a0, word
		jal print_win_message
		
		j _opening
	
	_exit:
		exit




# ------------------------
# - Check Guess Accuracy -
# ------------------------

# a0 - address of user guess
# a1 - address of correct word
# v0 - 1 if word was correct, 0 otherwise
compare_words:
	push_state s0, s1, s2, s3
	move s0, a0 # user guess safe
	move s1, a1 # correct word safe
	
	# loop through letters
	li s2, 0
	_guess_word_loop:
		bge s2, 5, _end_guess_loop
		
		# convert letter to lower case and store it in the guess
		add t0, s0, s2
		lb t0, 0(t0)
		
		move a0, t0
		jal lower
		
		add t0, s0, s2
		sb v0, 0(t0)
		
		# check if letter is in correct position
		add t0, s0, s2
		lb t0, 0(t0)
		
		add t1, s1, s2
		lb t1, 0(t1)
		
		bne t0, t1, _incorrect_location
			move a0, t0
			jal print_correct_location
			j _increment_guess
		
		
		
		# check if letter is in incorrect position
		_incorrect_location:
		li s3, 0
		_correct_word_loop:
			bge s3, 5, _increment_guess
			
			# load guess letter
			add t0, s0, s2
			lb t0, 0(t0)
			
			# load correct letter
			add t1, s1, s3
			lb t1, 0(t1)
			
			# check if letters are the same
			bne t0, t1, _incorrect_letter
				move a0, t0
				jal print_incorrect_location
				j _increment_guess
			

			_incorrect_letter:
			# print letter when it is the final letter
			blt s3, 4, _increment_correct
				print_char t0
			
			# next letter
			_increment_correct:
			increment s3
			j _correct_word_loop
		
		
		
		_increment_guess:
			increment s2
			j _guess_word_loop
	_end_guess_loop:
	
	pop_state s0, s1, s2, s3
	jr ra

# a0 - an ascii letter
# v0 - the lowercase equivalent letter
# invalid letters give invalid responses
lower:
	push_state
	
	# change to lower (does not affect already lower case letters)
	li a1, 5
	jal set_bit
	
	pop_state
	jr ra


#TODO move to functions
# a0 - letter to check
check_correct_position:
	jr ra

# a0 - letter to check
check_incorrect_position:
	jr ra



# --------------------
# - Bit Manipulation -
# --------------------

# a0 - bitfield
# a1 - bit index
# v0 - modified bitfield
set_bit:
	push_state
	
	li t0, 0x1 # mask
	sllv t0, t0, a1
	or v0, a0, t0
	
	pop_state
	jr ra



# ---------------------------
# - User Interface Messages -
# ---------------------------

print_opening_message:
	push_state
	
	println_str "===================================================="
	println_str "Welcome to that one game that the newspaper owns now"
	println_str "===================================================="
	
	pop_state
	jr ra


print_play_prompt:
	push_state
	println_str "\nWould you like to get started?"
	println_str "\t(1) Play"
	println_str "\t(2) Quit"
	
	pop_state
	jr ra

# a0 - correct word
print_loss_message:
	move s0, a0
	push_state
	
	println_str "\n\nUnlucky. You did not guess the word"
	print_str	"The correct word was: "
	print_strv s0
	
	pop_state
	jr ra

# a0 - correct word
print_win_message:
	move s0, a0
	push_state
	
	println_str "\n\nWell done chap! Your answer was correct."
	print_str	"The word was: "
	print_strv s0
	
	pop_state
	jr ra
	
# a0 - a letter
print_correct_location:
	push_state
	
	print_chari '['
	print_char a0
	print_chari ']'
	
	pop_state
	jr ra

# a0 - a letter
print_incorrect_location:
	push_state
	
	print_chari '('
	print_char a0
	print_chari ')'
	
	pop_state
	jr ra