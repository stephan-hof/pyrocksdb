from std_memory cimport shared_ptr

cdef extern from "rocksdb/cache.h" namespace "rocksdb":
    cdef cppclass Cache:
        pass

    cdef extern shared_ptr[Cache] NewLRUCache(size_t)
    cdef extern shared_ptr[Cache] NewLRUCache(size_t, int)
