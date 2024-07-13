package main

import (
	"encoding/binary"
	"fmt"
	"log"
	"net"
	"sync"
)

var mtx sync.Mutex

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

	log.Printf(
		"Handshaked with %v: [Protocol: %v] [Address: %v] [Port: %v] [Next State: %v]\n",
		conn.RemoteAddr(),
		hd.ProtocolVersion,
		hd.ServerAddress,
		hd.ServerPort,
		hd.NextState,
	)

	switch hd.NextState {
	case 1:
		HandleStatus(conn)
	case 2:
		HandleLogin(conn)

		mtx.Lock()
		HandleDeployment(conn)
		mtx.Unlock()
	}
}

func HandleStatus(conn net.Conn) {
	err := handleStatusRequest(conn)
	if err != nil {
		logError("handling status request", conn.RemoteAddr(), err)
		return
	}
	log.Printf("Received status request on %s", conn.RemoteAddr())

	err = sendStatusResponse(conn)
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
	log.Printf(
		"Received ping request on %s: [Payload: %v]\n",
		conn.RemoteAddr(),
		payload,
	)

	err = sendPongResponse(conn, payload)
	if err != nil {
		logError("sending pong response", conn.RemoteAddr(), err)
		return
	}
	log.Printf(
		"Sent pong response on %s: [Payload: %v]\n",
		conn.RemoteAddr(),
		payload,
	)
}

func HandleLogin(conn net.Conn) {
	player, err := handleLoginStart(conn)
	if err != nil {
		logError("handling login start request", conn.RemoteAddr(), err)
		return
	}
	log.Printf(
		"Received login request on %v: [Username: %v] [UUID: %v]\n",
		conn.RemoteAddr(),
		player.Name,
		ConvertToUUID(player.UUID.MSB, player.UUID.LSB),
	)

	err = sendDisconnect(conn)
	if err != nil {
		logError("sending disconnect", conn.RemoteAddr(), err)
		return
	}
	log.Println("Sent login disconnect on:", conn.RemoteAddr())
}

func HandleDeployment(conn net.Conn) {
	log.Printf("Client %v triggered server deployment\n", conn.RemoteAddr())

	ip, err := ApplyTF(false)
	if err != nil {
		log.Println("An error occurred while applying terraform configuration:", err)
	}

	log.Println("Server successfully deployed. IP:", ip)
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
