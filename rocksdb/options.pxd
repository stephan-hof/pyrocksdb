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
    ctypedef enum CompactionStyle:
        kCompactionStyleLevel
        kCompactionStyleUniversal

    ctypedef enum CompressionType:
        kNoCompression
        kSnappyCompression
        kZlibCompression
        kBZip2Compression
        kLZ4Compression
        kLZ4HCCompression

    ctypedef enum ReadTier:
        kReadAllTier
        kBlockCacheTier

    cdef cppclass Options:
        const Comparator* comparator
        shared_ptr[MergeOperator] merge_operator
        # TODO: compaction_filter
        # TODO: compaction_filter_factory
        cpp_bool create_if_missing
        cpp_bool error_if_exists
        cpp_bool paranoid_checks
        # TODO: env
        shared_ptr[Logger] info_log
        size_t write_buffer_size
        int max_write_buffer_number
        int min_write_buffer_number_to_merge
        int max_open_files
        CompressionType compression
        # TODO: compression_per_level
        # TODO: compression_opts
        shared_ptr[SliceTransform] prefix_extractor
        int num_levels
        int level0_file_num_compaction_trigger
        int level0_slowdown_writes_trigger
        int level0_stop_writes_trigger
        int max_mem_compaction_level
        uint64_t target_file_size_base
        int target_file_size_multiplier
        uint64_t max_bytes_for_level_base
        int max_bytes_for_level_multiplier
        vector[int] max_bytes_for_level_multiplier_additional
        int expanded_compaction_factor
        int source_compaction_factor
        int max_grandparent_overlap_factor
        # TODO: statistics
        cpp_bool disableDataSync
        cpp_bool use_fsync
        string db_log_dir
        string wal_dir
        uint64_t delete_obsolete_files_period_micros
        int max_background_compactions
        int max_background_flushes
        size_t max_log_file_size
        size_t log_file_time_to_roll
        size_t keep_log_file_num
        double soft_rate_limit
        double hard_rate_limit
        unsigned int rate_limit_delay_max_milliseconds
        uint64_t max_manifest_file_size
        int table_cache_numshardbits
        size_t arena_block_size
        # TODO: PrepareForBulkLoad()
        cpp_bool disable_auto_compactions
        uint64_t WAL_ttl_seconds
        uint64_t WAL_size_limit_MB
        size_t manifest_preallocation_size
        cpp_bool purge_redundant_kvs_while_flush
        cpp_bool allow_os_buffer
        cpp_bool allow_mmap_reads
        cpp_bool allow_mmap_writes
        cpp_bool is_fd_close_on_exec
        cpp_bool skip_log_error_on_recovery
        unsigned int stats_dump_period_sec
        cpp_bool advise_random_on_open
        # TODO: enum { NONE, NORMAL, SEQUENTIAL, WILLNEED } access_hint_on_compaction_start
        cpp_bool use_adaptive_mutex
        uint64_t bytes_per_sync
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
        shared_ptr[Cache] row_cache

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
