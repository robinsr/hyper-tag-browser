package queries_test

import (
	"context"
	"testing"

	"github.com/robinsr/taggedfilebrowser/server/db/queries"
	"github.com/robinsr/taggedfilebrowser/server/db/queries/testutil"
)

func TestGetFile_Found(t *testing.T) {
	db := testutil.NewTestDB(t)
	f, err := queries.GetFile(context.Background(), db, "file:abc001")
	if err != nil {
		t.Fatal(err)
	}
	if f == nil {
		t.Fatal("expected file, got nil")
	}
	if f.Name != "photo.jpg" {
		t.Errorf("name: got %q, want %q", f.Name, "photo.jpg")
	}
	if f.Visibility != "normal" {
		t.Errorf("visibility: got %q, want %q", f.Visibility, "normal")
	}
}

func TestGetFile_NotFound(t *testing.T) {
	db := testutil.NewTestDB(t)
	f, err := queries.GetFile(context.Background(), db, "file:notexist")
	if err != nil {
		t.Fatal(err)
	}
	if f != nil {
		t.Errorf("expected nil, got %+v", f)
	}
}

func TestListFiles_Default(t *testing.T) {
	db := testutil.NewTestDB(t)
	list, err := queries.ListFiles(context.Background(), db, queries.FileFilter{}, 10, "")
	if err != nil {
		t.Fatal(err)
	}
	if list.TotalCount != 2 {
		t.Errorf("totalCount: got %d, want 2", list.TotalCount)
	}
	if len(list.Files) != 2 {
		t.Errorf("len(files): got %d, want 2", len(list.Files))
	}
}

func TestListFiles_Pagination(t *testing.T) {
	db := testutil.NewTestDB(t)
	first, err := queries.ListFiles(context.Background(), db, queries.FileFilter{}, 1, "")
	if err != nil {
		t.Fatal(err)
	}
	if len(first.Files) != 1 {
		t.Fatalf("page 1: got %d files, want 1", len(first.Files))
	}
	if !first.HasNext {
		t.Error("page 1: expected hasNext=true")
	}

	second, err := queries.ListFiles(context.Background(), db, queries.FileFilter{}, 1, first.EndCursor)
	if err != nil {
		t.Fatal(err)
	}
	if len(second.Files) != 1 {
		t.Fatalf("page 2: got %d files, want 1", len(second.Files))
	}
	if second.HasNext {
		t.Error("page 2: expected hasNext=false")
	}
}

func TestListFiles_FilterByVisibility(t *testing.T) {
	db := testutil.NewTestDB(t)
	list, err := queries.ListFiles(context.Background(), db, queries.FileFilter{Visibility: "hidden"}, 10, "")
	if err != nil {
		t.Fatal(err)
	}
	if list.TotalCount != 0 {
		t.Errorf("expected 0 hidden files, got %d", list.TotalCount)
	}
}
