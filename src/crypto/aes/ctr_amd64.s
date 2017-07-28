// Copyright 2017 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

#include "textflag.h"

// func encryptEightBlocks(nr int, xk *uint32, dst, src *byte)
TEXT ·encryptEightBlocks(SB),0,$112-32
#define aesRound AESENC X1, X8; AESENC X1, X9; AESENC X1, X10; AESENC X1, X11; \
            AESENC X1, X12; AESENC X1, X13; AESENC X1, X14; AESENC X1, X15;
	MOVQ nr+0(FP), CX
	MOVQ xk+8(FP), AX
	MOVQ dst+16(FP), DX
	MOVQ src+24(FP), BX
	MOVOU 0(AX), X1
	ADDQ $16, AX

	MOVOU 0(BX), X8
	MOVOU 16(BX), X9
	MOVOU 32(BX), X10
	MOVOU 48(BX), X11
	MOVOU 64(BX), X12
	MOVOU 80(BX), X13
	MOVOU 96(BX), X14
	MOVOU 112(BX), X15

	PXOR X1, X8
	PXOR X1, X9
	PXOR X1, X10
	PXOR X1, X11
	PXOR X1, X12
	PXOR X1, X13
	PXOR X1, X14
	PXOR X1, X15

	SUBQ $12, CX
	JE Lenc196
	JB Lenc128
Lenc256:
	MOVOU 0(AX), X1
    aesRound
	MOVOU 16(AX), X1
    aesRound
	ADDQ $32, AX
Lenc196:
	MOVOU 0(AX), X1
    aesRound
	MOVOU 16(AX), X1
    aesRound
	ADDQ $32, AX
Lenc128:
	MOVOU 0(AX), X1
	aesRound
	MOVOU 16(AX), X1
	aesRound
	MOVOU 32(AX), X1
	aesRound
	MOVOU 48(AX), X1
	aesRound
	MOVOU 64(AX), X1
	aesRound
	MOVOU 80(AX), X1
	aesRound
	MOVOU 96(AX), X1
	aesRound
	MOVOU 112(AX), X1
	aesRound
	MOVOU 128(AX), X1
	aesRound
	MOVOU 144(AX), X1

	AESENCLAST X1, X8
	AESENCLAST X1, X9
	AESENCLAST X1, X10
	AESENCLAST X1, X11
	AESENCLAST X1, X12
	AESENCLAST X1, X13
	AESENCLAST X1, X14
	AESENCLAST X1, X15

	MOVOU X8, 0(DX)
	MOVOU X9, 16(DX)
	MOVOU X10, 32(DX)
	MOVOU X11, 48(DX)
	MOVOU X12, 64(DX)
	MOVOU X13, 80(DX)
	MOVOU X14, 96(DX)
	MOVOU X15, 112(DX)
	RET

// func fillBuffer(bufferBase, counterBase *byte, size int)
TEXT ·fillBuffer(SB),NOSPLIT,$0
    MOVQ    bufferBase+0(FP), BX
    MOVQ    counterBase+8(FP), R8
    MOVQ    size+16(FP), R9
    SHRQ    $4, R9
    SHLQ    $4, R9
    MOVQ    (R8), R11
    MOVQ    8(R8), R12
    XORQ    CX, CX

loop:
    MOVQ    R11, (BX)(CX*1)
    MOVQ    R12, 8(BX)(CX*1)
    ADDQ    $16, CX
    BSWAPQ  R11
    BSWAPQ  R12
    ADDQ    $1, R12
    ADCQ    $0, R11
    BSWAPQ  R12
    BSWAPQ  R11
    CMPQ    CX, R9
    JL      loop

    MOVQ    R11, (R8)
    MOVQ    R12, 8(R8)
    RET

