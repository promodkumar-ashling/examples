	.section ".text.init"
	.global	_startup
	.type _startup, @function

_startup:
	.cfi_startproc
	.cfi_undefined ra
.option push
.option norelax
	la gp, __global_pointer$
.option pop
	la sp, _sp

#ifndef __riscv_float_abi_soft
	/* Enable FPU */
	li t0, 3 << 13
	csrs mstatus, t0
#endif

	/* Do not return from here.. */
    .cfi_undefined ra

	/* Clear bss section */
	la a0, __bss_start
	la a1, _end
	bgeu a0, a1, 2f
1:
	sw zero, (a0)
	addi a0, a0, 4
	bltu a0, a1, 1b
2:

	/* Call global constructors */
	call __libc_init_array

	/* argc = argv = 0 */
	li a0, 0
	li a1, 0
	call main

	/* Call global destructors after main */
	call __libc_fini_array

	/* Infinite loop here */
1:
	j 1b

	.cfi_endproc

