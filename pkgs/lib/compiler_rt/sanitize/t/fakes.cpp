#include <stdio.h>
#include <stdlib.h>

#define _GNU_SOURCE 1
#include <unwind.h>

extern "C" {
  __attribute__((weak))
  void* dlsym(void* handle, const char* symbol) {
    return nullptr;
  }

  __attribute__((weak))
  uintptr_t _Unwind_GetIP(struct _Unwind_Context*) {
    fprintf(stderr, "_Unwind_GetIP() was not supposed to be called\n");
    abort();
  }

  __attribute__((weak))
  _Unwind_Reason_Code _Unwind_Backtrace(_Unwind_Trace_Fn, void *) {
    fprintf(stderr, "_Unwind_Backtrace() was not supposed to be called\n");
    abort();
  }
}
