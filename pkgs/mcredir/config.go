package main

import (
	"encoding/base64"
	"log"
	"os"

	"gopkg.in/yaml.v3"
)

type Config struct {
	ListenAddress string `yaml:"listen-address"`

	Minecraft struct {
		Version     string `yaml:"version"`
		Protocol    int    `yaml:"protocol"`
		Motd        string `yaml:"motd"`
		FaviconPath string `yaml:"favicon_path"`
		FaviconB64  string
	} `yaml:"mc"`
}

func getConfig() (conf Config) {
	var ConfigPath string = "./config.yml"

	if len(os.Args) != 1 {
		ConfigPath = os.Args[1]
	}

	yamlFile, err := os.ReadFile(ConfigPath)
	if err != nil {
		log.Fatalln("Failed to load config:", err)
	}

	err = yaml.Unmarshal(yamlFile, &conf)
	if err != nil {
		log.Fatalln("Failed to parse config:", err)
	}
	conf.Minecraft.FaviconB64, err = encodeFavicon(conf.Minecraft.FaviconPath)
	if err != nil {
		log.Println("Failed to encode favicon:", err)
	}

	return conf
}

func encodeFavicon(path string) (result string, err error) {
	faviconRAW, err := os.ReadFile(path)
	if err != nil {
		return "", err
	}

	return "data:image/png;base64," + base64.StdEncoding.EncodeToString(faviconRAW), nil
}
