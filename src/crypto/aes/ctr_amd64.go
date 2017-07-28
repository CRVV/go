// Copyright 2017 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

package aes

import (
	"crypto/cipher"
	"unsafe"
)

func encryptEightBlocks(nr int, xk *uint32, dst, counter *byte)

// streamBufferSize is the number of bytes of encrypted counter values to cache.
const streamBufferSize = 32 * BlockSize

type aesctr struct {
	block   *aesCipherAsm // block cipher
	nr      int
	ctr     [BlockSize]byte        // next value of the counter (big endian)
	buffer  []byte                 // buffer for the encrypted counter values
	storage [streamBufferSize]byte // array backing buffer slice
}

// NewCTR returns a Stream which encrypts/decrypts using the AES block
// cipher in counter mode. The length of iv must be the same as BlockSize.
func (c *aesCipherAsm) NewCTR(iv []byte) cipher.Stream {
	if len(iv) != BlockSize {
		panic("cipher.NewCTR: IV length must equal block size")
	}
	var ac aesctr
	ac.block = c
	ac.nr = len(c.enc)/4 - 1
	copy(ac.ctr[:], iv)
	ac.buffer = ac.storage[:0]
	return &ac
}

func (c *aesctr) refill() {
	// Fill up the buffer with an incrementing count.
	c.buffer = c.storage[:streamBufferSize]
	for j := 0; j < streamBufferSize; j += BlockSize {
		copy(c.buffer[j:], c.ctr[:])
		for i := len(c.ctr) - 1; i >= 0; i-- {
			c.ctr[i]++
			if c.ctr[i] != 0 {
				break
			}
		}
	}
	for i := 0; i < len(c.buffer); i += BlockSize * 8 {
		encryptEightBlocks(c.nr, &c.block.enc[0], &c.buffer[i], &c.buffer[i])
	}
}

func (c *aesctr) XORKeyStream(dst, src []byte) {
	if len(src) == 0 {
		return
	}
	_ = dst[len(src)-1]
	for len(src) > 0 {
		if len(c.buffer) == 0 {
			c.refill()
		}
		n := fastXORBytes(dst, src, c.buffer)
		c.buffer = c.buffer[n:]
		src = src[n:]
		dst = dst[n:]
	}
}

func fastXORBytes(dst, a, b []byte) int {
	wordSize := 8
	n := len(a)
	if len(b) < n {
		n = len(b)
	}

	w := n / wordSize
	if w > 0 {
		dw := *(*[]uintptr)(unsafe.Pointer(&dst))
		aw := *(*[]uintptr)(unsafe.Pointer(&a))
		bw := *(*[]uintptr)(unsafe.Pointer(&b))
		for i := 0; i < w; i++ {
			dw[i] = aw[i] ^ bw[i]
		}
	}

	for i := (n - n%wordSize); i < n; i++ {
		dst[i] = a[i] ^ b[i]
	}

	return n
}
