package queries_test

import (
	"context"
	"testing"

	"github.com/robinsr/taggedfilebrowser/server/db/queries"
	"github.com/robinsr/taggedfilebrowser/server/db/queries/testutil"
)

func TestGetQueue_Found(t *testing.T) {
	db := testutil.NewTestDB(t)
	q, err := queries.GetQueue(context.Background(), db, "queue:q001")
	if err != nil {
		t.Fatal(err)
	}
	if q == nil {
		t.Fatal("expected queue, got nil")
	}
	if q.Name != "To Review" {
		t.Errorf("name: got %q, want To Review", q.Name)
	}
}

func TestListQueues(t *testing.T) {
	db := testutil.NewTestDB(t)
	queues, err := queries.ListQueues(context.Background(), db)
	if err != nil {
		t.Fatal(err)
	}
	if len(queues) != 1 {
		t.Errorf("got %d queues, want 1", len(queues))
	}
}

func TestListQueueItems(t *testing.T) {
	db := testutil.NewTestDB(t)
	items, err := queries.ListQueueItems(context.Background(), db, "queue:q001")
	if err != nil {
		t.Fatal(err)
	}
	if len(items) != 1 {
		t.Fatalf("got %d items, want 1", len(items))
	}
	if items[0].File == nil || items[0].File.ID != "file:abc001" {
		t.Errorf("file.id: got %v, want file:abc001", items[0].File)
	}
	if items[0].Completed {
		t.Error("expected completed=false")
	}
}

func TestListQueuesForFile(t *testing.T) {
	db := testutil.NewTestDB(t)
	queues, err := queries.ListQueuesForFile(context.Background(), db, "file:abc001")
	if err != nil {
		t.Fatal(err)
	}
	if len(queues) != 1 {
		t.Errorf("got %d queues for file:abc001, want 1", len(queues))
	}
	if queues[0].ID != "queue:q001" {
		t.Errorf("id: got %q, want queue:q001", queues[0].ID)
	}
}
