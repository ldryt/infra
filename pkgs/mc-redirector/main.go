package main

import (
	"encoding/base64"
	"log"
	"net"
	"os"

	"gopkg.in/yaml.v3"
)

var ConfigPath string = "./config.yml"
var slconf ServerListConfig

type ServerListConfig struct {
	Version     string `yaml:"name"`
	Protocol    int    `yaml:"protocol"`
	Motd        string `yaml:"motd"`
	FaviconPath string `yaml:"favicon_path"`
	FaviconB64  string
}

func init() {
	yamlFile, err := os.ReadFile(ConfigPath)
	if err != nil {
		log.Fatalf("An error occurred while reading %s: %s\n", ConfigPath, err)
	}

	err = yaml.Unmarshal(yamlFile, &slconf)
	if err != nil {
		log.Fatalf("An error occurred while unmarshalling %s: %s\n", ConfigPath, err)
	}

	faviconRAW, err := os.ReadFile(slconf.FaviconPath)
	if err != nil {
		slconf.FaviconB64 = ""
	} else {
		slconf.FaviconB64 = "data:image/png;base64," + base64.StdEncoding.EncodeToString(faviconRAW)
	}
}

func main() {
	listener, err := net.Listen("tcp", "0.0.0.0:25565")
	if err != nil {
		log.Fatalln("An error occurred while creating listener:", err)
	}
	defer listener.Close()

	log.Println("Server listening on", listener.Addr())

	for {
		conn, err := listener.Accept()
		if err != nil {
			log.Println("An error occurred while accepting connection:", err)
			continue
		}

		go handleClient(conn)
	}
}

func handleClient(conn net.Conn) {
	defer func() {
		log.Println("Connection closed on:", conn.RemoteAddr())
		conn.Close()
	}()

	var hd HandshakeData

	log.Println("Connection established on", conn.RemoteAddr())

	hd, err := handleHandshake(conn)
	if err != nil {
		log.Printf(
			"An error occurred while handshaking on %s: %s\n",
			conn.RemoteAddr(),
			err,
		)
		return
	}

	log.Printf("Handshaked with %s:", conn.RemoteAddr())
	log.Printf(" -- Protocol Version: %d", hd.ProtocolVersion)
	log.Printf(" -- Server Address: %s", hd.ServerAddress)
	log.Printf(" -- Server Port: %d", hd.ServerPort)
	log.Printf(" -- Next State: %d", hd.NextState)

	switch hd.NextState {
	case 1:
		err = handleStatus(conn)
		if err != nil {
			log.Printf(
				"An error occurred while handling status request on %s: %s\n",
				conn.RemoteAddr(),
				err,
			)
			return
		}
		log.Printf("Received status request from %s", conn.RemoteAddr())

		err = sendStatus(conn, slconf)
		if err != nil {
			log.Printf(
				"An error occurred while sending status response on %s: %s\n",
				conn.RemoteAddr(),
				err,
			)
			return
		}
		log.Printf("Sent status response to %s", conn.RemoteAddr())

		payload, err := handlePing(conn)
		if err != nil {
			log.Printf(
				"An error occurred while handling ping request on %s: %s\n",
				conn.RemoteAddr(),
				err,
			)
			return
		}
		log.Printf("Received ping request from %s", conn.RemoteAddr())
		log.Println(" -- Payload:", payload)

		err = sendPong(conn, payload)
		if err != nil {
			log.Printf(
				"An error occurred while sending pong response on %s: %s\n",
				conn.RemoteAddr(),
				err,
			)
			return
		}
		log.Printf("Sent pong response to %s", conn.RemoteAddr())
	case 2:
		_, err = handleLogin(conn)
		if err != nil {
			log.Printf(
				"An error occurred while handling login start request on %s: %s\n",
				conn.RemoteAddr(),
				err,
			)
			return
		}
		log.Printf("Received login request from %s", conn.RemoteAddr())

		err = sendDisconnect(conn)
		if err != nil {
			log.Printf(
				"An error occurred while sending disconnect on %s: %s\n",
				conn.RemoteAddr(),
				err,
			)
			return
		}
		log.Printf("Sent login disconnect to %s", conn.RemoteAddr())
	}
}
