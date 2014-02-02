cdef extern from "rocksdb/env.h" namespace "rocksdb":
    cdef cppclass Env:
        Env()

    cdef Env* Env_Default "rocksdb::Env::Default"()
