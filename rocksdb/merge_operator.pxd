from libcpp.string cimport string
from libcpp cimport bool as cpp_bool
from libcpp.deque cimport deque
from slice_ cimport Slice
from logger cimport Logger
from std_memory cimport shared_ptr

cdef extern from "rocksdb/merge_operator.h" namespace "rocksdb":
    cdef cppclass MergeOperator:
        pass

#  cdef extern from  "utilities/merge_operators.h" namespace "rocksdb::MergeOperators":
cdef extern from  "utilities/merge_operators.h" namespace "rocksdb":
    cdef cppclass MergeOperators:
        @staticmethod
        shared_ptr[MergeOperator] CreatePutOperator()
        @staticmethod
        shared_ptr[MergeOperator] CreateDeprecatedPutOperator()
        @staticmethod
        shared_ptr[MergeOperator] CreateUInt64AddOperator()
        @staticmethod
        shared_ptr[MergeOperator] CreateStringAppendOperator()
        @staticmethod
        shared_ptr[MergeOperator] CreateStringAppendTESTOperator()
        @staticmethod
        shared_ptr[MergeOperator] CreateMaxOperator()
        @staticmethod
        shared_ptr[MergeOperator] CreateFromStringId(const string &)



ctypedef cpp_bool (*merge_func)(
    void*,
    const Slice&,
    const Slice*,
    const Slice&,
    string*,
    Logger*)

ctypedef cpp_bool (*full_merge_func)(
    void* ctx,
    const Slice& key,
    const Slice* existing_value,
    const deque[string]& operand_list,
    string* new_value,
    Logger* logger)

ctypedef cpp_bool (*partial_merge_func)(
    void* ctx,
    const Slice& key,
    const Slice& left_op,
    const Slice& right_op,
    string* new_value,
    Logger* logger)

cdef extern from "cpp/merge_operator_wrapper.hpp" namespace "py_rocks":
    cdef cppclass AssociativeMergeOperatorWrapper:
        AssociativeMergeOperatorWrapper(string, void*, merge_func) nogil except+

    cdef cppclass MergeOperatorWrapper:
        MergeOperatorWrapper(
            string,
            void*,
            void*,
            full_merge_func,
            partial_merge_func) nogil except+
