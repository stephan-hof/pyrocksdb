from libc.stdint cimport uint32_t
from libcpp cimport bool as cpp_bool
from std_memory cimport shared_ptr

from cache cimport Cache
from filter_policy cimport FilterPolicy

cdef extern from "rocksdb/table.h" namespace "rocksdb":
    cdef cppclass TableFactory:
        TableFactory()

    ctypedef enum BlockBasedTableIndexType:
        kBinarySearch "rocksdb::BlockBasedTableOptions::IndexType::kBinarySearch"
        kHashSearch "rocksdb::BlockBasedTableOptions::IndexType::kHashSearch"

    ctypedef enum ChecksumType:
        kCRC32c
        kxxHash

    cdef cppclass BlockBasedTableOptions:
        BlockBasedTableOptions()
        BlockBasedTableIndexType index_type
        cpp_bool hash_index_allow_collision
        ChecksumType checksum
        cpp_bool no_block_cache
        size_t block_size
        int block_size_deviation
        int block_restart_interval
        cpp_bool whole_key_filtering
        shared_ptr[Cache] block_cache
        shared_ptr[Cache] block_cache_compressed
        shared_ptr[FilterPolicy] filter_policy
        cpp_bool cache_index_and_filter_blocks

    cdef TableFactory* NewBlockBasedTableFactory(const BlockBasedTableOptions&)

    ctypedef enum EncodingType:
        kPlain
        kPrefix

    cdef cppclass PlainTableOptions:
        uint32_t user_key_len
        int bloom_bits_per_key
        double hash_table_ratio
        size_t index_sparseness
        size_t huge_page_tlb_size
        EncodingType encoding_type
        cpp_bool full_scan_mode
        cpp_bool store_index_in_file

    cdef TableFactory* NewPlainTableFactory(const PlainTableOptions&)
