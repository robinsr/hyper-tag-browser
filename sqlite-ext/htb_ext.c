/* sqlite-ext/htb_ext.c — HyperTagBrowser custom SQLite functions */
#include <sqlite3ext.h>
SQLITE_EXTENSION_INIT1

#ifdef _WIN32
__declspec(dllexport)
#endif
int sqlite3_htbext_init(
    sqlite3 *db, char **pzErrMsg, const sqlite3_api_routines *pApi
) {
    SQLITE_EXTENSION_INIT2(pApi);
    (void)db; (void)pzErrMsg;
    return SQLITE_OK;
}
