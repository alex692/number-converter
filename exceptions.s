                .kdata

_e0:            .asciiz         "[Interrupt]"
_e1:            .asciiz         "[TLB]"
_e2:            .asciiz         "[TLB]"
_e3:            .asciiz         "[TLB]"
_e4:            .asciiz         "[Address error in inst/data fetch]"
_e5:            .asciiz         "[Address error in store]"
_e6:            .asciiz         "[Bad instruction address]"
_e7:            .asciiz         "[Bad data address]"
_e8:            .asciiz         "[Error in syscall]"
_e9:            .asciiz         "[Breakpoint]"
_e10:           .asciiz         "[Reserved instruction]"
_e11:           .asciiz         ""
_e12:           .asciiz         "Arithmetic overflow."
_e13:           .asciiz         "Invalid input."
_e14:           .asciiz         ""
_e15:           .asciiz         "[Floating point]"
_e16:           .asciiz         ""
_e17:           .asciiz         ""
_e18:           .asciiz         "[Coproc 2]"
_e19:           .asciiz         ""
_e20:           .asciiz         ""
_e21:           .asciiz         ""
_e22:           .asciiz         "[MDMX]"
_e23:           .asciiz         "[Watch]"
_e24:           .asciiz         "[Machine check]"
_e25:           .asciiz         ""
_e26:           .asciiz         ""
_e27:           .asciiz         ""
_e28:           .asciiz         ""
_e29:           .asciiz         ""
_e30:           .asciiz         "[Cache]"
_e31:           .asciiz         ""

_excp:          .word           _e0, _e1, _e2, _e3, _e4, _e5, _e6, _e7, _e8, _e9,
                .word           _e10, _e11, _e12, _e13, _e14, _e15, _e16, _e17, _e18,
                .word           _e19, _e20, _e21, _e22, _e23, _e24, _e25, _e26, _e27,
                .word           _e28, _e29, _e30, _e31

_at:            .word 0
_v0:            .word 0
_a0:            .word 0
_k0:            .word 0
_k1:            .word 0

                .ktext 0x80000180

# Store registers.
                .set noat
                sw $at,_at                      # save $at
                sw $v0,_v0                      # save $v0
                sw $a0,_a0                      # save $a0
                sw $k0,_k0                      # save $k0
                sw $k1,_k1                      # save $k1
                .set at

# Load coprocessor 0 registers.

                mfc0 $k0,$13                    # cause
                mfc0 $k1,$14                    # epc

# Print _e[code].

                li $v0,4                        # print string
                andi $a0,$k0,0x3c               # extract exception code
                lw $a0,_excp($a0)               # address of _e[code]
                syscall                         # syscall

# Print '\n'

                li $v0,11                       # print char
                li $a0,0x0a                     # '\n'
                syscall                         # syscall

# Reset processor state.

                mtc0 $0,$13                     # clear cause register
                mfc0 $k0,$12                    # set status register
                ori  $k0,0x1                    # interrupts enabled
                mtc0 $k0,$12

# Restore registers.

                .set noat
                lw $at,_at                      # restore $at
                lw $v0,_v0                      # restore $v0
                lw $a0,_a0                      # restore $a0
                lw $k0,_k0                      # restore $k0
                lw $k1,_k1                      # restore $k1
                .set at

# Return to catch address.

                jr $k0                          # jump to catch address
