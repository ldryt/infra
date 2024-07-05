package main

import (
	"encoding/binary"
	"errors"
	"io"
)

// https://wiki.vg/Protocol#Type:VarInt

var segmentBits byte = 0x7F
var continueBit byte = 0x80

func ReadVarInt(r io.Reader) (value int32, err error) {
	var position int
	var currentByte byte

	for {
		err = binary.Read(r, binary.BigEndian, &currentByte)
		if err != nil {
			return 0, err
		}

		value |= int32(currentByte&segmentBits) << position

		if (currentByte & continueBit) == 0 {
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
		if (value & int32(^segmentBits)) == 0 {
			_, err = w.Write([]byte{byte(value)})
			return err
		}

		_, err := w.Write([]byte{byte(value)&segmentBits | continueBit})
		if err != nil {
			return err
		}

		value = int32(uint32(value) >> 7)
	}
}

func VarIntSize(value int32) (size int) {
	var i int

	for {
		i++
		value >>= 7
		if value == 0 {
			break
		}
	}

	return i
}
