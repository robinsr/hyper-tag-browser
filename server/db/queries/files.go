package queries

import (
	"context"
	"database/sql"
	"encoding/base64"
	"fmt"
	"strconv"
	"strings"
)

// File mirrors the app_content_indices columns returned by query functions.
type File struct {
	ID         string
	Name       string
	Location   string
	Volume     string
	Type       string
	Size       int64
	Created    string // stored as UTC datetime string, passed to GraphQL DateTime scalar as-is
	Modified   string
	Comment    string
	Visibility string
	RowID      int64 // used for cursor-based pagination
}

type FileList struct {
	Files       []*File
	TotalCount  int
	HasNext     bool
	StartCursor string
	EndCursor   string
}

// FileFilter holds parsed values from FileFilterInput for SQL construction.
type FileFilter struct {
	Root       string   // location prefix; empty = no filter
	Traversal  string   // "RECURSIVE" or "FLAT" (empty = FLAT default)
	SortOrder  string   // e.g. "NAME_ASC"
	Visibility string   // "normal", "hidden", "lost", "ANY" (empty = no filter)
	Types      []string // UTType identifier strings
}

func GetFile(ctx context.Context, db *sql.DB, id string) (*File, error) {
	const q = `
		SELECT rowid, id, name, location, volume, type, size, created, modified, comment, visibility
		FROM app_content_indices
		WHERE id = ?`
	row := db.QueryRowContext(ctx, q, id)
	f := &File{}
	err := row.Scan(&f.RowID, &f.ID, &f.Name, &f.Location, &f.Volume,
		&f.Type, &f.Size, &f.Created, &f.Modified, &f.Comment, &f.Visibility)
	if err == sql.ErrNoRows {
		return nil, nil
	}
	return f, err
}

// ListFiles returns a page of files.
// Cursor is base64(rowid). first defaults to 20 if <= 0.
func ListFiles(ctx context.Context, db *sql.DB, filter FileFilter, first int, after string) (*FileList, error) {
	if first <= 0 {
		first = 20
	}

	var afterRowID int64
	if after != "" {
		var err error
		afterRowID, err = DecodeCursorToRowID(after)
		if err != nil {
			return nil, err
		}
	}

	where, args := buildFileWhere(filter, afterRowID)
	orderBy := sortOrderToSQL(filter.SortOrder)

	countQ := "SELECT COUNT(*) FROM app_content_indices" + baseWhere(filter)
	var total int
	db.QueryRowContext(ctx, countQ, baseArgs(filter)...).Scan(&total)

	q := fmt.Sprintf(
		`SELECT rowid, id, name, location, volume, type, size, created, modified, comment, visibility
		 FROM app_content_indices %s ORDER BY %s LIMIT ?`,
		where, orderBy,
	)
	args = append(args, first+1)

	rows, err := db.QueryContext(ctx, q, args...)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var files []*File
	for rows.Next() {
		f := &File{}
		if err := rows.Scan(&f.RowID, &f.ID, &f.Name, &f.Location, &f.Volume,
			&f.Type, &f.Size, &f.Created, &f.Modified, &f.Comment, &f.Visibility); err != nil {
			return nil, err
		}
		files = append(files, f)
	}

	hasNext := len(files) > first
	if hasNext {
		files = files[:first]
	}

	var startCursor, endCursor string
	if len(files) > 0 {
		startCursor = EncodeCursorFromRowID(files[0].RowID)
		endCursor = EncodeCursorFromRowID(files[len(files)-1].RowID)
	}

	return &FileList{
		Files: files, TotalCount: total,
		HasNext: hasNext, StartCursor: startCursor, EndCursor: endCursor,
	}, nil
}

func EncodeCursorFromRowID(rowID int64) string {
	return base64.StdEncoding.EncodeToString([]byte(strconv.FormatInt(rowID, 10)))
}

func DecodeCursorToRowID(cursor string) (int64, error) {
	b, err := base64.StdEncoding.DecodeString(cursor)
	if err != nil {
		return 0, fmt.Errorf("invalid cursor: %w", err)
	}
	return strconv.ParseInt(string(b), 10, 64)
}

func GetFileTagCount(ctx context.Context, db *sql.DB, fileID string) (int, error) {
	var count int
	err := db.QueryRowContext(ctx,
		"SELECT COUNT(*) FROM app_content_tag_items WHERE contentId = ?", fileID).Scan(&count)
	return count, err
}

func IsFileBookmarked(ctx context.Context, db *sql.DB, fileID string) (bool, error) {
	var count int
	err := db.QueryRowContext(ctx,
		"SELECT COUNT(*) FROM app_bookmarks WHERE contentId = ?", fileID).Scan(&count)
	return count > 0, err
}

func baseWhere(f FileFilter) string {
	clauses := fileFilterClauses(f)
	if len(clauses) == 0 {
		return ""
	}
	return " WHERE " + strings.Join(clauses, " AND ")
}

func baseArgs(f FileFilter) []any {
	var args []any
	if f.Root != "" {
		args = append(args, f.Root+"%")
		if f.Traversal != "RECURSIVE" {
			args = append(args, f.Root+"/%")
		}
	}
	if f.Visibility != "" && f.Visibility != "ANY" {
		args = append(args, strings.ToLower(f.Visibility))
	}
	for _, t := range f.Types {
		args = append(args, t)
	}
	return args
}

func buildFileWhere(f FileFilter, afterRowID int64) (string, []any) {
	clauses := fileFilterClauses(f)
	args := baseArgs(f)
	if afterRowID > 0 {
		clauses = append(clauses, "rowid > ?")
		args = append(args, afterRowID)
	}
	if len(clauses) == 0 {
		return "", args
	}
	return " WHERE " + strings.Join(clauses, " AND "), args
}

func fileFilterClauses(f FileFilter) []string {
	var clauses []string
	if f.Root != "" {
		if f.Traversal == "RECURSIVE" {
			clauses = append(clauses, "location LIKE ?")
		} else {
			clauses = append(clauses, "location LIKE ? AND location NOT LIKE ?")
		}
	}
	if f.Visibility != "" && f.Visibility != "ANY" {
		clauses = append(clauses, "visibility = ?")
	}
	if len(f.Types) > 0 {
		placeholders := make([]string, len(f.Types))
		for i := range f.Types {
			placeholders[i] = "?"
		}
		clauses = append(clauses, "type IN ("+strings.Join(placeholders, ",")+")")
	}
	return clauses
}

func sortOrderToSQL(order string) string {
	switch order {
	case "NAME_ASC":
		return "name ASC"
	case "NAME_DESC":
		return "name DESC"
	case "CREATED_ASC":
		return "created ASC"
	case "CREATED_DESC":
		return "created DESC"
	case "MODIFIED_ASC":
		return "modified ASC"
	case "MODIFIED_DESC":
		return "modified DESC"
	case "SIZE_ASC":
		return "size ASC"
	case "SIZE_DESC":
		return "size DESC"
	default:
		return "rowid ASC"
	}
}
