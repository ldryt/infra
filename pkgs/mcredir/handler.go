package main

import (
	"encoding/binary"
	"fmt"
	"log"
	"net"
)

func HandleClient(conn net.Conn) {
	defer func() {
		log.Println("Connection closed on:", conn.RemoteAddr())
		conn.Close()
	}()

	log.Println("Connection established on", conn.RemoteAddr())

	hd, err := handleHandshake(conn)
	if err != nil {
		logError("handshaking", conn.RemoteAddr(), err)
		return
	}

	logHandshakeDetails(conn.RemoteAddr(), hd)

	switch hd.NextState {
	case 1:
		HandleStatus(conn)
	case 2:
		HandleLogin(conn)
	}
}

func HandleStatus(conn net.Conn) {
	err := handleStatusRequest(conn)
	if err != nil {
		logError("handling status request", conn.RemoteAddr(), err)
		return
	}
	log.Printf("Received status request on %s", conn.RemoteAddr())

	err = sendStatusResponse(conn, getConfig())
	if err != nil {
		logError("sending status response", conn.RemoteAddr(), err)
		return
	}
	log.Printf("Sent status response on %s", conn.RemoteAddr())

	payload, err := handlePingRequest(conn)
	if err != nil {
		logError("handling ping request", conn.RemoteAddr(), err)
		return
	}
	log.Printf("Received ping request on %s", conn.RemoteAddr())
	log.Println(" -- Payload:", payload)

	err = sendPongResponse(conn, payload)
	if err != nil {
		logError("sending pong response", conn.RemoteAddr(), err)
		log.Println(" -- Payload:", payload)
		return
	}
	log.Printf("Sent pong response on %s", conn.RemoteAddr())
	log.Println(" -- Payload:", payload)
}

func HandleLogin(conn net.Conn) {
	player, err := handleLoginStart(conn)
	if err != nil {
		logError("handling login start request", conn.RemoteAddr(), err)
		return
	}
	log.Println("Received login request on:", conn.RemoteAddr())
	log.Println(" -- Username:", player.Name)
	log.Printf(" -- UUID: %s", ConvertToUUID(player.UUID.MSB, player.UUID.LSB))

	err = sendDisconnect(conn)
	if err != nil {
		logError("sending disconnect", conn.RemoteAddr(), err)
		return
	}
	log.Println("Sent login disconnect on:", conn.RemoteAddr())
}

func ConvertToUUID(a, b uint64) string {
	var bytes [16]byte
	binary.BigEndian.PutUint64(bytes[:8], uint64(a))
	binary.BigEndian.PutUint64(bytes[8:], uint64(b))
	return fmt.Sprintf("%08x-%04x-%04x-%04x-%12x",
		bytes[0:4], bytes[4:6], bytes[6:8], bytes[8:10], bytes[10:16])
}

func logError(action string, remoteAddr net.Addr, err error) {
	log.Printf("An error occurred while %s on %s: %s\n", action, remoteAddr, err)
}

func logHandshakeDetails(remoteAddr net.Addr, hd HandshakeData) {
	log.Printf("Handshaked with %s:", remoteAddr)
	log.Printf(" -- Protocol Version: %d", hd.ProtocolVersion)
	log.Printf(" -- Server Address: %s", hd.ServerAddress)
	log.Printf(" -- Server Port: %d", hd.ServerPort)
	log.Printf(" -- Next State: %d", hd.NextState)
}