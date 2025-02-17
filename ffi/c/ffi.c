#include <lean/lean.h>
#include <sqlite3.h>
#include <stdio.h>

uint32_t myAdd(uint32_t a, uint32_t b) {
  printf("a = %d, b = %d\n", a, b);
  return a + b;
}

lean_obj_res myLeanFun() {
  return lean_io_result_mk_ok(lean_box(0));
}

lean_external_class* g_sqlite_object_external_class = NULL;

void noop_foreach(void* mod, b_lean_obj_arg fn) {}

lean_object* box_connection(sqlite3 *conn) {
  return lean_alloc_external(g_sqlite_object_external_class, conn);
}

sqlite3* unbox_connection(lean_object *o) {
  return (sqlite3*)lean_get_external_data(o);
}

void connection_finalize(void* conn) {
  if (!conn) return;

  sqlite3_close(conn);
}

lean_obj_res lean_sqlite_initialize() {
  g_sqlite_object_external_class = lean_register_external_class(connection_finalize, noop_foreach);

  return lean_io_result_mk_ok(lean_box(0));
}

lean_obj_res lean_sqlite_open(b_lean_obj_arg path) {
  const char* path_str = lean_string_cstr(path);
  sqlite3* conn = malloc(sizeof(sqlite3*));

  int c = sqlite3_open(path_str, &conn);

  if (c == SQLITE_OK)
    return lean_io_result_mk_ok(box_connection(conn));

  lean_object *err = lean_mk_string(sqlite3_errmsg(conn));

  sqlite3_close(conn);

  return lean_io_result_mk_error(lean_mk_io_error_other_error(c, err));
}

/* lean_obj_res lean_sqlite3_prepare(b_lean_obj_arg db, b_lean_obj_arg statement) {
  const char* stmt_str = lean_string_cstr(statement);



  return lean_io_result_mk_ok(box());
} */

int callback(void *NotUsed, int argc, char **argv, char **azColName){
  int i;
  for(i=0; i<argc; i++){
    printf("%s = %s\n", azColName[i], argv[i] ? argv[i] : "NULL");
  }
  printf("\n");
  return 0;
}

uint32_t wasd(uint32_t a) {
  printf("hello world\n");

  sqlite3 *db;
  char *zErrMsg = 0;
  int err;

  err = sqlite3_open("test.sqlite3", &db);
  if (err != SQLITE_OK) {
    fprintf(stderr, "Can't open database: %s\n", sqlite3_errmsg(db));
    sqlite3_close(db);
    return(1);
  }

  err = sqlite3_exec(db, "select 1 = 1;", callback, 0, &zErrMsg);
  if (err != SQLITE_OK) {
    fprintf(stderr, "SQL error: %s\n", zErrMsg);
    sqlite3_free(zErrMsg);
  }

  sqlite3_close(db);

  return a;
}
