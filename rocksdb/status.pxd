from libcpp cimport bool as cpp_bool
from libcpp.string cimport string

cdef extern from "rocksdb/status.h" namespace "rocksdb":
    cdef cppclass Status:
        Status()
        cpp_bool ok() nogil
        cpp_bool IsNotFound() nogil const
        cpp_bool IsCorruption() nogil const
        cpp_bool IsNotSupported() nogil const
        cpp_bool IsInvalidArgument() nogil const
        cpp_bool IsIOError() nogil const
        cpp_bool IsMergeInProgress() nogil const
        cpp_bool IsIncomplete() nogil const
        string ToString() nogil except+
