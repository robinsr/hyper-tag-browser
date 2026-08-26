package queries

import (
	"context"
	"database/sql"
)

type SavedQueryRow struct {
	ID        string
	Name      string
	Query     string // raw JSON from app_saved_content_queries.query
	CreatedAt string
	UpdatedAt string
}

func GetSavedQuery(ctx context.Context, db *sql.DB, id string) (*SavedQueryRow, error) {
	const q = `SELECT id, name, query, createdAt, updatedAt FROM app_saved_content_queries WHERE id = ?`
	row := db.QueryRowContext(ctx, q, id)
	r := &SavedQueryRow{}
	err := row.Scan(&r.ID, &r.Name, &r.Query, &r.CreatedAt, &r.UpdatedAt)
	if err == sql.ErrNoRows {
		return nil, nil
	}
	return r, err
}

func ListSavedQueries(ctx context.Context, db *sql.DB) ([]*SavedQueryRow, error) {
	const q = `SELECT id, name, query, createdAt, updatedAt FROM app_saved_content_queries ORDER BY name ASC`
	rows, err := db.QueryContext(ctx, q)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var out []*SavedQueryRow
	for rows.Next() {
		r := &SavedQueryRow{}
		if err := rows.Scan(&r.ID, &r.Name, &r.Query, &r.CreatedAt, &r.UpdatedAt); err != nil {
			return nil, err
		}
		out = append(out, r)
	}
	return out, rows.Err()
}
