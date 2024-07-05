package main

import (
	"bytes"
	"testing"
)

// https://wiki.vg/Protocol#VarInt_and_VarLong
var tests = []struct {
	name     string
	VarInt   []byte
	FixedInt int32
}{
	{
		name:     "0",
		FixedInt: 0,
		VarInt:   []byte{0x00},
	},
	{
		name:     "1",
		FixedInt: 1,
		VarInt:   []byte{0x01},
	},
	{
		name:     "2",
		FixedInt: 2,
		VarInt:   []byte{0x02},
	},
	{
		name:     "127",
		FixedInt: 127,
		VarInt:   []byte{0x7f},
	},
	{
		name:     "128",
		FixedInt: 128,
		VarInt:   []byte{0x80, 0x01},
	},
	{
		name:     "255",
		FixedInt: 255,
		VarInt:   []byte{0xff, 0x01},
	},
	{
		name:     "25565",
		FixedInt: 25565,
		VarInt:   []byte{0xdd, 0xc7, 0x01},
	},
	{
		name:     "2097151",
		FixedInt: 2097151,
		VarInt:   []byte{0xff, 0xff, 0x7f},
	},
	{
		name:     "2147483647",
		FixedInt: 2147483647,
		VarInt:   []byte{0xff, 0xff, 0xff, 0xff, 0x07},
	},
	{
		name:     "-1",
		FixedInt: -1,
		VarInt:   []byte{0xff, 0xff, 0xff, 0xff, 0x0f},
	},
	{
		name:     "-2147483648",
		FixedInt: -2147483648,
		VarInt:   []byte{0x80, 0x80, 0x80, 0x80, 0x08},
	},
}

func TestReadVarInt(t *testing.T) {
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			r := bytes.NewReader(tt.VarInt)

			got, err := ReadVarInt(r)
			if err != nil {
				t.Error("An error occurred:", err)
				return
			}

			if got != tt.FixedInt {
				t.Errorf("Got '% X' instead of '% X'.", got, tt.FixedInt)
			}
		})
	}
}

func TestWriteVarInt(t *testing.T) {
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			var buf bytes.Buffer

			err := WriteVarInt(&buf, tt.FixedInt)
			if err != nil {
				t.Error("An error occurred:", err)
				return
			}

			if !bytes.Equal(buf.Bytes(), tt.VarInt) {
				t.Errorf("Got '% X' instead of '% X'.", buf.Bytes(), tt.VarInt)
			}
		})
	}
}
