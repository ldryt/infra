package main

import (
	"flag"
	"log"
	"net"
)

var ConfigPath string
var GlobalConfig Config

func main() {
	ConfigPathPTR := flag.String("config", "./config.yml", "a path to the configuration file")

	flag.Parse()

	ConfigPath = *ConfigPathPTR

	err := LoadConfig()
	if err != nil {
		log.Fatalln("An error occurred while loading configuration:", err)
	}

	listener, err := net.Listen("tcp4", GlobalConfig.ListenAddress)
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
