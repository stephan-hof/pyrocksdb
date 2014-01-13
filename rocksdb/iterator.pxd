from libcpp cimport bool as cpp_bool
from slice_ cimport Slice
from status cimport Status

cdef extern from "rocksdb/iterator.h" namespace "rocksdb":
    cdef cppclass Iterator:
        cpp_bool Valid() const
        void SeekToFirst()
        void SeekToLast()
        void Seek(const Slice&)
        void Next()
        void Prev()
        Slice key() const
        Slice value() const
        Status status() const
