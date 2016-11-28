                .text

# Parses given string into a binary number.
#
# $a0           address of first digit
# $a1           radix
# $a2           sign
#
# $v0           value of the number in binary

                .globl parse_num

# Initialize return value.

parse_num:      li $v0,0                        # value

# Loop over the characters.

_loop:          lbu $t0,($a0)                   # char
                beq $t0,0x0a,_sign              # if (char == '\n') branch to _sign
                beq $t0,0x00,_sign              # if (char == '\0') branch to _sign
                ble $a1,10,_num                 # if (radix <= 10) branch to _num

# Parse alphabetic character.

                or $t0,0x20                     # convert to lowercase
                add $t1,$a1,0x56                # max
                bgt $t0,$t1,_nan                # if (char > max) branch to _nan
                bgt $t0,0x7a,_nan               # if (char > 'z') branch to _nan
                blt $t0,0x61,_num               # if (char < 'a') branch to _num
                add $t0,$t0,-0x57               # convert to int
                j _add                          # jump to _add

# Parse numeric character.

_num:           add $t1,$a1,47                  # max
                bgt $t0,$t1,_nan                # if (char > max) branch to _nan
                bgt $t0,57,_nan                 # if (char > '9') branch to _nan
                blt $t0,48,_nan                 # if (char < '0') branch to _nan
                and $t0,0xcf                    # convert to int
                j _add                          # jump to _add

# Not a number.

_nan:           beq $t0,0x20,_next              # if (char == ' ') branch to _next
                beq $t0,0x2c,_next              # if (char == ',') branch to _next
                teqi $zero,0                    # trap

# Add integer to value.

_add:           mul $v0,$v0,$a1                 # result *= radix
                addu $v0,$v0,$t0                # result += int

# Parse next character.

_next:          add $a0,$a0,1                   # address++
                j _loop                         # jump to _loop

# Negate if negative

_sign:          beq $a2,0,_return               # if (sign == 0) branch to _return
                negu $v0,$v0                    # negate value

# Return to caller.

_return:        jr $ra                          # jump to return address
