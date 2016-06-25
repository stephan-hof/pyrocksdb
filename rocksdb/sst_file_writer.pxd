cimport options
from slice_ cimport Slice
from status cimport Status
from libcpp.string cimport string
from libc.stdint cimport uint64_t, int32_t

from env cimport EnvOptions
from comparator cimport Comparator
from options cimport ImmutableCFOptions, Options


cdef extern from "rocksdb/sst_file_writer.h" namespace "rocksdb":
    ctypedef uint64_t SequenceNumber

    cdef struct ExternalSstFileInfo:
        string file_path
        string smallest_key
        string largest_key
        SequenceNumber sequence_number
        uint64_t file_size
        uint64_t num_entries
        int32_t version

    cdef cppclass SstFileWriter:
        SstFileWriter(const EnvOptions&, const Options&, const Comparator*) nogil except+
        Status Open(string) nogil except+
        Status Add(const Slice&, const Slice&) nogil except+
        Status Finish(ExternalSstFileInfo*) nogil except+
