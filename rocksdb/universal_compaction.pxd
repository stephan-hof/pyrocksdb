cdef extern from "rocksdb/universal_compaction.h" namespace "rocksdb":

    ctypedef enum CompactionStopStyle:
        kCompactionStopStyleSimilarSize
        kCompactionStopStyleTotalSize

    cdef cppclass CompactionOptionsUniversal:
        CompactionOptionsUniversal()

        unsigned int size_ratio
        unsigned int min_merge_width
        unsigned int max_merge_width
        unsigned int max_size_amplification_percent
        int compression_size_percent
        CompactionStopStyle stop_style
