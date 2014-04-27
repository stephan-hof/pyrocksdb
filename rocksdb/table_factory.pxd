from libc.stdint cimport uint32_t

cdef extern from "rocksdb/table.h" namespace "rocksdb":
    cdef cppclass TableFactory:
        TableFactory()

    cdef TableFactory* NewBlockBasedTableFactory()
    cdef TableFactory* NewPlainTableFactory(uint32_t, int, double, size_t)
    cdef TableFactory* NewTotalOrderPlainTableFactory(uint32_t, int, size_t)
