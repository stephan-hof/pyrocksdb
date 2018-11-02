from libcpp cimport bool as cpp_bool
from libcpp.string cimport string
from libcpp.vector cimport vector
from libc.stdint cimport uint64_t
from libc.stdint cimport uint32_t
from std_memory cimport shared_ptr
from comparator cimport Comparator
from merge_operator cimport MergeOperator
from logger cimport Logger
from slice_ cimport Slice
from snapshot cimport Snapshot
from slice_transform cimport SliceTransform
from table_factory cimport TableFactory
from memtablerep cimport MemTableRepFactory
from universal_compaction cimport CompactionOptionsUniversal
from cache cimport Cache

cdef extern from "rocksdb/options.h" namespace "rocksdb":
    cdef cppclass CompressionOptions:
        int window_bits;
        int level;
        int strategy;
        uint32_t max_dict_bytes
        CompressionOptions() except +
        CompressionOptions(int, int, int, int) except +

    ctypedef enum CompactionStyle:
        kCompactionStyleLevel
        kCompactionStyleUniversal
        kCompactionStyleFIFO
        kCompactionStyleNone

    ctypedef enum CompressionType:
        kNoCompression
        kSnappyCompression
        kZlibCompression
        kBZip2Compression
        kLZ4Compression
        kLZ4HCCompression
        kXpressCompression
        kZSTD
        kZSTDNotFinalCompression
        kDisableCompressionOption

    ctypedef enum ReadTier:
        kReadAllTier
        kBlockCacheTier

    ctypedef enum CompactionPri:
        kByCompensatedSize
        kOldestLargestSeqFirst
        kOldestSmallestSeqFirst
        kMinOverlappingRatio

    # This needs to be in _rocksdb.pxd so it will export into python
    #cpdef enum AccessHint "rocksdb::DBOptions::AccessHint":
    #    NONE,
    #    NORMAL,
    #    SEQUENTIAL,
    #    WILLNEED

    cdef cppclass DBOptions:
        cpp_bool create_if_missing
        cpp_bool create_missing_column_families
        cpp_bool error_if_exists
        cpp_bool paranoid_checks
        # TODO: env
        shared_ptr[Logger] info_log
        int max_open_files
        int max_file_opening_threads
        # TODO: statistics
        cpp_bool use_fsync
        string db_log_dir
        string wal_dir
        uint64_t delete_obsolete_files_period_micros
        int max_background_jobs
        int max_background_compactions
        uint32_t max_subcompactions
        int max_background_flushes
        size_t max_log_file_size
        size_t log_file_time_to_roll
        size_t keep_log_file_num
        size_t recycle_log_file_num
        uint64_t max_manifest_file_size
        int table_cache_numshardbits
        uint64_t WAL_ttl_seconds
        uint64_t WAL_size_limit_MB
        size_t manifest_preallocation_size
        cpp_bool allow_mmap_reads
        cpp_bool allow_mmap_writes
        cpp_bool use_direct_reads
        cpp_bool use_direct_io_for_flush_and_compaction
        cpp_bool allow_fallocate
        cpp_bool is_fd_close_on_exec
        cpp_bool skip_log_error_on_recovery
        unsigned int stats_dump_period_sec
        cpp_bool advise_random_on_open
        size_t db_write_buffer_size
        # AccessHint access_hint_on_compaction_start
        cpp_bool use_adaptive_mutex
        uint64_t bytes_per_sync
        cpp_bool allow_concurrent_memtable_write
        cpp_bool enable_write_thread_adaptive_yield
        shared_ptr[Cache] row_cache

    cdef cppclass ColumnFamilyOptions:
        ColumnFamilyOptions()
        ColumnFamilyOptions(const Options& options)
        const Comparator* comparator
        shared_ptr[MergeOperator] merge_operator
        # TODO: compaction_filter
        # TODO: compaction_filter_factory
        size_t write_buffer_size
        int max_write_buffer_number
        int min_write_buffer_number_to_merge
        CompressionType compression
        CompactionPri compaction_pri
        # TODO: compression_per_level
        shared_ptr[SliceTransform] prefix_extractor
        int num_levels
        int level0_file_num_compaction_trigger
        int level0_slowdown_writes_trigger
        int level0_stop_writes_trigger
        int max_mem_compaction_level
        uint64_t target_file_size_base
        int target_file_size_multiplier
        uint64_t max_bytes_for_level_base
        double max_bytes_for_level_multiplier
        vector[int] max_bytes_for_level_multiplier_additional
        int expanded_compaction_factor
        int source_compaction_factor
        int max_grandparent_overlap_factor
        cpp_bool disableDataSync
        double soft_rate_limit
        double hard_rate_limit
        unsigned int rate_limit_delay_max_milliseconds
        size_t arena_block_size
        # TODO: PrepareForBulkLoad()
        cpp_bool disable_auto_compactions
        cpp_bool purge_redundant_kvs_while_flush
        cpp_bool allow_os_buffer
        cpp_bool verify_checksums_in_compaction
        CompactionStyle compaction_style
        CompactionOptionsUniversal compaction_options_universal
        cpp_bool filter_deletes
        uint64_t max_sequential_skip_in_iterations
        shared_ptr[MemTableRepFactory] memtable_factory
        shared_ptr[TableFactory] table_factory
        # TODO: table_properties_collectors
        cpp_bool inplace_update_support
        size_t inplace_update_num_locks
        # TODO: remove options source_compaction_factor, max_grandparent_overlap_bytes and expanded_compaction_factor from document
        uint64_t max_compaction_bytes
        CompressionOptions compression_opts

    cdef cppclass Options(DBOptions, ColumnFamilyOptions):
        pass

    cdef cppclass WriteOptions:
        cpp_bool sync
        cpp_bool disableWAL

    cdef cppclass ReadOptions:
        cpp_bool verify_checksums
        cpp_bool fill_cache
        const Snapshot* snapshot
        ReadTier read_tier

    cdef cppclass FlushOptions:
        cpp_bool wait

    ctypedef enum BottommostLevelCompaction:
        blc_skip "rocksdb::BottommostLevelCompaction::kSkip"
        blc_is_filter "rocksdb::BottommostLevelCompaction::kIfHaveCompactionFilter"
        blc_force "rocksdb::BottommostLevelCompaction::kForce"

    cdef cppclass CompactRangeOptions:
        cpp_bool change_level
        int target_level
        uint32_t target_path_id
        BottommostLevelCompaction bottommost_level_compaction
