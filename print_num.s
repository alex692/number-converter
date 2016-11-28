                .data

# Labels

m_bin:          .asciiz         "Binary:  "
m_oct:          .asciiz         "Octal:   "
m_dec:          .asciiz         "Decimal: "
m_hex:          .asciiz         "Hex:     "

                .text

# Print given number in different bases.
#
# $a0           value of number to print

                .globl print_num

# Store registers.

print_num:      add $sp,$sp,-8                  # push
                sw $ra,0($sp)                   # save $ra
                sw $s0,4($sp)                   # save $s0

# Save arguments.

                move $s0,$a0                    # value

# Print binary

                li $v0,4                        # print string
                la $a0,m_bin                    # address of m_bin
                syscall                         # syscall

                move $a0,$s0                    # value
                li $a1,2                        # radix
                li $a2,4                        # grouping
                li $a3,0x20                     # separator
                jal _print                      # call _print

# Print octal.

                li $v0,4                        # print string
                la $a0,m_oct                    # address of m_oct
                syscall                         # syscall

                move $a0,$s0                    # value
                li $a1,8                        # radix
                li $a2,3                        # grouping
                li $a3,0x20                     # separator
                jal _print                      # call _print

# Print decimal.

                li $v0,4                        # print string
                la $a0,m_dec                    # address of m_dec
                syscall                         # syscall

                move $a0,$s0                    # value
                li $a1,10                       # radix
                li $a2,3                        # grouping
                li $a3,0x2c                     # separator
                jal _print                      # call _print

# Print hexadecimal.

                li $v0,4                        # print string
                la $a0,m_hex                    # address of m_hex
                syscall                         # syscall

                move $a0,$s0                    # value
                li $a1,16                       # radix
                li $a2,4                        # grouping
                li $a3,0x20                     # separator
                jal _print                      # call _print

# Restore registers.

                lw $ra,0($sp)                   # restore $ra
                lw $s0,4($sp)                   # restore $s0
                add $sp,$sp,8                   # pop

# Return to caller.

                jr $ra                          # jump to return address

# Print value of number in given base.
#
# $a0           value of number to print
# $a1           radix
# $a2           grouping
# $a3           separator

# Store registers.

_print:         add $sp,$sp,-28                 # push
                sw $s0,0($sp)                   # save $s0
                sw $s1,4($sp)                   # save $s1
                sw $s2,8($sp)                   # save $s2
                sw $s3,12($sp)                  # save $s3
                sw $s4,16($sp)                  # save $s4
                sw $s5,20($sp)                  # save $s5
                sw $s6,24($sp)                  # save $s6

# Save arguments.

                move $s0,$a0                    # value
                move $s1,$a1                    # radix
                move $s2,$a2                    # grouping
                move $s3,$a3                    # separator

# Find the minimum power greater than the value.

                li $s4,1                        # power = 1
                li $s5,0                        # exponent = 0
                not $t0,$zero                   # max = 0xffffffff
_power:         mul $s4,$s4,$s1                 # power *= radix
                addi $s5,$s5,1                  # exponent++
                divu $t1,$t0,$s4                # quotient = max / power
                bgtu $s4,$s0,_root              # if (power > value) branch to _root
                bltu $t1,$s1,_extract           # if (quotient < radix) branch to _extract
                j _power                        # jump to _power

# Extract digits.

_extract:       divu $s6,$s0,$s4                # digit = value / power
                add $t1,$s6,0x30                # convert digit to numeric char
                ble $t1,0x39,_yield             # if (char <= '9') branch to _yield
                add $t1,$t1,0x27                # convert to lowercase char

# Print digit.

_yield:         li $v0,11                       # print char
                move $a0,$t1                    # char
                syscall                         # syscall

# End condition.

                beq $s5,0,_end                  # if (exponent == 0) branch to _end

# Drop digit.

                mul $t0,$s6,$s4                 # diff = digit * power
                sub $s0,$s0,$t0                 # value -= diff

# Print grouping separator.

                rem $t0,$s5,$s2                 # rem = exponent / grouping
                bgt $t0,0,_root                 # if (rem > 0) branch to _root
                li $v0,11                       # print char
                move $a0,$s3                    # separator
                syscall                         # syscall

# Root the power.

_root:          divu $s4,$s4,$s1                # power /= radix
                add $s5,$s5,-1                  # exponent--
                j _extract                      # jump to _extract

# Print '\n'

_end:           li $v0,11                       # print char
                li $a0,0x0a                     # '\n'
                syscall                         # syscall

# Restore registers.

                lw $s0,0($sp)                   # restore $s0
                lw $s1,4($sp)                   # restore $s1
                lw $s2,8($sp)                   # restore $s2
                lw $s3,12($sp)                  # restore $s3
                lw $s4,16($sp)                  # restore $s4
                lw $s5,20($sp)                  # restore $s5
                lw $s6,24($sp)                  # restore $s6
                add $sp,$sp,28                  # pop

# Return to caller.

                jr $ra                          # jump to return address
