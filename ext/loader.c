#include "ruby.h"
#include "stdio.h"

#define zero INT2NUM(0)
#define dlen INT2NUM(4)
static const char* codekey = "xjz_iseqs";
static const char* reskey = "xjz_res";

// get a number(data length) from data string
VALUE take_len(VALUE *str, VALUE len, VALUE fmt) {
  VALUE len_str = rb_funcall(*str, rb_intern("slice!"), 2, zero, len);
  VALUE unpack_ary = rb_funcall(len_str, rb_intern("unpack"), 1, fmt);
  return RARRAY_AREF(unpack_ary, 0);
}

int is_code_path(VALUE path) {
  return rb_funcall(path, rb_intern("end_with?"), 1, rb_str_new_cstr(".rb")) == Qtrue;
}

// load binary data from file
VALUE read_data_from_path(VALUE path) {
  VALUE Zlib_cls = rb_const_get(rb_cObject, rb_intern("Zlib"));
  VALUE Inflate_cls = rb_const_get(Zlib_cls, rb_intern("Inflate"));
  VALUE file = rb_funcall(rb_cFile, rb_intern("open"), 2, path, rb_str_new_cstr("rb"));
  VALUE data = rb_funcall(file, rb_intern("read"), 0);
  rb_funcall(file, rb_intern("close"), 0);
  rb_funcall(data, rb_intern("force_encoding"), 1, rb_str_new_cstr("binary"));
  VALUE rand_len = take_len(&data, INT2NUM(1), rb_str_new_cstr("C"));

  rb_funcall(data, rb_intern("slice!"), 2, zero, rand_len);
  rb_funcall(data, rb_intern("slice!"), 2, INT2NUM(-NUM2INT(rand_len)), rand_len);

  // default is binary encoding
  return rb_funcall(Inflate_cls, rb_intern("inflate"), 1, data);
}

VALUE take_data(VALUE *str) {
  VALUE is_utf8 = take_len(str, INT2NUM(1), rb_str_new_cstr("C"));
  VALUE len = take_len(str, dlen, rb_str_new_cstr("N"));
  VALUE data = rb_funcall(*str, rb_intern("slice!"), 2, zero, len);

  if (is_utf8) {
    rb_funcall(data, rb_intern("force_encoding"), 1, rb_str_new_cstr("utf-8"));
  }
  return data;
}

VALUE get_vm_iseq_cls() {
  VALUE rbvm = rb_const_get(rb_cObject, rb_intern("RubyVM"));
  return rb_const_get(rbvm, rb_intern("InstructionSequence"));
}

void init_data(VALUE *code_str) {
  VALUE code = rb_hash_new();
  VALUE res = rb_hash_new();
  VALUE vmiseq_cls = get_vm_iseq_cls();

  while (NUM2INT(rb_str_length(*code_str)) > 0) {
    VALUE k = take_data(code_str);
    VALUE v = Qnil;

    if (is_code_path(k)) {
      v = rb_funcall(
        vmiseq_cls, rb_intern("load_from_binary"), 1, take_data(code_str)
      );
      rb_hash_aset(code, k, v);
    } else {
      v = take_data(code_str);
      rb_hash_aset(res, k, v);
    }
  }
  rb_ivar_set(rb_cObject, rb_intern(codekey), code);
  rb_ivar_set(rb_cObject, rb_intern(reskey), res);
}

VALUE init_app(VALUE self) {
  VALUE App = rb_const_get(rb_cObject, rb_intern("XjzLoader"));
  VALUE root_path = rb_funcall(App, rb_intern("root"), 0);
  VALUE data_path = rb_file_expand_path(rb_str_new_cstr("./data"), root_path);

  VALUE data_str = read_data_from_path(data_path);
  init_data(&data_str);
  return self;
}

VALUE get_res(VALUE self, VALUE path) {
  VALUE data = rb_ivar_get(rb_cObject, rb_intern(reskey));
  return rb_hash_aref(data, path);
}

VALUE has_res(VALUE self, VALUE path) {
  VALUE data = rb_ivar_get(rb_cObject, rb_intern(reskey));

  if (RB_TYPE_P(path, T_STRING)) {
    if (rb_hash_aref(data, path) != Qnil) {
      return path;
    } else {
      return Qnil;
    }
  } else if (RB_TYPE_P(path, T_REGEXP)) {
    VALUE keys = rb_funcall(data, rb_intern("keys"), 0);
    VALUE k;
    int i, len = RARRAY_LENINT(keys);
    for (i = 0; i < len; i++) {
      k = RARRAY_AREF(keys, i);
      if (rb_funcall(path, rb_intern("match?"), 1, k) == Qtrue) {
        return k;
      }
    }
  }

  return Qnil;
}

VALUE load_code(VALUE self, VALUE path) {
  VALUE data = rb_ivar_get(rb_cObject, rb_intern(codekey));
  VALUE iseq = rb_hash_aref(data, path);

  if (iseq == Qnil) {
    printf("[ERR] Not found path %s\n", RSTRING_PTR(path));
  }
  
  if (iseq != Qnil) {
    rb_funcall(data, rb_intern("delete"), 1, path);
    rb_funcall(iseq, rb_intern("eval"), 0);
    
    return Qtrue;
  } else {
    return Qfalse;
  }
}

VALUE delete_code(VALUE self, VALUE path) {
  VALUE data = rb_ivar_get(rb_cObject, rb_intern(codekey));
  rb_funcall(data, rb_intern("delete"), 1, path);
  return Qtrue;
}

VALUE load_all_code(VALUE self) {
  VALUE iseqs = rb_ivar_get(rb_cObject, rb_intern(codekey));
  VALUE data = rb_funcall(iseqs, rb_intern("sort"), 0);
  VALUE iseq = Qnil;
  VALUE path = Qnil;

  int len = RARRAY_LENINT(data);
  int i;
  for (i = 0; i < len; i++) {
    path = RARRAY_AREF(RARRAY_AREF(data, i), 0);
    iseq = RARRAY_AREF(RARRAY_AREF(data, i), 1);
    rb_funcall(data, rb_intern("delete"), 1, path);
    rb_funcall(iseq, rb_intern("eval"), 0);
  }

  return Qtrue;
}

VALUE run_app(VALUE self) {
  load_code(self, rb_str_new_cstr("boot.rb"));
  return self;
}

VALUE start_app(VALUE self) {
  init_app(self);
  run_app(self);
  return Qnil;
}

VALUE load_app_code(VALUE self, VALUE path) {
  VALUE App = rb_const_get(rb_cObject, rb_intern("XjzLoader"));
  VALUE root_path = rb_funcall(App, rb_intern("root"), 0);

  if (rb_funcall(path, rb_intern("start_with?"), 1, rb_str_new_cstr("xjz/")) == Qtrue) {
    path = rb_str_concat(rb_str_new_cstr("src/"), path);
  } else if (rb_funcall(path, rb_intern("start_with?"), 1, rb_str_new_cstr("./")) == Qtrue) {
    path = rb_str_substr(path, 2, RSTRING_LEN(path) - 2);
  } else if (rb_funcall(path, rb_intern("start_with?"), 1, root_path) == Qtrue) {
    VALUE len = RSTRING_LEN(root_path);
    path = rb_str_substr(path, len + 1, RSTRING_LEN(path) - len - 1);
  }

  VALUE prefix = rb_str_new_cstr(".rb");
  if (rb_funcall(path, rb_intern("end_with?"), 1, prefix) == Qfalse) {
    rb_str_concat(path, prefix);
  }
  return load_code(self, path);
}

void Init_loader() {
  rb_require("zlib");
  VALUE App = rb_define_module("XjzLoader");
  
  char *ptr = getenv("TOUCH_APP");
  if (ptr != NULL && *ptr) {
    rb_define_singleton_method(App, "init", init_app, 0);
    rb_define_singleton_method(App, "run", run_app, 0);
    rb_define_singleton_method(App, "delete_code", delete_code, 1);
  }

  rb_define_singleton_method(App, "start", start_app, 0);
  /* rb_define_singleton_method(App, "_load_file", load_code, 1); */
  rb_define_singleton_method(App, "load_file", load_app_code, 1);
  rb_define_singleton_method(App, "load_all", load_all_code, 0);
  rb_define_singleton_method(App, "get_res", get_res, 1);
  rb_define_singleton_method(App, "has_res?", has_res, 1);
}

