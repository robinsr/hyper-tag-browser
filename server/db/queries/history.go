package queries

import (
	"context"
	"database/sql"
)

type HistoryRow struct {
	ID         int64
	Timestamp  string
	FsStatus   string
	IndexType  *string
	ColumnName string
	NewValue   string
	OldValue   string
}

func ListFileHistory(ctx context.Context, db *sql.DB, fileID string) ([]*HistoryRow, error) {
	const q = `
		SELECT id, timestamp, fsStatus, indexType, columnName, newValue, oldValue
		FROM app_content_indices_history
		WHERE indexId = ?
		ORDER BY timestamp DESC`
	rows, err := db.QueryContext(ctx, q, fileID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var out []*HistoryRow
	for rows.Next() {
		r := &HistoryRow{}
		if err := rows.Scan(&r.ID, &r.Timestamp, &r.FsStatus, &r.IndexType, &r.ColumnName, &r.NewValue, &r.OldValue); err != nil {
			return nil, err
		}
		out = append(out, r)
	}
	return out, rows.Err()
}
