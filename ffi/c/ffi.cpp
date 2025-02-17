#include <lean/lean.h>

extern "C" uint32_t myAdd(uint32_t a, uint32_t b) {
  return a + b + something;
}

extern "C" lean_obj_res myLeanFun() {
  return lean_io_result_mk_ok(lean_box(0));
}
