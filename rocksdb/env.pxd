from libcpp cimport bool as cpp_bool
from rate_limiter cimport RateLimiter


cdef extern from "rocksdb/env.h" namespace "rocksdb":
    cdef cppclass Env:
        Env()

    cdef Env* Env_Default "rocksdb::Env::Default"()

    cdef struct EnvOptions:
        EnvOptions()
        # TODO: EnvOptions(DBOptions&)
        cpp_bool use_os_buffer
        cpp_bool use_mmap_reads
        cpp_bool use_mmap_writes
        # cpp_bool use_direct_reads
        # cpp_bool use_direct_writes
        cpp_bool allow_fallocate
        cpp_bool set_fd_cloexec
        cpp_bool bytes_per_sync
        cpp_bool fallocate_with_keep_size
        size_t compaction_readahead_size
        size_t random_access_max_buffer_size
        RateLimiter* rate_limiter
