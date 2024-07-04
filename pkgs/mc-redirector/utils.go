package main

import (
	"bytes"
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

// https://wiki.vg/Protocol#Packet_format

type Packet struct {
	ID   int32
	Data bytes.Buffer
}

func ReadPacket(r io.Reader) (p Packet, err error) {
	var PacketLength int32
	var PacketBuf []byte

	PacketLength, err = ReadVarInt(r)
	if err != nil {
		return Packet{}, err
	}

	p.ID, err = ReadVarInt(r)
	if err != nil {
		return Packet{}, err
	}

	PacketBuf = make([]byte, PacketLength-int32(VarIntSize(p.ID)))
	_, err = io.ReadFull(r, PacketBuf)
	if err != nil {
		return Packet{}, err
	}

	p.Data = *bytes.NewBuffer(PacketBuf)

	return p, nil
}

func SendPacket(w io.Writer, p Packet) (err error) {
	var PacketLength int
	var PacketBuf bytes.Buffer

	err = WriteVarInt(&PacketBuf, p.ID)
	if err != nil {
		return err
	}

	_, err = PacketBuf.ReadFrom(&p.Data)
	if err != nil {
		return err
	}

	PacketLength = PacketBuf.Len()

	err = WriteVarInt(w, int32(PacketLength))
	if err != nil {
		return err
	}

	_, err = io.Copy(w, &PacketBuf)
	if err != nil {
		return err
	}

	return nil
}

// https://wiki.vg/Protocol#Type:String

func ReadString(r io.Reader) (value string, err error) {
	var len int32
	var buf []byte

	len, err = ReadVarInt(r)
	if err != nil {
		return "", err
	}

	buf = make([]byte, len)

	_, err = r.Read(buf)
	if err != nil {
		return "", err
	}

	return string(buf), nil
}

func WriteString(w io.Writer, value string) (err error) {
	var len int = len(value)

	err = WriteVarInt(w, int32(len))
	if err != nil {
		return err
	}

	_, err = w.Write([]byte(value))
	if err != nil {
		return err
	}

	return nil
}
