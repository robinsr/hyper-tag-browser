package queries

import (
	"context"
	"database/sql"
	"strings"
)

// Tag mirrors the app_content_tags columns returned by query functions.
type Tag struct {
	ID        string
	TagValue  string
	TagType   string
	EntryType string
	RelatedID *string
}

func GetTag(ctx context.Context, db *sql.DB, id string) (*Tag, error) {
	const q = `SELECT id, tagValue, tagType, entryType, relatedId FROM app_content_tags WHERE id = ?`
	row := db.QueryRowContext(ctx, q, id)
	t := &Tag{}
	err := row.Scan(&t.ID, &t.TagValue, &t.TagType, &t.EntryType, &t.RelatedID)
	if err == sql.ErrNoRows {
		return nil, nil
	}
	return t, err
}

// ListTags returns tags filtered by domain (tagType group) or exact tagType.
// domain is a TagDomain name: "descriptive", "attribution", "queue", "unlabeled", "creation".
// tagType is a TagType raw value: "tag", "artist", etc.
func ListTags(ctx context.Context, db *sql.DB, domain *string, tagType *string) ([]*Tag, error) {
	q := `SELECT id, tagValue, tagType, entryType, relatedId FROM app_content_tags`
	var clauses []string
	var args []any

	if tagType != nil {
		clauses = append(clauses, "tagType = ?")
		args = append(args, *tagType)
	} else if domain != nil {
		types := tagTypesForDomain(*domain)
		if len(types) > 0 {
			placeholders := make([]string, len(types))
			for i, tp := range types {
				placeholders[i] = "?"
				args = append(args, tp)
			}
			clauses = append(clauses, "tagType IN ("+strings.Join(placeholders, ",")+")")
		}
	}

	if len(clauses) > 0 {
		q += " WHERE " + strings.Join(clauses, " AND ")
	}
	q += " ORDER BY tagValue ASC"

	rows, err := db.QueryContext(ctx, q, args...)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	return scanTags(rows)
}

func ListTagsForFile(ctx context.Context, db *sql.DB, fileID string) ([]*Tag, error) {
	const q = `
		SELECT t.id, t.tagValue, t.tagType, t.entryType, t.relatedId
		FROM app_content_tags t
		JOIN app_content_tag_items ti ON ti.tagId = t.id
		WHERE ti.contentId = ?
		ORDER BY t.tagValue ASC`
	rows, err := db.QueryContext(ctx, q, fileID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	return scanTags(rows)
}

func CountFilesForTag(ctx context.Context, db *sql.DB, tagID string) (int, error) {
	var count int
	err := db.QueryRowContext(ctx,
		"SELECT COUNT(*) FROM app_content_tag_items WHERE tagId = ?", tagID).Scan(&count)
	return count, err
}

func ListFilesForTag(ctx context.Context, db *sql.DB, tagID string, first int, after string) (*FileList, error) {
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

	var total int
	db.QueryRowContext(ctx,
		"SELECT COUNT(*) FROM app_content_tag_items WHERE tagId = ?", tagID).Scan(&total)

	q := `SELECT i.rowid, i.id, i.name, i.location, i.volume, i.type, i.size,
				 i.created, i.modified, i.comment, i.visibility
		  FROM app_content_indices i
		  JOIN app_content_tag_items ti ON ti.contentId = i.id
		  WHERE ti.tagId = ?`
	args := []any{tagID}
	if afterRowID > 0 {
		q += " AND i.rowid > ?"
		args = append(args, afterRowID)
	}
	q += " ORDER BY i.rowid ASC LIMIT ?"
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

func ListAliasesForTag(ctx context.Context, db *sql.DB, tagID string) ([]*Tag, error) {
	const q = `SELECT id, tagValue, tagType, entryType, relatedId FROM app_content_tags
			   WHERE relatedId = ? ORDER BY tagValue ASC`
	rows, err := db.QueryContext(ctx, q, tagID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	return scanTags(rows)
}

// tagTypesForDomain maps TagDomain names to tagType raw values stored in SQLite.
// These match FilteringTag.TagType.rawValue in Swift.
func tagTypesForDomain(domain string) []string {
	switch strings.ToLower(domain) {
	case "descriptive":
		return []string{"tag"}
	case "attribution":
		return []string{"artist", "creator", "contributor", "owner"}
	case "queue":
		return []string{"queue"}
	case "unlabeled":
		return []string{"related"}
	case "creation":
		return []string{"createdBefore", "createdOnOrBefore", "createdOn", "createdOnOrAfter", "createdAfter"}
	}
	return nil
}

func scanTags(rows *sql.Rows) ([]*Tag, error) {
	var tags []*Tag
	for rows.Next() {
		t := &Tag{}
		if err := rows.Scan(&t.ID, &t.TagValue, &t.TagType, &t.EntryType, &t.RelatedID); err != nil {
			return nil, err
		}
		tags = append(tags, t)
	}
	return tags, rows.Err()
}
