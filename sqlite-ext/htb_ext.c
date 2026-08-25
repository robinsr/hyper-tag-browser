/* sqlite-ext/htb_ext.c — HyperTagBrowser custom SQLite functions */
#include <sqlite3ext.h>
SQLITE_EXTENSION_INIT1

#include <stdio.h>
#include <string.h>
#include <stdint.h>
#include <stdlib.h>

/* ── concatGroup aggregate ─────────────────────────────────────────── */

typedef struct {
    char   *buf;
    size_t  len;
    size_t  cap;
    int     count;
} ConcatCtx;

static void concat_group_step(sqlite3_context *ctx, int argc, sqlite3_value **argv) {
    (void)argc;
    ConcatCtx *p = sqlite3_aggregate_context(ctx, sizeof(ConcatCtx));
    if (!p) return;

    const char *val = (const char *)sqlite3_value_text(argv[0]);
    if (!val) return;
    size_t val_len = strlen(val);

    const char *sep     = ",";
    size_t      sep_len = 1;

    size_t needed = p->len + (p->count > 0 ? sep_len : 0) + val_len + 1;
    if (needed > p->cap) {
        size_t new_cap = needed * 2 + 64;
        char  *new_buf = sqlite3_realloc(p->buf, (int)new_cap);
        if (!new_buf) { sqlite3_result_error_nomem(ctx); return; }
        p->buf = new_buf;
        p->cap = new_cap;
    }

    if (p->count > 0) {
        memcpy(p->buf + p->len, sep, sep_len);
        p->len += sep_len;
    }
    memcpy(p->buf + p->len, val, val_len);
    p->len += val_len;
    p->buf[p->len] = '\0';
    p->count++;
}

static void concat_group_final(sqlite3_context *ctx) {
    ConcatCtx *p = sqlite3_aggregate_context(ctx, 0);
    if (p && p->buf) {
        sqlite3_result_text(ctx, p->buf, (int)p->len, sqlite3_free);
        p->buf = NULL;
    } else {
        sqlite3_result_null(ctx);
    }
}

/* ── textConcat scalar ─────────────────────────────────────────────── */

static void text_concat(sqlite3_context *ctx, int argc, sqlite3_value **argv) {
    size_t total = 0;
    for (int i = 0; i < argc; i++) {
        const char *s = (const char *)sqlite3_value_text(argv[i]);
        if (s) total += strlen(s);
    }
    char *out = sqlite3_malloc((int)total + 1);
    if (!out) { sqlite3_result_error_nomem(ctx); return; }
    size_t pos = 0;
    for (int i = 0; i < argc; i++) {
        const char *s = (const char *)sqlite3_value_text(argv[i]);
        if (s) { size_t n = strlen(s); memcpy(out + pos, s, n); pos += n; }
    }
    out[pos] = '\0';
    sqlite3_result_text(ctx, out, (int)pos, sqlite3_free);
}

/* ── textJoin scalar ───────────────────────────────────────────────── */

static void text_join(sqlite3_context *ctx, int argc, sqlite3_value **argv) {
    if (argc < 1) { sqlite3_result_null(ctx); return; }
    const char *sep     = (const char *)sqlite3_value_text(argv[0]);
    if (!sep) sep = "";
    size_t      sep_len = strlen(sep);

    size_t total = 0;
    int    count = 0;
    for (int i = 1; i < argc; i++) {
        const char *s = (const char *)sqlite3_value_text(argv[i]);
        if (s) { total += strlen(s); count++; }
    }
    if (count > 1) total += sep_len * (size_t)(count - 1);

    char *out = sqlite3_malloc((int)total + 1);
    if (!out) { sqlite3_result_error_nomem(ctx); return; }
    size_t pos   = 0;
    int    first = 1;
    for (int i = 1; i < argc; i++) {
        const char *s = (const char *)sqlite3_value_text(argv[i]);
        if (s) {
            if (!first) { memcpy(out + pos, sep, sep_len); pos += sep_len; }
            size_t n = strlen(s);
            memcpy(out + pos, s, n);
            pos += n;
            first = 0;
        }
    }
    out[pos] = '\0';
    sqlite3_result_text(ctx, out, (int)pos, sqlite3_free);
}

/* ── hashId scalar (FNV-1a 64-bit) ────────────────────────────────── */

static uint64_t fnv1a64(const char *data, size_t len) {
    uint64_t h = 14695981039346656037ULL;
    for (size_t i = 0; i < len; i++) {
        h ^= (uint8_t)data[i];
        h *= 1099511628211ULL;
    }
    return h;
}

static void hash_id(sqlite3_context *ctx, int argc, sqlite3_value **argv) {
    size_t total = 0;
    for (int i = 0; i < argc; i++) {
        const char *s = (const char *)sqlite3_value_text(argv[i]);
        if (s) total += strlen(s);
    }
    char *buf = sqlite3_malloc((int)total + 1);
    if (!buf) { sqlite3_result_error_nomem(ctx); return; }
    size_t pos = 0;
    for (int i = 0; i < argc; i++) {
        const char *s = (const char *)sqlite3_value_text(argv[i]);
        if (s) { size_t n = strlen(s); memcpy(buf + pos, s, n); pos += n; }
    }
    buf[pos] = '\0';
    uint64_t h = fnv1a64(buf, pos);
    sqlite3_free(buf);
    char hex[17];
    snprintf(hex, sizeof(hex), "%016llx", (unsigned long long)h);
    sqlite3_result_text(ctx, hex, 16, SQLITE_TRANSIENT);
}

/* ── regexp functions ──────────────────────────────────────────────── */

#include <regex.h>

static void regexp_match(sqlite3_context *ctx, int argc, sqlite3_value **argv) {
    (void)argc;
    const char *text    = (const char *)sqlite3_value_text(argv[0]);
    const char *pattern = (const char *)sqlite3_value_text(argv[1]);
    if (!text || !pattern) { sqlite3_result_null(ctx); return; }

    regex_t re;
    if (regcomp(&re, pattern, REG_EXTENDED | REG_NOSUB) != 0) {
        sqlite3_result_null(ctx);
        return;
    }
    int matched = (regexec(&re, text, 0, NULL, 0) == 0) ? 1 : 0;
    regfree(&re);
    sqlite3_result_int(ctx, matched);
}

static void regexp_capture(sqlite3_context *ctx, int argc, sqlite3_value **argv) {
    (void)argc;
    const char *text    = (const char *)sqlite3_value_text(argv[0]);
    const char *pattern = (const char *)sqlite3_value_text(argv[1]);
    int         index   = sqlite3_value_int(argv[2]);
    if (!text || !pattern || index < 0) { sqlite3_result_null(ctx); return; }

    regex_t re;
    if (regcomp(&re, pattern, REG_EXTENDED) != 0) {
        sqlite3_result_null(ctx);
        return;
    }

    size_t     nmatch  = (size_t)(index + 1);
    regmatch_t *matches = sqlite3_malloc((int)(nmatch * sizeof(regmatch_t)));
    if (!matches) { regfree(&re); sqlite3_result_error_nomem(ctx); return; }

    if (regexec(&re, text, nmatch, matches, 0) == 0 && matches[index].rm_so >= 0) {
        int start = matches[index].rm_so;
        int end   = matches[index].rm_eo;
        sqlite3_result_text(ctx, text + start, end - start, SQLITE_TRANSIENT);
    } else {
        sqlite3_result_null(ctx);
    }

    sqlite3_free(matches);
    regfree(&re);
}

static void regexp_replace(sqlite3_context *ctx, int argc, sqlite3_value **argv) {
    (void)argc;
    const char *text        = (const char *)sqlite3_value_text(argv[0]);
    const char *pattern     = (const char *)sqlite3_value_text(argv[1]);
    const char *replacement = (const char *)sqlite3_value_text(argv[2]);
    if (!text || !pattern || !replacement) { sqlite3_result_null(ctx); return; }

    regex_t re;
    if (regcomp(&re, pattern, REG_EXTENDED) != 0) {
        sqlite3_result_null(ctx);
        return;
    }

    regmatch_t match;
    if (regexec(&re, text, 1, &match, 0) == 0) {
        size_t pre_len  = (size_t)match.rm_so;
        size_t rep_len  = strlen(replacement);
        size_t post_len = strlen(text) - (size_t)match.rm_eo;
        size_t total    = pre_len + rep_len + post_len + 1;

        char *out = sqlite3_malloc((int)total);
        if (!out) { regfree(&re); sqlite3_result_error_nomem(ctx); return; }

        memcpy(out,                     text,        pre_len);
        memcpy(out + pre_len,           replacement, rep_len);
        memcpy(out + pre_len + rep_len, text + match.rm_eo, post_len);
        out[total - 1] = '\0';

        sqlite3_result_text(ctx, out, (int)(total - 1), sqlite3_free);
    } else {
        sqlite3_result_text(ctx, text, -1, SQLITE_TRANSIENT);
    }

    regfree(&re);
}

/* ── POSIX file functions ───────────────────────────────────────────── */

#include <sys/stat.h>
#include <sys/xattr.h>

static void file_exists(sqlite3_context *ctx, int argc, sqlite3_value **argv) {
    (void)argc;
    const char *path = (const char *)sqlite3_value_text(argv[0]);
    if (!path) { sqlite3_result_null(ctx); return; }
    struct stat st;
    sqlite3_result_int(ctx, stat(path, &st) == 0 ? 1 : 0);
}

static void file_exists_in(sqlite3_context *ctx, int argc, sqlite3_value **argv) {
    (void)argc;
    const char *folder   = (const char *)sqlite3_value_text(argv[0]);
    const char *filename = (const char *)sqlite3_value_text(argv[1]);
    if (!folder || !filename) { sqlite3_result_null(ctx); return; }

    size_t len  = strlen(folder) + strlen(filename) + 2;
    char  *path = sqlite3_malloc((int)len);
    if (!path) { sqlite3_result_error_nomem(ctx); return; }
    snprintf(path, len, "%s%s", folder, filename);

    struct stat st;
    int exists = (stat(path, &st) == 0) ? 1 : 0;
    sqlite3_free(path);
    sqlite3_result_int(ctx, exists);
}

static void file_size(sqlite3_context *ctx, int argc, sqlite3_value **argv) {
    (void)argc;
    const char *path = (const char *)sqlite3_value_text(argv[0]);
    if (!path) { sqlite3_result_null(ctx); return; }
    struct stat st;
    if (stat(path, &st) == 0) {
        sqlite3_result_int64(ctx, (sqlite3_int64)st.st_size);
    } else {
        sqlite3_result_null(ctx);
    }
}

static void xattr_get(sqlite3_context *ctx, int argc, sqlite3_value **argv) {
    (void)argc;
    const char *path = (const char *)sqlite3_value_text(argv[0]);
    const char *key  = (const char *)sqlite3_value_text(argv[1]);
    if (!path || !key) { sqlite3_result_null(ctx); return; }

    /* macOS getxattr: 4-arg form with position=0 and options=0 */
    ssize_t size = getxattr(path, key, NULL, 0, 0, 0);
    if (size < 0) { sqlite3_result_null(ctx); return; }

    char *buf = sqlite3_malloc((int)size + 1);
    if (!buf) { sqlite3_result_error_nomem(ctx); return; }

    if (getxattr(path, key, buf, (size_t)size, 0, 0) < 0) {
        sqlite3_free(buf);
        sqlite3_result_null(ctx);
        return;
    }
    buf[size] = '\0';
    sqlite3_result_text(ctx, buf, (int)size, sqlite3_free);
}

static void file_contents(sqlite3_context *ctx, int argc, sqlite3_value **argv) {
    (void)argc;
    const char *path = (const char *)sqlite3_value_text(argv[0]);
    if (!path) { sqlite3_result_null(ctx); return; }

    FILE *f = fopen(path, "rb");
    if (!f) { sqlite3_result_null(ctx); return; }

    fseek(f, 0, SEEK_END);
    long size = ftell(f);
    fseek(f, 0, SEEK_SET);

    if (size < 0) { fclose(f); sqlite3_result_null(ctx); return; }

    void *buf = sqlite3_malloc((int)size);
    if (!buf) { fclose(f); sqlite3_result_error_nomem(ctx); return; }

    if ((long)fread(buf, 1, (size_t)size, f) != size) {
        sqlite3_free(buf);
        fclose(f);
        sqlite3_result_null(ctx);
        return;
    }
    fclose(f);
    sqlite3_result_blob(ctx, buf, (int)size, sqlite3_free);
}

/* ── Core Services UTType functions ────────────────────────────────── */

#include <CoreServices/CoreServices.h>

static CFStringRef uti_for_path(const char *path) {
    const char *dot = strrchr(path, '.');
    if (!dot || dot[1] == '\0') return NULL;

    CFStringRef ext = CFStringCreateWithCString(NULL, dot + 1, kCFStringEncodingUTF8);
    if (!ext) return NULL;

    CFStringRef uti = UTTypeCreatePreferredIdentifierForTag(
        kUTTagClassFilenameExtension, ext, NULL);
    CFRelease(ext);
    return uti; /* caller must CFRelease */
}

static void file_content_type(sqlite3_context *ctx, int argc, sqlite3_value **argv) {
    (void)argc;
    const char *path = (const char *)sqlite3_value_text(argv[0]);
    if (!path) { sqlite3_result_null(ctx); return; }

    CFStringRef uti = uti_for_path(path);
    if (!uti) { sqlite3_result_null(ctx); return; }

    char buf[512];
    if (CFStringGetCString(uti, buf, sizeof(buf), kCFStringEncodingUTF8)) {
        sqlite3_result_text(ctx, buf, -1, SQLITE_TRANSIENT);
    } else {
        sqlite3_result_null(ctx);
    }
    CFRelease(uti);
}

static void conforms_to(sqlite3_context *ctx, int argc, sqlite3_value **argv) {
    (void)argc;
    const char *s1 = (const char *)sqlite3_value_text(argv[0]);
    const char *s2 = (const char *)sqlite3_value_text(argv[1]);
    if (!s1 || !s2) { sqlite3_result_null(ctx); return; }

    CFStringRef uti1 = CFStringCreateWithCString(NULL, s1, kCFStringEncodingUTF8);
    CFStringRef uti2 = CFStringCreateWithCString(NULL, s2, kCFStringEncodingUTF8);
    if (!uti1 || !uti2) {
        if (uti1) CFRelease(uti1);
        if (uti2) CFRelease(uti2);
        sqlite3_result_null(ctx);
        return;
    }

    Boolean result = UTTypeConformsTo(uti1, uti2);
    CFRelease(uti1);
    CFRelease(uti2);
    sqlite3_result_int(ctx, result ? 1 : 0);
}

static void file_conforms_to(sqlite3_context *ctx, int argc, sqlite3_value **argv) {
    (void)argc;
    const char *path    = (const char *)sqlite3_value_text(argv[0]);
    const char *uti_str = (const char *)sqlite3_value_text(argv[1]);
    if (!path || !uti_str) { sqlite3_result_null(ctx); return; }

    CFStringRef file_uti = uti_for_path(path);
    if (!file_uti) { sqlite3_result_null(ctx); return; }

    CFStringRef target = CFStringCreateWithCString(NULL, uti_str, kCFStringEncodingUTF8);
    if (!target) { CFRelease(file_uti); sqlite3_result_null(ctx); return; }

    Boolean result = UTTypeConformsTo(file_uti, target);
    CFRelease(file_uti);
    CFRelease(target);
    sqlite3_result_int(ctx, result ? 1 : 0);
}

/* ── Extension entry point ─────────────────────────────────────────── */

#ifdef _WIN32
__declspec(dllexport)
#endif
int sqlite3_htbext_init(
    sqlite3 *db, char **pzErrMsg, const sqlite3_api_routines *pApi
) {
    SQLITE_EXTENSION_INIT2(pApi);
    (void)pzErrMsg;

    /* text / aggregate */
    sqlite3_create_function(db, "concatGroup", 1,  SQLITE_UTF8|SQLITE_DETERMINISTIC, NULL, NULL, concat_group_step, concat_group_final);
    sqlite3_create_function(db, "textConcat",  -1, SQLITE_UTF8|SQLITE_DETERMINISTIC, NULL, text_concat, NULL, NULL);
    sqlite3_create_function(db, "textJoin",    -1, SQLITE_UTF8|SQLITE_DETERMINISTIC, NULL, text_join,   NULL, NULL);
    sqlite3_create_function(db, "hashId",      -1, SQLITE_UTF8|SQLITE_DETERMINISTIC, NULL, hash_id,     NULL, NULL);

    /* regexp */
    sqlite3_create_function(db, "regexpMatch",   2, SQLITE_UTF8, NULL, regexp_match,   NULL, NULL);
    sqlite3_create_function(db, "regexpCapture", 3, SQLITE_UTF8, NULL, regexp_capture, NULL, NULL);
    sqlite3_create_function(db, "regexpReplace", 3, SQLITE_UTF8, NULL, regexp_replace, NULL, NULL);

    /* POSIX file */
    sqlite3_create_function(db, "fileExists",   1, SQLITE_UTF8, NULL, file_exists,    NULL, NULL);
    sqlite3_create_function(db, "fileExistsIn", 2, SQLITE_UTF8, NULL, file_exists_in, NULL, NULL);
    sqlite3_create_function(db, "fileSize",     1, SQLITE_UTF8, NULL, file_size,      NULL, NULL);
    sqlite3_create_function(db, "xattr",        2, SQLITE_UTF8, NULL, xattr_get,      NULL, NULL);
    sqlite3_create_function(db, "fileContents", 1, SQLITE_UTF8, NULL, file_contents,  NULL, NULL);

    /* Core Services UTType */
    sqlite3_create_function(db, "fileContentType", 1, SQLITE_UTF8, NULL, file_content_type, NULL, NULL);
    sqlite3_create_function(db, "conformsTo",      2, SQLITE_UTF8, NULL, conforms_to,       NULL, NULL);
    sqlite3_create_function(db, "fileConformsTo",  2, SQLITE_UTF8, NULL, file_conforms_to,  NULL, NULL);

    return SQLITE_OK;
}
