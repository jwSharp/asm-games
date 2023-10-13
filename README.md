# Description

This is a collection of games created using MIPS assembly language. Descriptions of each game are below.

## Wordle

This game is based on that one game now owned by that one newspaper. The user attempts to guess the secret word.

Words are five letters long. The user guesses up to five times. When a word is guessed, the program will give feedback. Letters will be displayed as described below:

1. Correct Position:
   A letter placed in the correct position will be surrounded by square brackets.

   ```
   guess:  a
   out:    [a]
   ```

2. Incorrect Position:
   A letter that is in the word but in the wrong position will be surrounded by parenthesis.

   ```
   guess:  a
   out:    (a)
   ```

3. Incorrect Letter:
   A letter that does not exist anywhere in the word will not have a modification.

   ```
   guess:  a
   out:    a
   ```

All five letters of the user's guess are displayed using the above format. The user wins when they correctly guess the entire word.

## Snake

This game is based on the age-old game Snake. The user controls the snake and tries to eat enough apples.

The snake grows when it eats an apple. The snake is constantly in motion, and the user is tasked with guidance. The user loses when the snake:

- collides with its own body
- slithers off the grid

The user wins the snake reaches a certain size.

# Requirements

In order to run the game, use the version of Mars in the .jar file provided.
