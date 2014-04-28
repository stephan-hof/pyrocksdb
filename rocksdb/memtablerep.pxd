from libc.stdint cimport int32_t

cdef extern from "rocksdb/memtablerep.h" namespace "rocksdb":
    cdef cppclass MemTableRepFactory:
        MemTableRepFactory()

    cdef MemTableRepFactory* NewHashSkipListRepFactory(size_t, int32_t, int32_t)
    cdef MemTableRepFactory* NewHashLinkListRepFactory(size_t)

cdef extern from "cpp/memtable_factories.hpp" namespace "py_rocks":
    cdef MemTableRepFactory* NewVectorRepFactory(size_t)
    cdef MemTableRepFactory* NewSkipListFactory()
