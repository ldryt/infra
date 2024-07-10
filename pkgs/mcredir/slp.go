// https://wiki.vg/Server_List_Ping

package main

import (
	"encoding/binary"
	"encoding/json"
	"errors"
	"io"
)

type HandshakeData struct {
	ProtocolVersion int32
	ServerAddress   string
	ServerPort      uint16
	NextState       int32
}

type PlayerData struct {
	Name string
	UUID struct {
		MSB uint64
		LSB uint64
	}
}

type StatusResponse struct {
	Version struct {
		Name     string `json:"name"`
		Protocol int    `json:"protocol"`
	} `json:"version"`
	Description struct {
		Text string `json:"text"`
	} `json:"description"`
	Favicon string `json:"favicon"`
}

func handleHandshake(r io.Reader) (h HandshakeData, err error) {
	var p Packet

	p, err = ReadPacket(r)
	if err != nil {
		return HandshakeData{}, err
	}
	if p.ID != 0 {
		return HandshakeData{}, errors.New("not an handshake packet")
	}

	h.ProtocolVersion, err = ReadVarInt(&p.Data)
	if err != nil {
		return HandshakeData{}, err
	}

	h.ServerAddress, err = ReadString(&p.Data)
	if err != nil {
		return HandshakeData{}, err
	}

	err = binary.Read(&p.Data, binary.BigEndian, &h.ServerPort)
	if err != nil {
		return HandshakeData{}, err
	}

	h.NextState, err = ReadVarInt(&p.Data)
	if err != nil {
		return HandshakeData{}, err
	}
	if !(h.NextState == 1 || h.NextState == 2) {
		return HandshakeData{}, errors.New("state is neither status or login")
	}

	return h, nil
}

func handleStatusRequest(r io.Reader) (err error) {
	var p Packet

	p, err = ReadPacket(r)
	if err != nil {
		return err
	}
	if p.ID != 0 {
		return errors.New("not a status request packet")
	}

	return nil
}

func sendStatusResponse(w io.Writer) (err error) {
	var p Packet
	var sr StatusResponse
	var srMarshalled []byte

	p.ID = 0

	sr = StatusResponse{
		Version: struct {
			Name     string `json:"name"`
			Protocol int    `json:"protocol"`
		}{
			Name:     GlobalConfig.Version.Name,
			Protocol: GlobalConfig.Version.Protocol,
		},
		Description: struct {
			Text string `json:"text"`
		}{
			Text: GlobalConfig.Motds.NotStarted,
		},
		Favicon: GlobalConfig.FaviconB64,
	}

	srMarshalled, err = json.Marshal(sr)
	if err != nil {
		return err
	}

	err = WriteString(&p.Data, string(srMarshalled))
	if err != nil {
		return err
	}

	err = SendPacket(w, p)
	if err != nil {
		return err
	}

	return nil
}

func handlePingRequest(r io.Reader) (pl int64, err error) {
	var p Packet

	p, err = ReadPacket(r)
	if err != nil {
		return 0, err
	}
	if p.ID != 1 {
		return 0, errors.New("not a ping request packet")
	}

	err = binary.Read(&p.Data, binary.BigEndian, &pl)
	if err != nil {
		return 0, err
	}

	return pl, nil
}

func sendPongResponse(w io.Writer, pl int64) (err error) {
	var p Packet

	p.ID = 1

	err = binary.Write(&p.Data, binary.BigEndian, pl)
	if err != nil {
		return err
	}

	err = SendPacket(w, p)
	if err != nil {
		return err
	}

	return nil
}

func handleLoginStart(r io.Reader) (pr PlayerData, err error) {
	var p Packet

	p, err = ReadPacket(r)
	if err != nil {
		return PlayerData{}, err
	}
	if p.ID != 0 {
		return PlayerData{}, errors.New("not a login start packet")
	}

	pr.Name, err = ReadString(&p.Data)
	if err != nil {
		return PlayerData{}, err
	}

	err = binary.Read(&p.Data, binary.BigEndian, &pr.UUID.MSB)
	if err != nil {
		return PlayerData{}, err
	}
	err = binary.Read(&p.Data, binary.BigEndian, &pr.UUID.LSB)
	if err != nil {
		return PlayerData{}, err
	}

	return pr, nil
}

func sendDisconnect(w io.Writer) (err error) {
	var p Packet

	p.ID = 0

	err = WriteString(&p.Data, "No")
	if err != nil {
		return err
	}

	err = SendPacket(w, p)
	if err != nil {
		return err
	}

	return nil
}
