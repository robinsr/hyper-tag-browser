package queries

import (
	"context"
	"database/sql"
)

type QueueRow struct {
	ID      string
	Name    string
	Created string
}

type QueueItemRow struct {
	ID        string
	QueueID   string
	Created   string
	Completed bool
	File      *File
}

func GetQueue(ctx context.Context, db *sql.DB, id string) (*QueueRow, error) {
	const q = `SELECT id, name, created FROM app_workqueues WHERE id = ?`
	row := db.QueryRowContext(ctx, q, id)
	r := &QueueRow{}
	err := row.Scan(&r.ID, &r.Name, &r.Created)
	if err == sql.ErrNoRows {
		return nil, nil
	}
	return r, err
}

func ListQueues(ctx context.Context, db *sql.DB) ([]*QueueRow, error) {
	const q = `SELECT id, name, created FROM app_workqueues ORDER BY name ASC`
	rows, err := db.QueryContext(ctx, q)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var queues []*QueueRow
	for rows.Next() {
		r := &QueueRow{}
		if err := rows.Scan(&r.ID, &r.Name, &r.Created); err != nil {
			return nil, err
		}
		queues = append(queues, r)
	}
	return queues, rows.Err()
}

func ListQueueItems(ctx context.Context, db *sql.DB, queueID string) ([]*QueueItemRow, error) {
	const q = `
		SELECT qi.id, qi.queueId, qi.created, qi.completed,
		       i.rowid, i.id, i.name, i.location, i.volume, i.type, i.size,
		       i.created, i.modified, i.comment, i.visibility
		FROM app_workqueue_items qi
		JOIN app_content_indices i ON i.id = qi.contentId
		WHERE qi.queueId = ?
		ORDER BY qi.created ASC`
	rows, err := db.QueryContext(ctx, q, queueID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	return scanQueueItems(rows)
}

func ListQueuesForFile(ctx context.Context, db *sql.DB, fileID string) ([]*QueueRow, error) {
	const q = `
		SELECT DISTINCT q.id, q.name, q.created
		FROM app_workqueues q
		JOIN app_workqueue_items qi ON qi.queueId = q.id
		WHERE qi.contentId = ?
		ORDER BY q.name ASC`
	rows, err := db.QueryContext(ctx, q, fileID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var queues []*QueueRow
	for rows.Next() {
		r := &QueueRow{}
		if err := rows.Scan(&r.ID, &r.Name, &r.Created); err != nil {
			return nil, err
		}
		queues = append(queues, r)
	}
	return queues, rows.Err()
}

func scanQueueItems(rows *sql.Rows) ([]*QueueItemRow, error) {
	var items []*QueueItemRow
	for rows.Next() {
		var completedInt int
		qi := &QueueItemRow{File: &File{}}
		if err := rows.Scan(
			&qi.ID, &qi.QueueID, &qi.Created, &completedInt,
			&qi.File.RowID, &qi.File.ID, &qi.File.Name, &qi.File.Location, &qi.File.Volume,
			&qi.File.Type, &qi.File.Size, &qi.File.Created, &qi.File.Modified,
			&qi.File.Comment, &qi.File.Visibility,
		); err != nil {
			return nil, err
		}
		qi.Completed = completedInt != 0
		items = append(items, qi)
	}
	return items, rows.Err()
}
