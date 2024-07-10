package main

import (
	"encoding/base64"
	"fmt"
	"os"

	"gopkg.in/yaml.v3"
)

type Config struct {
	ListenAddress string `yaml:"listen-address"`

	Version struct {
		Name     string `yaml:"name"`
		Protocol int    `yaml:"protocol"`
	} `yaml:"version"`

	Motds struct {
		NotStarted string `yaml:"not_started"`
		Starting   string `yaml:"starting"`
	}

	FaviconPath string `yaml:"favicon"`
	FaviconB64  string
}

func LoadConfig() (err error) {
	yamlFile, err := os.ReadFile(ConfigPath)
	if err != nil {
		return fmt.Errorf("couldn't load config: %v", err)
	}

	err = yaml.Unmarshal(yamlFile, &GlobalConfig)
	if err != nil {
		return fmt.Errorf("couldn't parse config: %v", err)
	}

	if GlobalConfig.FaviconPath == "" {
		return nil
	}

	GlobalConfig.FaviconB64, err = encodeFavicon(GlobalConfig.FaviconPath)
	if err != nil {
		return fmt.Errorf("couldn't encode favicon: %v", err)
	}

	return nil
}

func encodeFavicon(path string) (result string, err error) {
	faviconRAW, err := os.ReadFile(path)
	if err != nil {
		return "", err
	}

	return "data:image/png;base64," + base64.StdEncoding.EncodeToString(faviconRAW), nil
}
