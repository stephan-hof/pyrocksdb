from libcpp.string cimport string
from libcpp cimport bool as cpp_bool

cdef extern from "rocksdb/slice.h" namespace "rocksdb":
    cdef cppclass Slice:
        Slice()
        Slice(const char*, size_t)
        Slice(const string&)
        Slice(const char*)

        const char* data()
        size_t size()
        cpp_bool empty()
        char operator[](int)
        void clear()
        void remove_prefix(size_t)
        string ToString()
        string ToString(cpp_bool)
        int compare(const Slice&)
        cpp_bool starts_with(const Slice&)
