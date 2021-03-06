/*

	OR1K jump to jump test

	Stefan Kristiansson, stefan.kristiansson@saunalahti.fi

*/
#include <or1k-asm.h>
#include <or1k-sprs.h>

/* =================================================== [ exceptions ] === */
	.section .vectors, "ax"


/* ---[ 0x100: RESET exception ]----------------------------------------- */
        .org 0x100
	l.movhi r0, 0
	/* Clear status register */
	l.ori 	r1, r0, OR1K_SPR_SYS_SR_SM_MASK
	l.mtspr r0, r1, OR1K_SPR_SYS_SR_ADDR
	/* Clear timer  */
	l.mtspr r0, r0, OR1K_SPR_TICK_TTMR_ADDR

	/* Jump to program initialisation code */
	.global _start
	l.movhi r4, hi(_start)
	l.ori 	r4, r4, lo(_start)
	OR1K_DELAYED_NOP(l.jr    r4)

/* =================================================== [ text ] === */
	.section .text

/* =================================================== [ start ] === */

	.global _start
_start:
	/* r16 hold test loop counter */
	l.movhi r16, 0
	// Kick off test
	OR1K_DELAYED_NOP(l.jal   _main)

/* =================================================== [ main ] === */

test_func0:
	l.lwz	r4, 0(r2)
	l.lwz	r4, 4(r2)
	l.lwz	r4, 8(r2)
	l.lwz	r4, 12(r2)
        OR1K_DELAYED(
	OR1K_INST(l.lwz	r4, 16(r2)),
	OR1K_INST(l.jr	r9)
        )
	.global _main
_main:
	l.movhi	r1, 0
	l.movhi	r2, 0
        OR1K_DELAYED(
	OR1K_INST(l.addi	r2, r0, 0),
	OR1K_INST(l.jal	test_func0)
        )
        OR1K_DELAYED(
	OR1K_INST(l.sw	16(r1), r2),
	OR1K_INST(l.j	.L1)
        )
	OR1K_DELAYED_NOP(l.j	test_fail)
	
.L1:
        OR1K_DELAYED(
        OR1K_INST(l.addi	r1, r1, 1),
	OR1K_INST(l.jal	.L2)
        )
	OR1K_DELAYED_NOP(l.j	test_fail)
.L2:
	/*
	 * Print and check result
	 */
	l.ori	r3, r1, 0
	l.nop	2
	l.sfnei	r1, 1
	OR1K_DELAYED_NOP(l.bf	test_fail)

	/*
	 * Test finished when ran through once without caches enabled
	 * and twice with.
	 */
	l.sfeqi	r16, 2
        OR1K_DELAYED(
	OR1K_INST(l.addi r16, r16, 1),
	OR1K_INST(l.bf	test_ok)
        )

	l.sfeqi r16, 2
	OR1K_DELAYED_NOP(l.bf	_main)

	/* Restart test with cache enabled */
	OR1K_DELAYED_NOP(l.jal 	_cache_init)
	OR1K_DELAYED_NOP(l.j     _main)

test_fail:
	l.movhi	r3,0xbaaa
	l.ori	r3,r3,0xaaad
	l.nop	0x1

test_ok:
	l.movhi	r3,0x8000
	l.ori	r3,r3,0x000d
	l.nop	0x2
	l.ori 	r3, r0, 0 /* Clear R3 */
	l.nop 	0x1 /* Exit simulation */
	l.nop
	l.nop
