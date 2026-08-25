package config

import (
	"encoding/json"
	"os"

	"github.com/fsnotify/fsnotify"
)

type ServerConfig struct {
	DatabasePath string `json:"databasePath"`
	Port         int    `json:"port"`
	Enabled      bool   `json:"enabled"`
}

func Load(path string) (ServerConfig, error) {
	data, err := os.ReadFile(path)
	if err != nil {
		return ServerConfig{}, err
	}
	var cfg ServerConfig
	return cfg, json.Unmarshal(data, &cfg)
}

// Watch monitors path for writes and calls onChange with the new config.
// Returns a stop function that closes the watcher.
func Watch(path string, onChange func(ServerConfig)) (func(), error) {
	watcher, err := fsnotify.NewWatcher()
	if err != nil {
		return nil, err
	}
	if err := watcher.Add(path); err != nil {
		watcher.Close()
		return nil, err
	}
	go func() {
		for {
			select {
			case event, ok := <-watcher.Events:
				if !ok {
					return
				}
				if event.Has(fsnotify.Write) || event.Has(fsnotify.Create) {
					if cfg, err := Load(path); err == nil {
						onChange(cfg)
					}
				}
			case _, ok := <-watcher.Errors:
				if !ok {
					return
				}
			}
		}
	}()
	return func() { watcher.Close() }, nil
}
