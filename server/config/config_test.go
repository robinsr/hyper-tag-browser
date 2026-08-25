package config_test

import (
	"os"
	"testing"
	"time"

	"github.com/robinsr/taggedfilebrowser/server/config"
)

func TestLoad(t *testing.T) {
	f, _ := os.CreateTemp("", "cfg*.json")
	f.WriteString(`{"port":8765,"db_path":"/tmp/db.sqlite","log_level":"info","app_running":true}`)
	f.Close()
	defer os.Remove(f.Name())

	cfg, err := config.Load(f.Name())
	if err != nil {
		t.Fatal(err)
	}
	if cfg.Port != 8765 {
		t.Errorf("port: got %d, want 8765", cfg.Port)
	}
	if cfg.DBPath != "/tmp/db.sqlite" {
		t.Errorf("db_path: got %s, want /tmp/db.sqlite", cfg.DBPath)
	}
	if cfg.LogLevel != "info" {
		t.Errorf("log_level: got %s, want info", cfg.LogLevel)
	}
	if !cfg.AppRunning {
		t.Error("app_running: got false, want true")
	}
}

func TestWatch(t *testing.T) {
	f, _ := os.CreateTemp("", "cfg*.json")
	f.WriteString(`{"port":8765,"db_path":"/tmp/db.sqlite","log_level":"info","app_running":true}`)
	f.Close()
	defer os.Remove(f.Name())

	received := make(chan config.ServerConfig, 1)
	stop, err := config.Watch(f.Name(), func(c config.ServerConfig) {
		received <- c
	})
	if err != nil {
		t.Fatal(err)
	}
	defer stop()

	os.WriteFile(f.Name(), []byte(`{"port":9999,"db_path":"/tmp/db.sqlite","log_level":"debug","app_running":false}`), 0644)

	select {
	case cfg := <-received:
		if cfg.Port != 9999 {
			t.Errorf("watch: port got %d, want 9999", cfg.Port)
		}
	case <-time.After(2 * time.Second):
		t.Fatal("watch: timed out waiting for config change")
	}
}
