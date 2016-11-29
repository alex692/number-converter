                .data

# Global g_options.
#
# [0]           number of bits (8, 16 or 32)
# [1]           0 for unsigned, 1 for signed

                .globl          g_options
g_options:      .byte           32 1

# Title message.

m_title:        .ascii          "Number Converter\n"
                .ascii          "----------------\n"
                .asciiz         "Enter a number, or 'h' for help\n"

# Prompt message.

m_prompt:       .asciiz         "> "

# Help message.

m_help:         .ascii          " 0b - binary prefix\n"
                .ascii          " 0 - octal prefix\n"
                .ascii          " 0x - hexadecimal prefix\n\n"
                .ascii          " h - help\n"
                .ascii          " b - set bits\n"
                .ascii          " s - switch to signed mode\n"
                .ascii          " u - switch to unsigned mode\n"
                .asciiz         " q - quit\n"

# Signed message.

m_signed:       .asciiz         "Switched to signed mode.\n"

# Unsigned message.

m_unsigned:     .asciiz         "Switched to unsigned mode.\n"

                .text

# Program entry.

                .globl          main

# Set exception return address.

main:           la $k0,_loop                    # address of _loop

# Initialize buffer.

                li $v0,9                        # sbrk
                li $a0,1024                     # number of bytes
                syscall                         # syscall
                move $s0,$v0                    # save address
                li $t0,0x0a                     # '\n'
                sb $t0,1022($s0)                # second last byte

# Print title.

                li $v0,4                        # print string
                la $a0,m_title                  # address of m_title
                syscall                         # syscall

# Main loop.

# Print '\n'

_loop:          li $v0,11                       # print char
                li $a0,0x0a                     # '\n'
                syscall                         # syscall

# Print number of bits.

_short:         li $v0,1                        # print int
                lbu $a0,g_options               # number of bits
                syscall                         # syscall

# Print 'u' if unsigned.

                lbu $t0,g_options+1             # signed
                bne $t0,0,_print                # if (signed != 0) branch to _print
                li $v0,11                       # print char
                li $a0,0x75                     # 'u'
                syscall                         # syscall

# Print prompt.

_print:         li $v0,4                        # print string
                la $a0,m_prompt                 # address of m_prompt
                syscall                         # syscall

# Read a line of input.

                move $a0,$s0                    # address of buffer
                li $a1,1024                     # size of buffer
                jal read_line                   # call read_line

# Short circuit.

                lbu $t0,($s0)                   # first char
                beq $t0,0x0a,_short             # if (char == '\n') branch to _short

# Print '\n'

                li $v0,11                       # print char
                li $a0,0x0a                     # '\n'
                syscall                         # syscall

# Initialize offset and sign.

                li $s1,0                        # offset
                li $s2,0                        # sign

# Parse the sign.

                beq $t0,0x2d,_nve               # if (char == '-') branch to _nve
                beq $t0,0x2b,_pve               # if (char == '+') branch to _pve
                j _first                        # jump to _first
_nve:           li $s2,1                        # sign = 1
_pve:           lbu $t0,g_options+1             # signed
                tnei $t0,1                      # if (signed != 1) trap
                add $s1,$s1,1                   # offset++

# Parse the first character after the sign.

_first:         add $t0,$s0,$s1                 # address of char at offset
                lbu $t1,($t0)                   # char at offset
                beq $t1,0x30,_second            # if (char == '0') branch to _second
                or $t1,0x20                     # convert to lowercase
                beq $t1,0x75,_unsigned          # if (char == 'u') branch to _unsigned
                beq $t1,0x73,_signed            # if (char == 's') branch to _signed
                beq $t1,0x68,_help              # if (char == 'h') branch to _help
                beq $t1,0x71,_exit              # if (char == 'q') branch to _exit
                j _dec                          # jump to _dec

# Parse the second character after the sign.

_second:        add $s1,$s1,1                   # offset++
                add $t0,$s0,$s1                 # address of char at offset
                lbu $t1,($t0)                   # char at offset
                or $t1,0x20                     # convert to lowercase
                beq $t1,0x62,_bin               # if (char == 'b') branch to _bin
                beq $t1,0x78,_hex               # if (char == 'x') branch to _hex
                j _oct                          # jump to _oct

# Convert binary number.

_bin:           add $s1,$s1,1                   # offset++
                add $t0,$s0,$s1                 # address of char at offset
                la $a0,($t0)                    # address of first digit
                li $a1,2                        # radix
                move $a2,$s2                    # sign
                jal parse_num                   # call parse_num
                move $a0,$v0                    # value
                jal print_num                   # call print_num
                j _loop                         # jump to _loop

# Convert octal number.

_oct:           add $t0,$s0,$s1                 # address of char at offset
                la $a0,($t0)                    # address of first digit
                li $a1,8                        # radix
                move $a2,$s2                    # sign
                jal parse_num                   # call parse_num
                move $a0,$v0                    # value
                jal print_num                   # call print_num
                j _loop                         # jump to _loops

# Convert decimal number.

_dec:           add $t0,$s0,$s1                 # address of char at offset
                la $a0,($t0)                    # address of first digit
                li $a1,10                       # radix
                move $a2,$s2                    # sign
                jal parse_num                   # call parse_num
                move $a0,$v0                    # value
                jal print_num                   # call print_num
                j _loop                         # jump to _loop

# Convert hexadecimal number.

_hex:           add $s1,$s1,1                   # offset++
                add $t0,$s0,$s1                 # address of char at offset
                la $a0,($t0)                    # address of first digit
                li $a1,16                       # radix
                move $a2,$s2                    # sign
                jal parse_num                   # call parse_num
                move $a0,$v0                    # value
                jal print_num                   # call print_num
                j _loop                         # jump to _loop

# Print help text.

_help:          li $v0,4                        # print string
                la $a0,m_help                   # address of m_help
                syscall                         # syscall
                j _loop                         # jump to _loop

# Switch to signed mode.

_signed:        li $t0,1                        # signed
                sb $t0,g_options+1              # update option
                li $v0,4                        # print string
                la $a0,m_signed                 # address of m_signed
                syscall                         # syscall
                j _loop                         # jump to _loop

# Switch to unsigned mode.

_unsigned:      li $t0,0                        # unsigned
                sb $t0,g_options+1              # update option
                li $v0,4                        # print string
                la $a0,m_unsigned               # address of m_unsigned
                syscall                         # syscall
                j _loop                         # jump to _loop

# Exit program.

_exit:          li $v0,10                       # exit
                syscall                         # syscall
