package main

import (
	"flag"
	"log"
	"net"
)

var (
	ConfigPath          string
	TerraformExecPath   string
	TerraformWorkingDir string

	GlobalConfig Config
)

func main() {
	ConfigPathPTR := flag.String("config", "./config.yml", "a path to the configuration file")
	TerraformExecPathPTR := flag.String("tfexec", "terraform", "a path to the terraform executable binary")
	TerraformWorkingDirPTR := flag.String("tfdir", "./.", "a path to the terraform working directory")

	flag.Parse()

	ConfigPath = *ConfigPathPTR
	TerraformExecPath = *TerraformExecPathPTR
	TerraformWorkingDir = *TerraformWorkingDirPTR

	log.Println("Loading configuration...")
	err := LoadConfig()
	if err != nil {
		log.Fatalln("An error occurred while loading configuration:", err)
	}

	log.Println("Initializing Terraform...")
	err = InitTF()
	if err != nil {
		log.Fatalln("An error occurred while applying the terraform configuration:", err)
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
