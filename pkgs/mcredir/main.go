package main

import (
	"flag"
	"log"
	"net"
)

var ConfigPath string
var GlobalConfig Config

var TerraformWorkingDir string

func main() {
	ConfigPathPTR := flag.String("config", "./config.yml", "a path to the configuration file")
	TerraformWorkingDirPTR := flag.String("tfdir", "./.", "a path to the terraform working directory")

	flag.Parse()

	ConfigPath = *ConfigPathPTR
	TerraformWorkingDir = *TerraformWorkingDirPTR

	err := LoadConfig()
	if err != nil {
		log.Fatalln("An error occurred while loading configuration:", err)
	}

	err = InitializeTF()
	if err != nil {
		log.Fatalln("An error occurred while initializing terraform:", err)
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
