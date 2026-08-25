package config_test

import (
	"os"
	"testing"
	"time"

	"github.com/robinsr/taggedfilebrowser/server/config"
)

func TestLoad(t *testing.T) {
	f, _ := os.CreateTemp("", "cfg*.json")
	f.WriteString(`{"databasePath":"/tmp/db.sqlite","port":8765,"enabled":true}`)
	f.Close()
	defer os.Remove(f.Name())

	cfg, err := config.Load(f.Name())
	if err != nil {
		t.Fatal(err)
	}
	if cfg.Port != 8765 {
		t.Errorf("port: got %d, want 8765", cfg.Port)
	}
	if cfg.DatabasePath != "/tmp/db.sqlite" {
		t.Errorf("databasePath: got %s, want /tmp/db.sqlite", cfg.DatabasePath)
	}
	if !cfg.Enabled {
		t.Error("enabled: got false, want true")
	}
}

func TestLoad_MissingFile(t *testing.T) {
	_, err := config.Load("/tmp/does-not-exist-cfg-test.json")
	if err == nil {
		t.Error("expected non-nil error for missing file, got nil")
	}
}

func TestWatch(t *testing.T) {
	f, _ := os.CreateTemp("", "cfg*.json")
	f.WriteString(`{"databasePath":"/tmp/db.sqlite","port":8765,"enabled":true}`)
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

	os.WriteFile(f.Name(), []byte(`{"databasePath":"/tmp/db.sqlite","port":9999,"enabled":false}`), 0644)

	select {
	case cfg := <-received:
		if cfg.Port != 9999 {
			t.Errorf("watch: port got %d, want 9999", cfg.Port)
		}
	case <-time.After(2 * time.Second):
		t.Fatal("watch: timed out waiting for config change")
	}
}
