from libcpp.string cimport string
from libcpp cimport bool as cpp_bool

cdef extern from "rocksdb/slice.h" namespace "rocksdb":
    cdef cppclass Slice:
        Slice() nogil
        Slice(const char*, size_t) nogil
        Slice(const string&) nogil
        Slice(const char*) nogil

        const char* data() nogil
        size_t size() nogil
        cpp_bool empty() nogil
        char operator[](int) nogil
        void clear() nogil
        void remove_prefix(size_t) nogil
        string ToString() nogil
        string ToString(cpp_bool) nogil
        int compare(const Slice&) nogil
        cpp_bool starts_with(const Slice&) nogil
