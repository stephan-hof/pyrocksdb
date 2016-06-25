from libc.stdint cimport int64_t

cdef extern from "rocksdb/rate_limiter.h" namespace "rocksdb":
    cdef cppclass RateLimiter:
        pass
