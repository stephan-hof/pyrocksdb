from libcpp cimport bool as cpp_bool
from libcpp.string cimport string

cdef extern from "rocksdb/status.h" namespace "rocksdb":
    cdef cppclass Status:
        Status()
        cpp_bool ok() const
        cpp_bool IsNotFound() const
        cpp_bool IsCorruption() const
        cpp_bool IsNotSupported() const
        cpp_bool IsInvalidArgument() const
        cpp_bool IsIOError() const
        cpp_bool IsMergeInProgress() const
        cpp_bool IsIncomplete() const
        string ToString() const
