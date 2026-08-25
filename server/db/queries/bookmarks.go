package queries

import (
	"context"
	"database/sql"
)

type BookmarkRow struct {
	ID      string
	Created string
	File    *File
}

func ListBookmarks(ctx context.Context, db *sql.DB) ([]*BookmarkRow, error) {
	const q = `
		SELECT b.id, b.created,
		       i.rowid, i.id, i.name, i.location, i.volume, i.type, i.size,
		       i.created, i.modified, i.comment, i.visibility
		FROM app_bookmarks b
		JOIN app_content_indices i ON i.id = b.contentId
		ORDER BY b.created DESC`
	rows, err := db.QueryContext(ctx, q)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	return scanBookmarks(rows)
}

func scanBookmarks(rows *sql.Rows) ([]*BookmarkRow, error) {
	var bookmarks []*BookmarkRow
	for rows.Next() {
		b := &BookmarkRow{File: &File{}}
		if err := rows.Scan(
			&b.ID, &b.Created,
			&b.File.RowID, &b.File.ID, &b.File.Name, &b.File.Location, &b.File.Volume,
			&b.File.Type, &b.File.Size, &b.File.Created, &b.File.Modified,
			&b.File.Comment, &b.File.Visibility,
		); err != nil {
			return nil, err
		}
		bookmarks = append(bookmarks, b)
	}
	return bookmarks, rows.Err()
}
