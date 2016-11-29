                .text

# Reads a line from input to the given buffer.
#
# $a0           address of buffer
# $a1           size of buffer

                .globl read_line

# Read line from input.

read_line:      li $v0,8                        # read string
                add $a1,$a1,-2                  # max number of chars to read
                syscall                         # syscall

# Check second last byte.

                li $v0,11                       # print char
                add $t0,$a0,$a1                 # address of second last byte
                lbu $t1,($t0)                   # second last byte
                li $a0,0x0a                     # '\n'
                beq $t1,$a0,_return             # if (char == '\n') branch to _return
                sb $a0,($t0)                    # store '\n' to second last byte
                syscall                         # syscall

# Return to caller.

_return:        jr $ra                          # jump to return address
