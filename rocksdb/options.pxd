from libcpp cimport bool as cpp_bool
from libcpp.string cimport string
from libcpp.vector cimport vector
from libc.stdint cimport uint64_t
from std_memory cimport shared_ptr
from comparator cimport Comparator
from merge_operator cimport MergeOperator
from filter_policy cimport FilterPolicy
from cache cimport Cache
from logger cimport Logger
from slice_ cimport Slice
from snapshot cimport Snapshot

cdef extern from "rocksdb/options.h" namespace "rocksdb":
    ctypedef enum CompressionType:
        kNoCompression
        kSnappyCompression
        kZlibCompression
        kBZip2Compression

    ctypedef enum ReadTier:
        kReadAllTier
        kBlockCacheTier

    cdef cppclass Options:
        const Comparator* comparator
        shared_ptr[MergeOperator] merge_operator
        const FilterPolicy* filter_policy
        # TODO: compaction_filter
        # TODO: compaction_filter_factory
        cpp_bool create_if_missing
        cpp_bool error_if_exists
        cpp_bool paranoid_checks
        # TODO: env
        # TODO: info_log
        size_t write_buffer_size
        int max_write_buffer_number
        int min_write_buffer_number_to_merge
        int max_open_files
        shared_ptr[Cache] block_cache
        shared_ptr[Cache] block_cache_compressed
        size_t block_size
        int block_restart_interval
        CompressionType compression
        # TODO: compression_per_level
        # TODO: compression_opts
        # TODO: prefix_extractor
        cpp_bool whole_key_filtering
        int num_levels
        int level0_file_num_compaction_trigger
        int level0_slowdown_writes_trigger
        int level0_stop_writes_trigger
        int max_mem_compaction_level
        int target_file_size_base
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
        int db_stats_log_interval
        string db_log_dir
        string wal_dir
        cpp_bool disable_seek_compaction
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
        cpp_bool no_block_cache
        int table_cache_numshardbits
        int table_cache_remove_scan_count_limit
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
        int block_size_deviation
        cpp_bool advise_random_on_open
        # TODO: enum { NONE, NORMAL, SEQUENTIAL, WILLNEED } access_hint_on_compaction_start
        cpp_bool use_adaptive_mutex
        uint64_t bytes_per_sync
        # TODO: CompactionStyle compaction_style
        # TODO: CompactionOptionsUniversal compaction_options_universal
        cpp_bool filter_deletes
        uint64_t max_sequential_skip_in_iterations
        # TODO: memtable_factory
        # TODO: table_factory
        # TODO: table_properties_collectors
        cpp_bool inplace_update_support
        size_t inplace_update_num_locks

    cdef cppclass WriteOptions:
        cpp_bool sync
        cpp_bool disableWAL

    cdef cppclass ReadOptions:
        cpp_bool verify_checksums
        cpp_bool fill_cache
        cpp_bool prefix_seek
        const Slice* prefix
        const Snapshot* snapshot
        ReadTier read_tier

    cdef cppclass FlushOptions:
        cpp_bool wait
