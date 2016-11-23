.data
az_title:       .asciiz         "Number Converter\n----------------\n'h' for help, 'q' to exit\n\n"
az_prompt:      .asciiz         "> "
az_label:       .asciiz         "BIN: 0b" "OCT: 0" "DEC: " "HEX: 0x"
az_invalid:     .asciiz         "Invalid input.\n'h' for help, 'q' to exit\n\n"
az_help:        .asciiz         "Enter a number in any base as shown in the table\nto convert it to base 2, 8, 10 and 16.\n\nBase\tPrefix\tExample\n2\t0b\t0b1010\n8\t0\t014\n10\t(none)\t12\n16\t0x\t0xb\n\n"
.text
.globl main
                # allocate buffer
main:           addi $2,$0,9                    # sbrk
                addi $4,$0,64                   # bytes to allocate
                syscall                         # syscall

                # initialize registers
                addi $16,$2,0                   # address of buffer
                la $17,az_prompt                # address of az_prompt
                la $18,az_label                 # address of az_label
                la $19,az_invalid               # address of az_invalid
                la $20,az_help                  # address of az_help

                # initialize buffer
                addi $8,$0,10                   # '\n'
                sb $8,62($16)                   # store '\n' in second last char

                # print title
                addi $2,$0,4                    # print string
                la $4,az_title                  # address of title
                syscall                         # syscall

                # print prompt
prompt:         addi $2,$0,4                    # print string
                addi $4,$17,0                   # address of az_prompt
                syscall                         # syscall

                # read string
                addi $2,$0,8                    # read string
                addi $4,$16,0                   # address of buffer
                addi $5,$0,63                   # max chars
                syscall                         # syscall

                # initialize result
                addi $24,$0,0                   # result = 0

                # ensure second last char is '\n'
                lb $8,62($16)                   # second last char
                addi $9,$0,10                   # if (char == '\n')
                beq $8,$9,char1                 # branch to char1
                sb $9,62($16)                   # store '\n' to second last char

                # print '\n'
                addi $2,$0,11                   # print char
                addi $4,$0,10                   # '\n'
                syscall                         # syscall

                # check first char
char1:          lb $8,0($16)                    # first char
                add $9,$8,-10                   # if (char == '\n')
                beq $9,$0,prompt                # branch to prompt
                addi $2,$0,11                   # print char
                addi $4,$0,10                   # '\n'
                syscall                         # syscall
                add $9,$8,-113                  # if (char == 'q')
                beq $9,$0,exit                  # branch to exit
                add $9,$8,-104                  # if (char == 'h')
                beq $9,$0,help                  # branch to help
                add $9,$8,-45                   # if (char == '-')
                beq $9,$0,i_dec_neg             # branch to i_dec_neg
                add $9,$8,-48                   # if (char == '0')
                beq $9,$0,char2                 # branch to char2
                bltz $9,invalid                 # if (char < '0') branch to invalid
                add $9,$8,-57                   # if (char > '9')
                bgtz $9,invalid                 # branch to invalid
                j i_dec                         # jump to i_dec

                # check second char
char2:          lb $8,1($16)                    # second char
                add $9,$8,-10                   # if (char == '\n')
                beq $9,$0,print                 # branch to print
                add $9,$8,-120                  # if (char == 'x')
                beq $9,$0,i_hex                 # branch to i_hex
                add $9,$8,-98                   # if (char == 'b')
                beq $9,$0,i_bin                 # branch to i_bin
                add $9,$8,-48                   # if (char < '0')
                bltz $9,invalid                 # branch to invalid
                add $9,$8,-55                   # if (char > '7')
                bgtz $9,invalid                 # branch to invalid
                j i_oct                         # jump to i_oct

                # parse decimal
i_dec:          addi $9,$16,0                   # address of first char
                addi $10,$0,10                  # multipler
                addi $25,$0,0                   # sign = 0
                j i_dec_next                    # jump to i_dec_next
i_dec_neg:      addi $9,$16,1                   # address of first char
                lb $8,0($9)                     # first char
                addi $10,$0,10                  # multiplier
                addi $25,$0,1                   # sign = 1
i_dec_next:     addi $8,$8,-57                  # if (char > '9')
                bgtz $8,invalid                 # branch to invalid
                addi $8,$8,9                    # if (char < '0')
                bltz $8,i_dec_nan               # branch to i_dec_nan
                mul $24,$24,$10                 # result *= 10
                addu $24,$24,$8                 # result += digit
                srl $11,$24,31                  # if (msb != 0)
                bne $11,$0,invalid              # branch to invalid
                j i_dec_inc                     # jump to i_dec_inc
i_dec_nan:      addi $11,$8,16                  # if (char == ' ')
                beq $11,$0,i_dec_inc            # branch to i_dec_inc
                addi $11,$8,4                   # if (char == ',')
                beq $11,$0,i_dec_inc            # branch to i_dec_inc
                j invalid                       # jump to invalid
i_dec_inc:      addi $9,$9,1                    # address of next char
                lb $8,0($9)                     # next char
                addi $11,$8,-10                 # if (char == '\n')
                beq $11,$0,sign                 # branch to sign
                j i_dec_next                    # jump to i_dec_next

                # parse hexadecimal
i_hex:          addi $9,$16,2                   # address of first char
i_hex_next:     lb $8,0($9)                     # next char
                addi $10,$8,-10                 # if (char == '\n')
                beq $10,$0,print                # branch to print
                addi $8,$8,-102                 # if (char > 'f')
                bgtz $8,invalid                 # branch to invalid
                addi $8,$8,5                    # if (char < 'a')
                bltz $8,i_hex_cap               # branch to i_hex_cap
                addi $8,$8,10                   # digit += 10
                j i_hex_add                     # jump to i_hex_add
i_hex_cap:      addi $8,$8,27                   # if (char > 'F')
                bgtz $8,invalid                 # branch to invalid
                addi $8,$8,5                    # if (char < 'A')
                bltz $8,i_hex_num               # branch to dig
                addi $8,$8,10                   # digit += 10
                j i_hex_add                     # jump to i_hex_add
i_hex_num:      addi $8,$8,8                    # if (char > '9')
                bgtz $8,invalid                 # branch to invalid
                addi $8,$8,9                    # if (char < '0')
                bltz $8,i_hex_nan               # branch to i_hex_nan
i_hex_add:      sll $24,$24,4                   # result *= 16
                addu $24,$24,$8                 # result += digit
                srl $10,$24,31                  # if (msb != 0)
                #bne $10,$0,invalid             # branch to invalid
                j i_hex_inc                     # jump to i_hex_inc
i_hex_nan:      addi $11,$8,16                  # if (char == ' ')
                beq $11,$0,i_hex_inc            # branch to i_hex_inc
                addi $11,$8,4                   # if (char == ',')
                beq $11,$0,i_hex_inc            # branch to i_hex_inc
                j invalid                       # jump to invalid
i_hex_inc:      addi $9,$9,1                    # address of next char
                j i_hex_next                    # jump to i_hex_next

                # parse binary
i_bin:          addi $9,$16,2                   # address of first char
i_bin_next:     lb $8,0($9)                     # next char
                addi $10,$8,-10                 # if (char == '\n')
                beq $10,$0,print                # branch to print
                addi $8,$8,-49                  # if (char > '1')
                bgtz $8,invalid                 # branch to invalid
                addi $8,$8,1                    # if (char < '0')
                bltz $8,i_bin_nan               # branch to i_bin_nan
                sll $24,$24,1                   # result *= 2
                addu $24,$24,$8                 # result += digit
                srl $10,$24,31                  # if (msb != 0)
                bne $10,$0,invalid              # branch to invalid
                j i_bin_inc                     # jump to i_bin_inc
i_bin_nan:      addi $11,$8,16                  # if (char == ' ')
                beq $11,$0,i_bin_inc            # branch to i_bin_inc
                addi $11,$8,4                   # if (char == ',')
                beq $11,$0,i_bin_inc            # branch to i_bin_inc
                j invalid                       # jump to invalid
i_bin_inc:      addi $9,$9,1                    # address of next char
                j i_bin_next                    # jump to i_bin_next

                # parse octal
i_oct:          addi $9,$16,1                   # address of first char
i_oct_next:     addi $8,$8,-55                  # if (char > '7')
                bgtz $8,invalid                 # branch to invalid
                addi $8,$8,7                    # if (char < '0')
                bltz $8,i_oct_nan               # branch to i_oct_nan
                sll $24,$24,3                   # result *= 8
                addu $24,$24,$8                 # result += digit
                srl $10,$24,31                  # if (msb != 0)
                bne $10,$0,invalid              # branch to invalid
                j i_oct_inc                     # jump to i_oct_inc
i_oct_nan:      addi $11,$8,16                  # if (char == ' ')
                beq $11,$0,i_oct_inc            # branch to i_oct_inc
                addi $11,$8,4                   # if (char == ',')
                beq $11,$0,i_oct_inc            # branch to i_oct_inc
                j invalid                       # jump to invalid
i_oct_inc:      addi $9,$9,1                    # address of next char
                lb $8,0($9)                     # next char
                addi $10,$8,-10                 # if (char == '\n')
                beq $10,$0,print                # branch to print
                j i_oct_next                    # jump to i_oct_next

                # convert sign
sign:           beq $25,$0,print                # if (sign == 0) branch to print
                nor $24,$24,$0                  # flip bits
                addi $24,$24,1                  # add 1

                # print binary
print:          addi $2,$0,4                    # print string
                addi $4,$18,0                   # address of az_label[0]
                syscall                         # syscall
                addi $2,$0,11                   # print char
                beq $24,$0,o_bin_z              # if (result == 0) branch to o_bin_z
                addi $8,$0,0                    # a = 0
                addi $9,$0,31                   # i = 31
o_bin_next:     rol $24,$24,1                   # rotate left 1
                andi $4,$24,1                   # lsb
                or $8,$8,$4                     # a |= lsb
                beq $8,$0,o_bin_inc             # if (a == 0) branch to o_bin_inc
                addi $4,$4,48                   # convert to char
                syscall                         # syscall
o_bin_inc:      beq $9,$0,o_bin_end             # if (i == 0) branch to o_bin_end
                addi $9,$9,-1                   # i--
                j o_bin_next                    # jump to o_bin_next
o_bin_z:        addi $4,$0,48                   # '0'
                syscall                         # syscall
o_bin_end:      addi $4,$0,10                   # '\n'
                syscall                         # syscall

                # print octal
                addi $2,$0,4                    # print string
                addi $4,$18,8                   # address of az_label[1]
                syscall                         # syscall
                addi $2,$0,11                   # print char
                beq $24,$0,o_oct_z              # if (result == 0) branch to o_oct_z
                addi $8,$0,0                    # a = 0
                addi $9,$0,9                    # i = 9
                rol $24,$24,2                   # rotate left 2
                andi $4,$24,3                   # 2 lsbs
                beq $4,$0,o_oct_next            # if (lsb == 0) branch to o_oct_next
                addi $4,$4,48                   # convert to char
                syscall                         # syscall
o_oct_next:     rol $24,$24,3                   # rotate left 3
                andi $4,$24,7                   # 3 lsbs
                or $8,$8,$4                     # a |= lsb
                beq $8,$0,o_oct_inc             # if (a == 0) branch to o_oct_inc
                addi $4,$4,48                   # convert to char
                syscall                         # syscall
o_oct_inc:      beq $9,$0,o_oct_end             # if (i == 0) branch to o_oct_end
                addi $9,$9,-1                   # i--
                j o_oct_next                    # jump to o_oct_next
o_oct_z:        addi $4,$0,48                   # '0'
                syscall                         # syscall
o_oct_end:      addi $4,$0,10                   # '\n'
                syscall                         # syscall

                # print decimal
                addi $2,$0,4                    # print string
                addi $4,$18,15                  # address of az_label[2]
                syscall                         # syscall
                addi $4,$24,0                   # result
                addi $2,$0,1                    # print int
                syscall                         # syscall
                addi $4,$0,10                   # '\n'
                addi $2,$0,11                   # print char
                syscall                         # syscall

                # print hexadecimal
                addi $2,$0,4                    # print string
                addi $4,$18,21                  # address of az_label[3]
                syscall                         # syscall
                addi $2,$0,11                   # print char
                beq $24,$0,o_hex_z              # if (result == 0) branch to o_hex_z
                addi $8,$0,0                    # a = 0
                addi $9,$0,7                    # i = 7
o_hex_next:     rol $24,$24,4                   # rotate left 4
                andi $4,$24,15                  # 4 lsbs
                or $8,$8,$4                     # a |= lsb
                beq $8,$0,o_hex_inc             # if (a == 0) branch to o_hex_inc
                addi $4,$4,-10                  # if (msb < 10)
                blt $4,$0,o_hex_num             # branch to o_hex_num
                addi $4,$4,97                   # convert to char
                syscall                         # syscall
                j o_hex_inc                     # jump to o_hex_inc
o_hex_num:      addi $4,$4,58                   # convert to char
                syscall                         # syscall
o_hex_inc:      beq $9,$0,o_hex_end             # if (i == 0) branch to o_hex_end
                addi $9,$9,-1                   # i--
                j o_hex_next                    # jump to o_hex_next
o_hex_z:        addi $4,$0,48                   # '0'
                syscall                         # syscall
o_hex_end:      addi $4,$0,10                   # '\n'
                syscall                         # syscall

                # print '\n'
                addi $2,$0,11                   # print char
                addi $4,$0,10                   # '\n'
                syscall                         # syscall
                j prompt                        # jump to prompt

                # print invalid
invalid:        addi $2,$0,4                    # print string
                addi $4,$19,0                   # address of az_invalid
                syscall                         # syscall
                j prompt                        # jump to prompt

                # print help
help:           addi $2,$0,4                    # print string
                addi $4,$20,0                   # address of az_help
                syscall                         # syscall
                j prompt                        # jump to prompt

exit:           addi $2,$0,10                   # exit
                syscall                         # syscall
.end main
