cdef extern from "rocksdb/env.h" namespace "rocksdb":
    cdef cppclass Logger:
        pass

    void Log(Logger*, const char*, ...) nogil except+
