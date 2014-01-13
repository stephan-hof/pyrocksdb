from libcpp.string cimport string
from libcpp cimport bool as cpp_bool
from cpython.string cimport PyString_Size
from cpython.string cimport PyString_AsString
from cpython.string cimport PyString_FromStringAndSize

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

cdef inline Slice str_to_slice(str ob):
    return Slice(PyString_AsString(ob), PyString_Size(ob))

cdef inline str slice_to_str(Slice ob):
    return PyString_FromStringAndSize(ob.data(), ob.size())
