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

	PacketLength, err = ReadVarInt(r)
	if err != nil {
		return Packet{}, err
	}

	p.ID, err = ReadVarInt(r)
	if err != nil {
		return Packet{}, err
	}

	_, err = io.CopyN(&p.Data, r, int64(PacketLength-int32(VarIntSize(p.ID))))
	if err != nil {
		return Packet{}, err
	}

	return p, nil
}

func SendPacket(w io.Writer, p Packet) (err error) {
	var PacketLength int = VarIntSize(p.ID) + p.Data.Len()

	err = WriteVarInt(w, int32(PacketLength))
	if err != nil {
		return err
	}

	err = WriteVarInt(w, p.ID)
	if err != nil {
		return err
	}

	_, err = p.Data.WriteTo(w)
	if err != nil {
		return err
	}

	return nil
}
