package main

import (
	"log"
	"net"
)

func main() {
	listener, err := net.Listen("tcp4", getConfig().ListenAddress)
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

		go HandleClient(conn)
	}
}
