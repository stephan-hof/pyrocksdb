from libcpp.string cimport string
from slice_ cimport Slice
cdef extern from "rocksdb/comparator.h" namespace "rocksdb":
    cdef cppclass Comparator:
        const char* Name()
        int Compare(const Slice&, const Slice&) const

    cdef extern const Comparator* BytewiseComparator() nogil except +

ctypedef int (*compare_func)(void*, const Slice&, const Slice&)

cdef extern from "cpp/comparator_wrapper.hpp" namespace "py_rocks":
    cdef cppclass ComparatorWrapper:
        ComparatorWrapper(string, void*, compare_func) nogil except +
