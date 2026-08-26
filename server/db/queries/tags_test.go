package queries_test

import (
	"context"
	"testing"

	"github.com/robinsr/taggedfilebrowser/server/db/queries"
	"github.com/robinsr/taggedfilebrowser/server/db/queries/testutil"
)

func TestGetTag_Found(t *testing.T) {
	db := testutil.NewTestDB(t)
	tag, err := queries.GetTag(context.Background(), db, "tag:t001")
	if err != nil {
		t.Fatal(err)
	}
	if tag == nil {
		t.Fatal("expected tag, got nil")
	}
	if tag.TagValue != "vacation" {
		t.Errorf("tagValue: got %q, want vacation", tag.TagValue)
	}
	if tag.TagType != "tag" {
		t.Errorf("tagType: got %q, want tag", tag.TagType)
	}
}

func TestListTags_All(t *testing.T) {
	db := testutil.NewTestDB(t)
	tags, err := queries.ListTags(context.Background(), db, nil, nil)
	if err != nil {
		t.Fatal(err)
	}
	if len(tags) != 2 {
		t.Errorf("got %d tags, want 2", len(tags))
	}
}

func TestListTags_FilterByDomain(t *testing.T) {
	db := testutil.NewTestDB(t)
	domain := "attribution"
	tags, err := queries.ListTags(context.Background(), db, &domain, nil)
	if err != nil {
		t.Fatal(err)
	}
	// fixture has one 'artist' tag which is in attribution domain
	if len(tags) != 1 {
		t.Errorf("got %d attribution tags, want 1", len(tags))
	}
	if tags[0].TagType != "artist" {
		t.Errorf("tagType: got %q, want artist", tags[0].TagType)
	}
}

func TestListTagsForFile(t *testing.T) {
	db := testutil.NewTestDB(t)
	tags, err := queries.ListTagsForFile(context.Background(), db, "file:abc001")
	if err != nil {
		t.Fatal(err)
	}
	if len(tags) != 2 {
		t.Errorf("got %d tags for file:abc001, want 2", len(tags))
	}
}

func TestCountFilesForTag(t *testing.T) {
	db := testutil.NewTestDB(t)
	count, err := queries.CountFilesForTag(context.Background(), db, "tag:t001")
	if err != nil {
		t.Fatal(err)
	}
	if count != 1 {
		t.Errorf("got %d, want 1", count)
	}
}
