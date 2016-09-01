# Student Name: Eric Klawitter
#
#     I c o n   M a t c h
#
#
# This routine determines which of eight candidate icons matches a pattern icon.
# This program finds the matching icon by comparing the location and value of non-black
# pixels in the reference icon to each candidate.
# The program loops through pixels in the pattern base until it finds a non-black pixel
# It will then compare that pixel and location to the same location in each candidate that is still valid
# Candidates are still valid as long as they match each non-black pixel found in the pattern
# $4 tracks the validity of each candidate in its first 8 bits.
# When a candidate is found to not match its corresponding bit in $4 is changed to a 1
# $7 contains a count of how many candidates must still be
# When $7 reaches 0 the program branches to the submit loop
# The submit loop shifts $4 until it finds the index of the 0 and then calls swi544 on that value

.data
CandBase: 	.alloc 1152
PatternBase:	.alloc 144

		#register allocation
		# $1 	pixel offset (x4) (0-572)
		# $2 	temp1
		# $3 	temp2
		# $4 	valid icons (first 8 bits, 1=invalid, 0=valid)
		# $5 	current candidate
		# $7 	num valid (initially 7)
		# $8 	constant 1 
		# $11 	constant 576

.text
IconMatch:	addi	$1, $0, CandBase		# point to base of Candidates
		swi	584				# generate puzzle icons
		
# your code goes here
		addi 	$1, $0, -4 			# initialize $1 (pixel offset) to -4 (1 before 1st pixel)
		addi	$4, $0, 0 			# initialize $4 (valid icons) to 0
		addi 	$7, $0, 7 			# initialize $7 (num valid) to 8
		addi 	$8, $0, 1 			# initialize $8 (constant 1) to 1
		addi	$11, $0, 576			# initialize $11 (constant 144pixels*4) to 576

Find:		addi 	$1, $1, 4 			# increment mem offset
		lw	$2, PatternBase($1)		# load next pixel in pattern
		beq 	$2, $0, Find 			# if it is not black (==0) looks at next pixel in pattern

		addi	$5, $0, 8			# initialize $5 to 8
NextC:		beq 	$5, $0, Find 			# if index = 0 (ie all candidates have been checked), search pattern
	 	addi 	$5, $5, -1 			# decrement current candidate
		srlv 	$3, $4, $5 			# shift $4 so that LSB is current candidate validity
		andi 	$3, $3, 1 			# remove all but LSB
		bne 	$3, $0, NextC			# if invalid (ie index in $4 ==1), jump to inval
									
							# if the candidate is valid
Valid:		mult 	$5, $11 			# multiply current icon by 576 to find candidate's 1st pixel 
		mflo 	$3				# move result from lower
		add 	$3, $3, $1 			# add pixel offset
		lw 	$3, CandBase($3) 		# load pixel
		beq  	$3, $2, NextC			# If the pattern and cand match, check next candidate

									# If they do not match, update $4 and $7
NMatch:		sllv 	$3, $8, $5 			# move the constant 1 to location of candidate
		or 	$4, $4, $3 			# or the shifted 1 with possible candidates
		addi 	$7, $7, -1 			# decrement num possible candidates
		bne  	$7, $0, NextC			# if num remaining candidates != 0, check next candidate
		 
Sub:		addi 	$2, $0, -1 			# initialize $2 to -1
Sub2: 		addi 	$2, $2, 1 			# increment $2
	 	srlv  	$3, $4, $2 			# shift $4 to the right so that current spot is LSB
		andi 	$3, $3, 1 			# isolate LSB
		bne 	$3, $0, Sub2 			# if LSB != 1 shift again
							# else if LSB=0 and that is the valid candidate
		swi	544				# submit answer and check
		jr	$31				# return to caller
