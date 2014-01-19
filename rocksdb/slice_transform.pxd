from slice_ cimport Slice
from libcpp.string cimport string
from libcpp cimport bool as cpp_bool

cdef extern from "rocksdb/slice_transform.h" namespace "rocksdb":
    cdef cppclass SliceTransform:
        pass

ctypedef Slice (*transform_func)(void*, const Slice&)
ctypedef cpp_bool (*in_domain_func)(void*, const Slice&)
ctypedef cpp_bool (*in_range_func)(void*, const Slice&)

cdef extern from "cpp/slice_transform_wrapper.hpp" namespace "py_rocks":
    cdef cppclass SliceTransformWrapper:
        SliceTransformWrapper(
                string name,
                void*,
                transform_func,
                in_domain_func,
                in_range_func) nogil except+
