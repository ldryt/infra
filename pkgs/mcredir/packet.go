package main

import (
	"bytes"
	"io"
)

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
