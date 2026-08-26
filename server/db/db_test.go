package db_test

import (
	"database/sql"
	"os"
	"testing"

	sdb "github.com/robinsr/taggedfilebrowser/server/db"
	_ "modernc.org/sqlite"
)

func makeTestDB(t *testing.T) string {
	t.Helper()
	f, err := os.CreateTemp("", "test*.sqlite")
	if err != nil {
		t.Fatal(err)
	}
	f.Close()

	w, err := sql.Open("sqlite", "file:"+f.Name())
	if err != nil {
		t.Fatal(err)
	}
	w.Exec("CREATE TABLE test (id TEXT PRIMARY KEY)")
	w.Exec("INSERT INTO test VALUES ('row1')")
	w.Close()
	return f.Name()
}

func TestOpen_ReturnsDB(t *testing.T) {
	path := makeTestDB(t)
	defer os.Remove(path)

	db, err := sdb.Open(path)
	if err != nil {
		t.Fatalf("Open failed: %v", err)
	}
	defer db.Close()
}

func TestOpen_ReadOnly(t *testing.T) {
	path := makeTestDB(t)
	defer os.Remove(path)

	db, err := sdb.Open(path)
	if err != nil {
		t.Fatal(err)
	}
	defer db.Close()

	_, err = db.Exec("INSERT INTO test VALUES ('x')")
	if err == nil {
		t.Fatal("expected INSERT to fail on read-only connection")
	}
}

func TestOpen_CanRead(t *testing.T) {
	path := makeTestDB(t)
	defer os.Remove(path)

	db, err := sdb.Open(path)
	if err != nil {
		t.Fatal(err)
	}
	defer db.Close()

	var id string
	err = db.QueryRow("SELECT id FROM test LIMIT 1").Scan(&id)
	if err != nil {
		t.Fatalf("SELECT failed: %v", err)
	}
	if id != "row1" {
		t.Errorf("got %q, want %q", id, "row1")
	}
}
