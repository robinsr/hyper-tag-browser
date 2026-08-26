package resolvers

import (
	"encoding/json"
	"strconv"
	"strings"

	"github.com/robinsr/taggedfilebrowser/server/db/queries"
	"github.com/robinsr/taggedfilebrowser/server/graph/model"
)

// --- File conversions ---

func fileRowToModel(f *queries.File) *model.File {
	return &model.File{
		ID:         f.ID,
		Name:       f.Name,
		Location:   f.Location,
		Volume:     f.Volume,
		Type:       f.Type,
		Size:       int(f.Size),
		Created:    f.Created,
		Modified:   f.Modified,
		Comment:    f.Comment,
		Visibility: dbVisibilityToModel(f.Visibility),
	}
}

func dbVisibilityToModel(v string) model.FileVisibility {
	switch v {
	case "hidden":
		return model.FileVisibilityHidden
	case "lost":
		return model.FileVisibilityLost
	default:
		return model.FileVisibilityNormal
	}
}

func fileListToConnection(list *queries.FileList) *model.FileConnection {
	edges := make([]*model.FileEdge, len(list.Files))
	nodes := make([]*model.File, len(list.Files))
	for i, f := range list.Files {
		// Edge cursor uses rowid encoding to match what ListFiles expects for `after`.
		cursor := queries.EncodeCursorFromRowID(f.RowID)
		m := fileRowToModel(f)
		edges[i] = &model.FileEdge{Cursor: cursor, Node: m}
		nodes[i] = m
	}

	pageInfo := &model.PageInfo{
		HasNextPage:     list.HasNext,
		HasPreviousPage: list.StartCursor != "",
	}
	// Ruling 3: nil cursors when no results, not pointer to empty string.
	if list.StartCursor != "" {
		pageInfo.StartCursor = &list.StartCursor
	}
	if list.EndCursor != "" {
		pageInfo.EndCursor = &list.EndCursor
	}

	return &model.FileConnection{
		Edges:      edges,
		Nodes:      nodes,
		PageInfo:   pageInfo,
		TotalCount: list.TotalCount,
	}
}

func parseFileFilter(in *model.FileFilterInput) queries.FileFilter {
	if in == nil {
		return queries.FileFilter{}
	}
	f := queries.FileFilter{}
	if in.Root != nil {
		f.Root = *in.Root
	}
	if in.Traversal != nil {
		f.Traversal = string(*in.Traversal)
	}
	if in.SortBy != nil {
		f.SortOrder = string(*in.SortBy)
	}
	if in.Visibility != nil {
		f.Visibility = strings.ToLower(string(*in.Visibility))
	}
	if len(in.Types) > 0 {
		f.Types = contentTypeGroupsToUTTypes(in.Types)
	}
	return f
}

func contentTypeGroupsToUTTypes(groups []model.ContentTypeGroup) []string {
	set := map[string]struct{}{}
	for _, g := range groups {
		for _, id := range utTypesForGroup(g) {
			set[id] = struct{}{}
		}
	}
	out := make([]string, 0, len(set))
	for id := range set {
		out = append(out, id)
	}
	return out
}

func utTypesForGroup(g model.ContentTypeGroup) []string {
	switch g {
	case model.ContentTypeGroupFolders:
		return []string{"public.folder", "public.directory"}
	case model.ContentTypeGroupImages:
		return []string{"public.image", "public.jpeg", "public.png", "public.tiff",
			"org.webmproject.webp", "com.compuserve.gif", "public.heic", "public.heif", "public.heics"}
	case model.ContentTypeGroupVideo:
		return []string{"public.video", "public.mpeg-4", "com.apple.protected-mpeg-4-video",
			"com.microsoft.waveform-audio", "public.avi"}
	case model.ContentTypeGroupDatabase:
		return []string{"com.apple.sqlite3", "public.sqlite3"}
	case model.ContentTypeGroupAll:
		var all []string
		for _, sub := range []model.ContentTypeGroup{
			model.ContentTypeGroupFolders, model.ContentTypeGroupImages,
			model.ContentTypeGroupVideo, model.ContentTypeGroupDatabase,
		} {
			all = append(all, utTypesForGroup(sub)...)
		}
		return all
	default:
		return nil
	}
}

// --- Bookmark/Queue conversions ---

func bookmarkRowToModel(b *queries.BookmarkRow) *model.Bookmark {
	return &model.Bookmark{
		ID:        b.ID,
		File:      fileRowToModel(b.File),
		CreatedAt: b.Created,
	}
}

func queueRowToModel(q *queries.QueueRow, items []*queries.QueueItemRow) *model.Queue {
	modelItems := make([]*model.QueueItem, len(items))
	for i, item := range items {
		modelItems[i] = queueItemRowToModel(item)
	}
	return &model.Queue{
		ID:        q.ID,
		Name:      q.Name,
		Created:   q.Created,
		ItemCount: len(items),
		Items:     modelItems,
	}
}

func queueItemRowToModel(qi *queries.QueueItemRow) *model.QueueItem {
	return &model.QueueItem{
		ID:        qi.ID,
		File:      fileRowToModel(qi.File),
		AddedAt:   qi.Created,
		Completed: qi.Completed,
	}
}

// --- Tag conversions ---

func tagRowToModel(t *queries.Tag) *model.Tag {
	tt := dbTagTypeToModel(t.TagType)
	return &model.Tag{
		ID:        t.ID,
		TagValue:  t.TagValue,
		TagType:   tt,
		Domain:    tagTypeToDomain(tt),
		EntryType: dbEntryTypeToModel(t.EntryType),
	}
}

func dbTagTypeToModel(raw string) model.TagType {
	switch raw {
	case "tag":
		return model.TagTypeTag
	case "artist":
		return model.TagTypeArtist
	case "creator":
		return model.TagTypeCreator
	case "contributor":
		return model.TagTypeContributor
	case "owner":
		return model.TagTypeOwner
	case "queue":
		return model.TagTypeQueue
	case "related":
		return model.TagTypeRelated
	case "createdBefore":
		return model.TagTypeCreatedBefore
	case "createdOnOrBefore":
		return model.TagTypeCreatedOnOrBefore
	case "createdOn":
		return model.TagTypeCreatedOn
	case "createdOnOrAfter":
		return model.TagTypeCreatedOnOrAfter
	case "createdAfter":
		return model.TagTypeCreatedAfter
	default:
		return model.TagTypeTag
	}
}

func dbEntryTypeToModel(raw string) model.TagEntryType {
	if raw == "alias" {
		return model.TagEntryTypeAlias
	}
	return model.TagEntryTypeNormal
}

// tagTypeToDomain computes TagDomain from TagType (not stored in DB).
func tagTypeToDomain(t model.TagType) model.TagDomain {
	switch t {
	case model.TagTypeTag:
		return model.TagDomainDescriptive
	case model.TagTypeArtist, model.TagTypeCreator, model.TagTypeContributor, model.TagTypeOwner:
		return model.TagDomainAttribution
	case model.TagTypeQueue:
		return model.TagDomainQueue
	case model.TagTypeRelated:
		return model.TagDomainUnlabeled
	default:
		return model.TagDomainCreation
	}
}

// --- SavedQuery / History conversions ---

// swiftQueryJSON mirrors the JSON format stored by the Swift app in app_saved_content_queries.
type swiftQueryJSON struct {
	Root       string   `json:"root"`
	Types      []string `json:"types"`
	Visibility string   `json:"visibility"`
	SortBy     string   `json:"sortBy"`
	Mode       struct {
		Type string `json:"type"`
	} `json:"mode"`
}

func savedQueryRowToModel(sq *queries.SavedQueryRow) *model.SavedQuery {
	return &model.SavedQuery{
		ID:        sq.ID,
		Name:      sq.Name,
		Filter:    parseSavedQueryToModelFilter(sq.Query),
		CreatedAt: sq.CreatedAt,
		UpdatedAt: sq.UpdatedAt,
	}
}

func parseSavedQueryToModelFilter(jsonStr string) *model.FileFilter {
	var q swiftQueryJSON
	if err := json.Unmarshal([]byte(jsonStr), &q); err != nil {
		return &model.FileFilter{}
	}
	f := &model.FileFilter{}
	if q.Root != "" {
		f.Root = &q.Root
	}
	if v := swiftVisibilityToModel(q.Visibility); v != "" {
		f.Visibility = &v
	}
	if t := swiftTraversalToModel(q.Mode.Type); t != "" {
		f.Traversal = &t
	}
	if s := swiftSortByToModel(q.SortBy); s != "" {
		f.SortBy = &s
	}
	if len(q.Types) > 0 {
		f.Types = swiftTypesToContentTypeGroups(q.Types)
	}
	return f
}

func parseSavedQueryToDBFilter(jsonStr string) queries.FileFilter {
	var q swiftQueryJSON
	if err := json.Unmarshal([]byte(jsonStr), &q); err != nil {
		return queries.FileFilter{}
	}
	f := queries.FileFilter{Root: q.Root}
	if q.Mode.Type == "recursive" {
		f.Traversal = "RECURSIVE"
	}
	if q.Visibility != "" && strings.ToLower(q.Visibility) != "any" {
		f.Visibility = strings.ToLower(q.Visibility)
	} else if strings.ToLower(q.Visibility) == "any" {
		f.Visibility = "ANY"
	}
	if s := swiftSortByToModel(q.SortBy); s != "" {
		f.SortOrder = string(s)
	}
	if len(q.Types) > 0 {
		groups := swiftTypesToContentTypeGroups(q.Types)
		f.Types = contentTypeGroupsToUTTypes(groups)
	}
	return f
}

func swiftVisibilityToModel(v string) model.VisibilityFilter {
	switch strings.ToLower(v) {
	case "normal":
		return model.VisibilityFilterNormal
	case "hidden":
		return model.VisibilityFilterHidden
	case "lost":
		return model.VisibilityFilterLost
	case "any":
		return model.VisibilityFilterAny
	}
	return ""
}

func swiftTraversalToModel(m string) model.TraversalMode {
	if m == "recursive" {
		return model.TraversalModeRecursive
	}
	if m == "immediate" || m == "flat" {
		return model.TraversalModeFlat
	}
	return ""
}

func swiftSortByToModel(s string) model.SortOrder {
	switch s {
	case "nameAsc":
		return model.SortOrderNameAsc
	case "nameDesc":
		return model.SortOrderNameDesc
	case "createdAsc":
		return model.SortOrderCreatedAsc
	case "createdDesc":
		return model.SortOrderCreatedDesc
	case "modifiedAsc":
		return model.SortOrderModifiedAsc
	case "modifiedDesc":
		return model.SortOrderModifiedDesc
	case "sizeAsc":
		return model.SortOrderSizeAsc
	case "sizeDesc":
		return model.SortOrderSizeDesc
	}
	return ""
}

func swiftTypesToContentTypeGroups(types []string) []model.ContentTypeGroup {
	var groups []model.ContentTypeGroup
	for _, t := range types {
		switch strings.ToLower(t) {
		case "images":
			groups = append(groups, model.ContentTypeGroupImages)
		case "video":
			groups = append(groups, model.ContentTypeGroupVideo)
		case "folders":
			groups = append(groups, model.ContentTypeGroupFolders)
		case "database":
			groups = append(groups, model.ContentTypeGroupDatabase)
		case "all":
			groups = append(groups, model.ContentTypeGroupAll)
		}
	}
	return groups
}

func historyRowToModel(h *queries.HistoryRow) *model.FileHistoryEntry {
	return &model.FileHistoryEntry{
		ID:        strconv.FormatInt(h.ID, 10),
		Timestamp: h.Timestamp,
		Column:    dbColumnNameToModel(h.ColumnName),
		OldValue:  h.OldValue,
		NewValue:  h.NewValue,
		FsStatus:  dbFsStatusToModel(h.FsStatus),
		IndexType: h.IndexType,
	}
}

func dbColumnNameToModel(col string) model.HistoryColumn {
	if col == "location" {
		return model.HistoryColumnLocation
	}
	return model.HistoryColumnName
}

func dbFsStatusToModel(s string) model.FsStatus {
	switch s {
	case "synced":
		return model.FsStatusSynced
	case "failed":
		return model.FsStatusFailed
	default:
		return model.FsStatusPending
	}
}

// dbTagTypeRawValue is the inverse of dbTagTypeToModel.
func dbTagTypeRawValue(t model.TagType) string {
	switch t {
	case model.TagTypeTag:
		return "tag"
	case model.TagTypeArtist:
		return "artist"
	case model.TagTypeCreator:
		return "creator"
	case model.TagTypeContributor:
		return "contributor"
	case model.TagTypeOwner:
		return "owner"
	case model.TagTypeQueue:
		return "queue"
	case model.TagTypeRelated:
		return "related"
	case model.TagTypeCreatedBefore:
		return "createdBefore"
	case model.TagTypeCreatedOnOrBefore:
		return "createdOnOrBefore"
	case model.TagTypeCreatedOn:
		return "createdOn"
	case model.TagTypeCreatedOnOrAfter:
		return "createdOnOrAfter"
	case model.TagTypeCreatedAfter:
		return "createdAfter"
	default:
		return "tag"
	}
}
