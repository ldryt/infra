package main

import (
	"errors"
	"io"
)

// https://wiki.vg/Protocol#Type:VarInt

const (
	segmentBits int32 = 0x7F
	continueBit int32 = 0x80
)

func ReadVarInt(r io.Reader) (value int32, err error) {
	var position int
	var currentByte []byte = make([]byte, 1)

	for {
		_, err = r.Read(currentByte)
		if err != nil {
			return 0, err
		}

		value |= int32(currentByte[0]) & segmentBits << position

		if (int32(currentByte[0]) & continueBit) == 0 {
			break
		}

		position += 7

		if position >= 32 {
			return 0, errors.New("VarInt too big")
		}
	}

	return value, nil
}

func WriteVarInt(w io.Writer, value int32) (err error) {
	for {
		if (value & ^segmentBits) == 0 {
			_, err = w.Write([]byte{byte(value)})
			return err
		}

		_, err = w.Write([]byte{byte((value & segmentBits) | continueBit)})
		if err != nil {
			return err
		}

		value = int32(uint32(value) >> 7)
	}
}

func VarIntSize(value int32) (size int) {
	for {
		size++
		value >>= 7
		if value == 0 {
			break
		}
	}

	return size
}
