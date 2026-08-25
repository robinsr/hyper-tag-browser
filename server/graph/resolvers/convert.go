package resolvers

import (
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
