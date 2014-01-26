import cython
from libcpp.string cimport string
from libcpp.deque cimport deque
from libcpp.vector cimport vector
from libcpp cimport bool as cpp_bool
from cython.operator cimport dereference as deref
from cpython.bytes cimport PyBytes_AsString
from cpython.bytes cimport PyBytes_Size
from cpython.bytes cimport PyBytes_FromString
from cpython.bytes cimport PyBytes_FromStringAndSize
from cpython.unicode cimport PyUnicode_Decode

from std_memory cimport shared_ptr
cimport options
cimport merge_operator
cimport filter_policy
cimport comparator
cimport slice_transform
cimport cache
cimport logger
cimport snapshot
cimport db
cimport iterator

from slice_ cimport Slice
from status cimport Status

import sys
from interfaces import MergeOperator as IMergeOperator
from interfaces import AssociativeMergeOperator as IAssociativeMergeOperator
from interfaces import FilterPolicy as IFilterPolicy
from interfaces import Comparator as IComparator
from interfaces import SliceTransform as ISliceTransform
import traceback
import errors

cdef extern from "cpp/utils.hpp" namespace "py_rocks":
    cdef const Slice* vector_data(vector[Slice]&)

# Prepare python for threaded usage.
# Python callbacks (merge, comparator)
# could be executed in a rocksdb background thread (eg. compaction).
cdef extern from "Python.h":
    void PyEval_InitThreads()
PyEval_InitThreads()

## Here comes the stuff to wrap the status to exception
cdef check_status(const Status& st):
    if st.ok():
        return

    if st.IsNotFound():
        raise errors.NotFound(st.ToString())

    if st.IsCorruption():
        raise errors.Corruption(st.ToString())

    if st.IsNotSupported():
        raise errors.NotSupported(st.ToString())

    if st.IsInvalidArgument():
        raise errors.InvalidArgument(st.ToString())

    if st.IsIOError():
        raise errors.RocksIOError(st.ToString())

    if st.IsMergeInProgress():
        raise errors.MergeInProgress(st.ToString())

    if st.IsIncomplete():
        raise errors.Incomplete(st.ToString())

    raise Exception("Unknown error: %s" % st.ToString())
######################################################


cdef string bytes_to_string(path) except *:
    return string(PyBytes_AsString(path), PyBytes_Size(path))

cdef string_to_bytes(string ob):
    return PyBytes_FromStringAndSize(ob.c_str(), ob.size())

cdef Slice bytes_to_slice(ob) except *:
    return Slice(PyBytes_AsString(ob), PyBytes_Size(ob))

cdef slice_to_bytes(Slice sl):
    return PyBytes_FromStringAndSize(sl.data(), sl.size())

## only for filsystem paths
cdef string path_to_string(object path) except *:
    if isinstance(path, bytes):
        return bytes_to_string(path)
    if isinstance(path, unicode):
        path = path.encode(sys.getfilesystemencoding())
        return bytes_to_string(path)
    else:
       raise TypeError("Wrong type for path: %s" % path)

cdef object string_to_path(string path):
    fs_encoding = sys.getfilesystemencoding().encode('ascii')
    return PyUnicode_Decode(path.c_str(), path.size(), fs_encoding, "replace")

## Here comes the stuff for the comparator
@cython.internal
cdef class PyComparator(object):
    cdef object get_ob(self):
        return None

    cdef const comparator.Comparator* get_comparator(self):
        return NULL

    cdef set_info_log(self, shared_ptr[logger.Logger] info_log):
        pass

@cython.internal
cdef class PyGenericComparator(PyComparator):
    cdef comparator.ComparatorWrapper* comparator_ptr
    cdef object ob

    def __cinit__(self, object ob):
        self.comparator_ptr = NULL
        if not isinstance(ob, IComparator):
            # TODO: raise wrong subclass error
            raise TypeError("Cannot set comparator: %s" % ob)

        self.ob = ob
        self.comparator_ptr = new comparator.ComparatorWrapper(
                bytes_to_string(ob.name()),
                <void*>ob,
                compare_callback)

    def __dealloc__(self):
        if not self.comparator_ptr == NULL:
            del self.comparator_ptr

    cdef object get_ob(self):
        return self.ob

    cdef const comparator.Comparator* get_comparator(self):
        return <comparator.Comparator*> self.comparator_ptr

    cdef set_info_log(self, shared_ptr[logger.Logger] info_log):
        self.comparator_ptr.set_info_log(info_log)

@cython.internal
cdef class PyBytewiseComparator(PyComparator):
    cdef const comparator.Comparator* comparator_ptr

    def __cinit__(self):
        self.comparator_ptr = comparator.BytewiseComparator()

    def name(self):
        return PyBytes_FromString(self.comparator_ptr.Name())

    def compare(self, a, b):
        return self.comparator_ptr.Compare(
            bytes_to_slice(a),
            bytes_to_slice(b))

    cdef object get_ob(self):
       return self

    cdef const comparator.Comparator* get_comparator(self):
        return self.comparator_ptr

cdef int compare_callback(
    void* ctx,
    logger.Logger* log,
    string& error_msg,
    const Slice& a,
    const Slice& b) with gil:

    try:
        return (<object>ctx).compare(slice_to_bytes(a), slice_to_bytes(b))
    except BaseException as error:
        tb = traceback.format_exc()
        logger.Log(log, "Error in compare callback: %s", <bytes>tb)
        error_msg.assign(<bytes>str(error))

BytewiseComparator = PyBytewiseComparator
#########################################



## Here comes the stuff for the filter policy
@cython.internal
cdef class PyFilterPolicy(object):
    cdef object get_ob(self):
        return None

    cdef const filter_policy.FilterPolicy* get_policy(self):
        return NULL

    cdef set_info_log(self, shared_ptr[logger.Logger] info_log):
        pass

@cython.internal
cdef class PyGenericFilterPolicy(PyFilterPolicy):
    cdef filter_policy.FilterPolicyWrapper* policy
    cdef object ob

    def __cinit__(self, object ob):
        self.policy = NULL
        if not isinstance(ob, IFilterPolicy):
            raise TypeError("Cannot set filter policy: %s" % ob)

        self.ob = ob
        self.policy = new filter_policy.FilterPolicyWrapper(
                bytes_to_string(ob.name()),
                <void*>ob,
                create_filter_callback,
                key_may_match_callback)

    def __dealloc__(self):
        if not self.policy == NULL:
            del self.policy

    cdef object get_ob(self):
        return self.ob

    cdef const filter_policy.FilterPolicy* get_policy(self):
        return <filter_policy.FilterPolicy*> self.policy

    cdef set_info_log(self, shared_ptr[logger.Logger] info_log):
        self.policy.set_info_log(info_log)


cdef void create_filter_callback(
    void* ctx,
    logger.Logger* log,
    string& error_msg,
    const Slice* keys,
    int n,
    string* dst) with gil:

    try:
        ret = (<object>ctx).create_filter(
            [slice_to_bytes(keys[i]) for i in range(n)])
        dst.append(bytes_to_string(ret))
    except BaseException as error:
        tb = traceback.format_exc()
        logger.Log(log, "Error in create filter callback: %s", <bytes>tb)
        error_msg.assign(<bytes>str(error))

cdef cpp_bool key_may_match_callback(
    void* ctx,
    logger.Logger* log,
    string& error_msg,
    const Slice& key,
    const Slice& filt) with gil:

    try:
        return (<object>ctx).key_may_match(
            slice_to_bytes(key),
            slice_to_bytes(filt))
    except BaseException as error:
        tb = traceback.format_exc()
        logger.Log(log, "Error in key_mach_match callback: %s", <bytes>tb)
        error_msg.assign(<bytes>str(error))

@cython.internal
cdef class PyBloomFilterPolicy(PyFilterPolicy):
    cdef const filter_policy.FilterPolicy* policy

    def __cinit__(self, int bits_per_key):
        self.policy = NULL
        self.policy = filter_policy.NewBloomFilterPolicy(bits_per_key)

    def __dealloc__(self):
        if not self.policy == NULL:
            del self.policy

    def name(self):
        return PyBytes_FromString(self.policy.Name())

    def create_filter(self, keys):
        cdef string dst
        cdef vector[Slice] c_keys

        for key in keys:
            c_keys.push_back(bytes_to_slice(key))

        self.policy.CreateFilter(
            vector_data(c_keys),
            c_keys.size(),
            cython.address(dst))

        return string_to_bytes(dst)

    def key_may_match(self, key, filter_):
        return self.policy.KeyMayMatch(
            bytes_to_slice(key),
            bytes_to_slice(filter_))

    cdef object get_ob(self):
        return self

    cdef const filter_policy.FilterPolicy* get_policy(self):
        return self.policy

BloomFilterPolicy = PyBloomFilterPolicy
#############################################



## Here comes the stuff for the merge operator
@cython.internal
cdef class PyMergeOperator(object):
    cdef shared_ptr[merge_operator.MergeOperator] merge_op
    cdef object ob

    def __cinit__(self, object ob):
        if isinstance(ob, IAssociativeMergeOperator):
            self.ob = ob
            self.merge_op.reset(
                <merge_operator.MergeOperator*>
                    new merge_operator.AssociativeMergeOperatorWrapper(
                        bytes_to_string(ob.name()),
                        <void*>(ob),
                        merge_callback))

        elif isinstance(ob, IMergeOperator):
            self.ob = ob
            self.merge_op.reset(
                <merge_operator.MergeOperator*>
                    new merge_operator.MergeOperatorWrapper(
                        bytes_to_string(ob.name()),
                        <void*>ob,
                        <void*>ob,
                        full_merge_callback,
                        partial_merge_callback))
        else:
            raise TypeError("Cannot set MergeOperator: %s" % ob)

    cdef object get_ob(self):
        return self.ob

    cdef shared_ptr[merge_operator.MergeOperator] get_operator(self):
        return self.merge_op

cdef cpp_bool merge_callback(
    void* ctx,
    const Slice& key,
    const Slice* existing_value,
    const Slice& value,
    string* new_value,
    logger.Logger* log) with gil:

    if existing_value == NULL:
        py_existing_value = None
    else:
        py_existing_value = slice_to_bytes(deref(existing_value))

    try:
        ret = (<object>ctx).merge(
            slice_to_bytes(key),
            py_existing_value,
            slice_to_bytes(value))

        if ret[0]:
            new_value.assign(bytes_to_string(ret[1]))
            return True
        return False

    except:
        tb = traceback.format_exc()
        logger.Log(log, "Error in merge_callback: %s", <bytes>tb)
        return False

cdef cpp_bool full_merge_callback(
    void* ctx,
    const Slice& key,
    const Slice* existing_value,
    const deque[string]& op_list,
    string* new_value,
    logger.Logger* log) with gil:

    if existing_value == NULL:
        py_existing_value = None
    else:
        py_existing_value = slice_to_bytes(deref(existing_value))

    try:
        ret = (<object>ctx).full_merge(
            slice_to_bytes(key),
            py_existing_value,
            [string_to_bytes(op_list[i]) for i in range(op_list.size())])

        if ret[0]:
            new_value.assign(bytes_to_string(ret[1]))
            return True
        return False

    except:
        tb = traceback.format_exc()
        logger.Log(log, "Error in full_merge_callback: %s", <bytes>tb)
        return False

cdef cpp_bool partial_merge_callback(
    void* ctx,
    const Slice& key,
    const Slice& left_op,
    const Slice& right_op,
    string* new_value,
    logger.Logger* log) with gil:

    try:
        ret = (<object>ctx).partial_merge(
            slice_to_bytes(key),
            slice_to_bytes(left_op),
            slice_to_bytes(right_op))

        if ret[0]:
            new_value.assign(bytes_to_string(ret[1]))
            return True
        return False

    except:
        tb = traceback.format_exc()
        logger.Log(log, "Error in partial_merge_callback: %s", <bytes>tb)
        return False
##############################################

#### Here comes the Cache stuff
@cython.internal
cdef class PyCache(object):
    cdef object get_ob(self):
        return None

    cdef shared_ptr[cache.Cache] get_cache(self):
        return shared_ptr[cache.Cache]()

@cython.internal
cdef class PyLRUCache(PyCache):
    cdef shared_ptr[cache.Cache] cache_ob

    def __cinit__(self, capacity, shard_bits=None, rm_scan_count_limit=None):
        if shard_bits is not None:
            if rm_scan_count_limit is not None:
                self.cache_ob = cache.NewLRUCache(
                    capacity,
                    shard_bits,
                    rm_scan_count_limit)
            else:
                self.cache_ob = cache.NewLRUCache(capacity, shard_bits)
        else:
            self.cache_ob = cache.NewLRUCache(capacity)

    cdef object get_ob(self):
        return self

    cdef shared_ptr[cache.Cache] get_cache(self):
        return self.cache_ob

LRUCache = PyLRUCache
###############################

### Here comes the stuff for SliceTransform
@cython.internal
cdef class PySliceTransform(object):
    cdef slice_transform.SliceTransform* transfomer
    cdef object ob

    def __cinit__(self, object ob):
        self.transfomer = NULL
        if not isinstance(ob, ISliceTransform):
            raise TypeError("%s is not of type %s" % (ob, ISliceTransform))

        self.ob = ob
        self.transfomer = <slice_transform.SliceTransform*>(
            new slice_transform.SliceTransformWrapper(
                bytes_to_string(ob.name()),
                <void*>ob,
                slice_transform_callback,
                slice_in_domain_callback,
                slice_in_range_callback))

    def __dealloc__(self):
        if not self.transfomer == NULL:
            del self.transfomer

    cdef object get_ob(self):
        return self.ob

    cdef slice_transform.SliceTransform* get_transformer(self):
        return self.transfomer

cdef Slice slice_transform_callback(void* ctx, const Slice& src) with gil:
    cdef size_t offset
    cdef size_t size

    try:
        ret = (<object>ctx).transform(slice_to_bytes(src))
        offset = ret[0]
        size = ret[1]
        if (offset + size) > src.size():
            msg = "offset(%i) + size(%i) is bigger than slice(%i)"
            raise Exception(msg  % (offset, size, src.size()))

        return Slice(src.data() + offset, size)
    except Exception as error:
        print error
        # TODO: Use the rocksdb logger
        return src

cdef cpp_bool slice_in_domain_callback(void* ctx, const Slice& src) with gil:
    try:
        return (<object>ctx).in_domain(slice_to_bytes(src))
    except Exception as error:
        print error
        # TODO: Use the rocksdb logger
        return False

cdef cpp_bool slice_in_range_callback(void* ctx, const Slice& src) with gil:
    try:
        return (<object>ctx).in_range(slice_to_bytes(src))
    except Exception as error:
        print error
        # TODO: Use rocksdb logger
        return False

###########################################
cdef class CompressionType(object):
    no_compression = u'no_compression'
    snappy_compression = u'snappy_compression'
    zlib_compression = u'zlib_compression'
    bzip2_compression = u'bzip2_compression'

cdef class Options(object):
    cdef options.Options* opts
    cdef PyComparator py_comparator
    cdef PyMergeOperator py_merge_operator
    cdef PyFilterPolicy py_filter_policy
    cdef PyCache py_block_cache
    cdef PyCache py_block_cache_compressed
    cdef PySliceTransform py_prefix_extractor
    # Used to protect sharing of Options with many DB-objects
    cdef cpp_bool in_use

    def __cinit__(self):
        self.opts = NULL
        self.opts = new options.Options()
        self.in_use = False

    def __dealloc__(self):
        if not self.opts == NULL:
            del self.opts

    def __init__(self, **kwargs):
        self.py_comparator = BytewiseComparator()
        self.py_merge_operator = None
        self.py_filter_policy = None
        self.py_block_cache = None
        self.py_block_cache_compressed = None
        self.py_prefix_extractor = None

        for key, value in kwargs.items():
            setattr(self, key, value)

    property create_if_missing:
        def __get__(self):
            return self.opts.create_if_missing
        def __set__(self, value):
            self.opts.create_if_missing = value

    property error_if_exists:
        def __get__(self):
            return self.opts.error_if_exists
        def __set__(self, value):
            self.opts.error_if_exists = value

    property paranoid_checks:
        def __get__(self):
            return self.opts.paranoid_checks
        def __set__(self, value):
            self.opts.paranoid_checks = value

    property write_buffer_size:
        def __get__(self):
            return self.opts.write_buffer_size
        def __set__(self, value):
            self.opts.write_buffer_size = value

    property max_write_buffer_number:
        def __get__(self):
            return self.opts.max_write_buffer_number
        def __set__(self, value):
            self.opts.max_write_buffer_number = value

    property min_write_buffer_number_to_merge:
        def __get__(self):
            return self.opts.min_write_buffer_number_to_merge
        def __set__(self, value):
            self.opts.min_write_buffer_number_to_merge = value

    property max_open_files:
        def __get__(self):
            return self.opts.max_open_files
        def __set__(self, value):
            self.opts.max_open_files = value

    property block_size:
        def __get__(self):
            return self.opts.block_size
        def __set__(self, value):
            self.opts.block_size = value

    property block_restart_interval:
        def __get__(self):
            return self.opts.block_restart_interval
        def __set__(self, value):
            self.opts.block_restart_interval = value

    property compression:
        def __get__(self):
            if self.opts.compression == options.kNoCompression:
                return CompressionType.no_compression
            elif self.opts.compression  == options.kSnappyCompression:
                return CompressionType.snappy_compression
            elif self.opts.compression == options.kZlibCompression:
                return CompressionType.zlib_compression
            elif self.opts.compression == options.kBZip2Compression:
                return CompressionType.bzip2_compression
            else:
                raise Exception("Unknonw type: %s" % self.opts.compression)

        def __set__(self, value):
            if value == CompressionType.no_compression:
                self.opts.compression = options.kNoCompression
            elif value == CompressionType.snappy_compression:
                self.opts.compression = options.kSnappyCompression
            elif value == CompressionType.zlib_compression:
                self.opts.compression = options.kZlibCompression
            elif value == CompressionType.bzip2_compression:
                self.opts.compression = options.kBZip2Compression
            else:
                raise TypeError("Unknown compression: %s" % value)

    property whole_key_filtering:
        def __get__(self):
            return self.opts.whole_key_filtering
        def __set__(self, value):
            self.opts.whole_key_filtering = value

    property num_levels:
        def __get__(self):
            return self.opts.num_levels
        def __set__(self, value):
            self.opts.num_levels = value

    property level0_file_num_compaction_trigger:
        def __get__(self):
            return self.opts.level0_file_num_compaction_trigger
        def __set__(self, value):
            self.opts.level0_file_num_compaction_trigger = value

    property level0_slowdown_writes_trigger:
        def __get__(self):
            return self.opts.level0_slowdown_writes_trigger
        def __set__(self, value):
            self.opts.level0_slowdown_writes_trigger = value

    property level0_stop_writes_trigger:
        def __get__(self):
            return self.opts.level0_stop_writes_trigger
        def __set__(self, value):
            self.opts.level0_stop_writes_trigger = value

    property max_mem_compaction_level:
        def __get__(self):
            return self.opts.max_mem_compaction_level
        def __set__(self, value):
            self.opts.max_mem_compaction_level = value

    property target_file_size_base:
        def __get__(self):
            return self.opts.target_file_size_base
        def __set__(self, value):
            self.opts.target_file_size_base = value

    property target_file_size_multiplier:
        def __get__(self):
            return self.opts.target_file_size_multiplier
        def __set__(self, value):
            self.opts.target_file_size_multiplier = value

    property max_bytes_for_level_base:
        def __get__(self):
            return self.opts.max_bytes_for_level_base
        def __set__(self, value):
            self.opts.max_bytes_for_level_base = value

    property max_bytes_for_level_multiplier:
        def __get__(self):
            return self.opts.max_bytes_for_level_multiplier
        def __set__(self, value):
            self.opts.max_bytes_for_level_multiplier = value

    property max_bytes_for_level_multiplier_additional:
        def __get__(self):
            return self.opts.max_bytes_for_level_multiplier_additional
        def __set__(self, value):
            self.opts.max_bytes_for_level_multiplier_additional = value

    property expanded_compaction_factor:
        def __get__(self):
            return self.opts.expanded_compaction_factor
        def __set__(self, value):
            self.opts.expanded_compaction_factor = value

    property source_compaction_factor:
        def __get__(self):
            return self.opts.source_compaction_factor
        def __set__(self, value):
            self.opts.source_compaction_factor = value

    property max_grandparent_overlap_factor:
        def __get__(self):
            return self.opts.max_grandparent_overlap_factor
        def __set__(self, value):
            self.opts.max_grandparent_overlap_factor = value

    property disable_data_sync:
        def __get__(self):
            return self.opts.disableDataSync
        def __set__(self, value):
            self.opts.disableDataSync = value

    property use_fsync:
        def __get__(self):
            return self.opts.use_fsync
        def __set__(self, value):
            self.opts.use_fsync = value

    property db_stats_log_interval:
        def __get__(self):
            return self.opts.db_stats_log_interval
        def __set__(self, value):
            self.opts.db_stats_log_interval = value

    property db_log_dir:
        def __get__(self):
            return string_to_path(self.opts.db_log_dir)
        def __set__(self, value):
            self.opts.db_log_dir = path_to_string(value)

    property wal_dir:
        def __get__(self):
            return string_to_path(self.opts.wal_dir)
        def __set__(self, value):
            self.opts.wal_dir = path_to_string(value)

    property disable_seek_compaction:
        def __get__(self):
            return self.opts.disable_seek_compaction
        def __set__(self, value):
            self.opts.disable_seek_compaction = value

    property delete_obsolete_files_period_micros:
        def __get__(self):
            return self.opts.delete_obsolete_files_period_micros
        def __set__(self, value):
            self.opts.delete_obsolete_files_period_micros = value

    property max_background_compactions:
        def __get__(self):
            return self.opts.max_background_compactions
        def __set__(self, value):
            self.opts.max_background_compactions = value

    property max_background_flushes:
        def __get__(self):
            return self.opts.max_background_flushes
        def __set__(self, value):
            self.opts.max_background_flushes = value

    property max_log_file_size:
        def __get__(self):
            return self.opts.max_log_file_size
        def __set__(self, value):
            self.opts.max_log_file_size = value

    property log_file_time_to_roll:
        def __get__(self):
            return self.opts.log_file_time_to_roll
        def __set__(self, value):
            self.opts.log_file_time_to_roll = value

    property keep_log_file_num:
        def __get__(self):
            return self.opts.keep_log_file_num
        def __set__(self, value):
            self.opts.keep_log_file_num = value

    property soft_rate_limit:
        def __get__(self):
            return self.opts.soft_rate_limit
        def __set__(self, value):
            self.opts.soft_rate_limit = value

    property hard_rate_limit:
        def __get__(self):
            return self.opts.hard_rate_limit
        def __set__(self, value):
            self.opts.hard_rate_limit = value

    property rate_limit_delay_max_milliseconds:
        def __get__(self):
            return self.opts.rate_limit_delay_max_milliseconds
        def __set__(self, value):
            self.opts.rate_limit_delay_max_milliseconds = value

    property max_manifest_file_size:
        def __get__(self):
            return self.opts.max_manifest_file_size
        def __set__(self, value):
            self.opts.max_manifest_file_size = value

    property no_block_cache:
        def __get__(self):
            return self.opts.no_block_cache
        def __set__(self, value):
            self.opts.no_block_cache = value

    property table_cache_numshardbits:
        def __get__(self):
            return self.opts.table_cache_numshardbits
        def __set__(self, value):
            self.opts.table_cache_numshardbits = value

    property table_cache_remove_scan_count_limit:
        def __get__(self):
            return self.opts.table_cache_remove_scan_count_limit
        def __set__(self, value):
            self.opts.table_cache_remove_scan_count_limit = value

    property arena_block_size:
        def __get__(self):
            return self.opts.arena_block_size
        def __set__(self, value):
            self.opts.arena_block_size = value

    property disable_auto_compactions:
        def __get__(self):
            return self.opts.disable_auto_compactions
        def __set__(self, value):
            self.opts.disable_auto_compactions = value

    property wal_ttl_seconds:
        def __get__(self):
            return self.opts.WAL_ttl_seconds
        def __set__(self, value):
            self.opts.WAL_ttl_seconds = value

    property wal_size_limit_mb:
        def __get__(self):
            return self.opts.WAL_size_limit_MB
        def __set__(self, value):
            self.opts.WAL_size_limit_MB = value

    property manifest_preallocation_size:
        def __get__(self):
            return self.opts.manifest_preallocation_size
        def __set__(self, value):
            self.opts.manifest_preallocation_size = value

    property purge_redundant_kvs_while_flush:
        def __get__(self):
            return self.opts.purge_redundant_kvs_while_flush
        def __set__(self, value):
            self.opts.purge_redundant_kvs_while_flush = value

    property allow_os_buffer:
        def __get__(self):
            return self.opts.allow_os_buffer
        def __set__(self, value):
            self.opts.allow_os_buffer = value

    property allow_mmap_reads:
        def __get__(self):
            return self.opts.allow_mmap_reads
        def __set__(self, value):
            self.opts.allow_mmap_reads = value

    property allow_mmap_writes:
        def __get__(self):
            return self.opts.allow_mmap_writes
        def __set__(self, value):
            self.opts.allow_mmap_writes = value

    property is_fd_close_on_exec:
        def __get__(self):
            return self.opts.is_fd_close_on_exec
        def __set__(self, value):
            self.opts.is_fd_close_on_exec = value

    property skip_log_error_on_recovery:
        def __get__(self):
            return self.opts.skip_log_error_on_recovery
        def __set__(self, value):
            self.opts.skip_log_error_on_recovery = value

    property stats_dump_period_sec:
        def __get__(self):
            return self.opts.stats_dump_period_sec
        def __set__(self, value):
            self.opts.stats_dump_period_sec = value

    property block_size_deviation:
        def __get__(self):
            return self.opts.block_size_deviation
        def __set__(self, value):
            self.opts.block_size_deviation = value

    property advise_random_on_open:
        def __get__(self):
            return self.opts.advise_random_on_open
        def __set__(self, value):
            self.opts.advise_random_on_open = value

    property use_adaptive_mutex:
        def __get__(self):
            return self.opts.use_adaptive_mutex
        def __set__(self, value):
            self.opts.use_adaptive_mutex = value

    property bytes_per_sync:
        def __get__(self):
            return self.opts.bytes_per_sync
        def __set__(self, value):
            self.opts.bytes_per_sync = value

    property filter_deletes:
        def __get__(self):
            return self.opts.filter_deletes
        def __set__(self, value):
            self.opts.filter_deletes = value

    property max_sequential_skip_in_iterations:
        def __get__(self):
            return self.opts.max_sequential_skip_in_iterations
        def __set__(self, value):
            self.opts.max_sequential_skip_in_iterations = value

    property inplace_update_support:
        def __get__(self):
            return self.opts.inplace_update_support
        def __set__(self, value):
            self.opts.inplace_update_support = value

    property inplace_update_num_locks:
        def __get__(self):
            return self.opts.inplace_update_num_locks
        def __set__(self, value):
            self.opts.inplace_update_num_locks = value

    property comparator:
        def __get__(self):
            return self.py_comparator.get_ob()

        def __set__(self, value):
            if isinstance(value, PyComparator):
                if (<PyComparator?>value).get_comparator() == NULL:
                    raise Exception("Cannot set %s as comparator" % value)
                else:
                    self.py_comparator = value
            else:
                self.py_comparator = PyGenericComparator(value)

            self.opts.comparator = self.py_comparator.get_comparator()

    property merge_operator:
        def __get__(self):
            if self.py_merge_operator is None:
                return None
            return self.py_merge_operator.get_ob()

        def __set__(self, value):
            self.py_merge_operator = PyMergeOperator(value)
            self.opts.merge_operator = self.py_merge_operator.get_operator()

    property filter_policy:
        def __get__(self):
            if self.py_filter_policy is None:
                return None
            return self.py_filter_policy.get_ob()

        def __set__(self, value):
            if isinstance(value, PyFilterPolicy):
                if (<PyFilterPolicy?>value).get_policy() == NULL:
                    raise Exception("Cannot set filter policy: %s" % value)
                self.py_filter_policy = value
            else:
                self.py_filter_policy = PyGenericFilterPolicy(value)

            self.opts.filter_policy = self.py_filter_policy.get_policy()

    property prefix_extractor:
        def __get__(self):
            if self.py_prefix_extractor is None:
                return None
            return self.py_prefix_extractor.get_ob()

        def __set__(self, value):
            self.py_prefix_extractor = PySliceTransform(value)
            self.opts.prefix_extractor = self.py_prefix_extractor.get_transformer()

    property block_cache:
        def __get__(self):
            if self.py_block_cache is None:
                return None
            return self.py_block_cache.get_ob()

        def __set__(self, value):
            if value is None:
                self.py_block_cache = None
                self.opts.block_cache.reset()
            else:
                if not isinstance(value, PyCache):
                    raise TypeError("%s is not a Cache" % value)

                self.py_block_cache = value
                self.opts.block_cache = self.py_block_cache.get_cache()

    property block_cache_compressed:
        def __get__(self):
            if self.py_block_cache_compressed is None:
                return None
            return self.py_block_cache_compressed.get_ob()

        def __set__(self, value):
            if value is None:
                self.py_block_cache_compressed = None
                self.opts.block_cache_compressed.reset()
                return

            if not isinstance(value, PyCache):
                raise TypeError("%s is not a Cache" % value)

            self.py_block_cache_compressed = value
            self.opts.block_cache_compressed = (<PyCache>value).get_cache()

# Forward declaration
cdef class Snapshot

cdef class KeysIterator
cdef class ValuesIterator
cdef class ItemsIterator
cdef class ReversedIterator

cdef class WriteBatch(object):
    cdef db.WriteBatch* batch

    def __cinit__(self, data=None):
        self.batch = NULL
        if data is not None:
            self.batch = new db.WriteBatch(bytes_to_string(data))
        else:
            self.batch = new db.WriteBatch()

    def __dealloc__(self):
        if not self.batch == NULL:
            del self.batch

    def put(self, key, value):
        self.batch.Put(bytes_to_slice(key), bytes_to_slice(value))

    def merge(self, key, value):
        self.batch.Merge(bytes_to_slice(key), bytes_to_slice(value))

    def delete(self, key):
        self.batch.Delete(bytes_to_slice(key))

    def clear(self):
        self.batch.Clear()

    def data(self):
        return string_to_bytes(self.batch.Data())

    def count(self):
        return self.batch.Count()

@cython.no_gc_clear
cdef class DB(object):
    cdef Options opts
    cdef db.DB* db

    def __cinit__(self, db_name, Options opts, read_only=False):
        cdef Status st
        cdef string db_path
        self.db = NULL
        self.opts = None


        if opts.in_use:
            raise Exception("Options object is already used by another DB")

        db_path = path_to_string(db_name)
        if read_only:
            with nogil:
                st = db.DB_OpenForReadOnly(
                    deref(opts.opts),
                    db_path,
                    cython.address(self.db),
                    False)
        else:
            with nogil:
                st = db.DB_Open(
                    deref(opts.opts),
                    db_path,
                    cython.address(self.db))

        check_status(st)

        # Inject the loggers into the python callbacks
        cdef shared_ptr[logger.Logger] info_log = self.db.GetOptions().info_log
        if opts.py_comparator is not None:
            opts.py_comparator.set_info_log(info_log)

        if opts.py_filter_policy is not None:
            opts.py_filter_policy.set_info_log(info_log)

        self.opts = opts
        self.opts.in_use = True

    def __dealloc__(self):
        if not self.db == NULL:
            with nogil:
                del self.db

        if self.opts is not None:
            self.opts.in_use = False

    def put(self, key, value, sync=False, disable_wal=False):
        cdef Status st
        cdef options.WriteOptions opts
        opts.sync = sync
        opts.disableWAL = disable_wal

        cdef Slice c_key = bytes_to_slice(key)
        cdef Slice c_value = bytes_to_slice(value)

        with nogil:
            st = self.db.Put(opts, c_key, c_value)
        check_status(st)

    def delete(self, key, sync=False, disable_wal=False):
        cdef Status st
        cdef options.WriteOptions opts
        opts.sync = sync
        opts.disableWAL = disable_wal

        cdef Slice c_key = bytes_to_slice(key)
        with nogil:
            st = self.db.Delete(opts, c_key)
        check_status(st)

    def merge(self, key, value, sync=False, disable_wal=False):
        cdef Status st
        cdef options.WriteOptions opts
        opts.sync = sync
        opts.disableWAL = disable_wal

        cdef Slice c_key = bytes_to_slice(key)
        cdef Slice c_value = bytes_to_slice(value)
        with nogil:
            st = self.db.Merge(opts, c_key, c_value)
        check_status(st)

    def write(self, WriteBatch batch, sync=False, disable_wal=False):
        cdef Status st
        cdef options.WriteOptions opts
        opts.sync = sync
        opts.disableWAL = disable_wal

        with nogil:
            st = self.db.Write(opts, batch.batch)
        check_status(st)

    def get(self, key, *args, **kwargs):
        cdef string res
        cdef Status st
        cdef options.ReadOptions opts

        opts = self.build_read_opts(self.__parse_read_opts(*args, **kwargs))
        cdef Slice c_key = bytes_to_slice(key)

        with nogil:
            st = self.db.Get(opts, c_key, cython.address(res))

        if st.ok():
            return string_to_bytes(res)
        elif st.IsNotFound():
            return None
        else:
            check_status(st)

    def multi_get(self, keys, *args, **kwargs):
        cdef vector[string] values
        values.resize(len(keys))

        cdef vector[Slice] c_keys
        for key in keys:
            c_keys.push_back(bytes_to_slice(key))

        cdef options.ReadOptions opts
        opts = self.build_read_opts(self.__parse_read_opts(*args, **kwargs))

        cdef vector[Status] res
        with nogil:
            res = self.db.MultiGet(
                opts,
                c_keys,
                cython.address(values))

        cdef dict ret_dict = {}
        for index in range(len(keys)):
            if res[index].ok():
                ret_dict[keys[index]] = string_to_bytes(values[index])
            elif res[index].IsNotFound():
                ret_dict[keys[index]] = None
            else:
                check_status(res[index])

        return ret_dict

    def key_may_exist(self, key, fetch=False, *args, **kwargs):
        cdef string value
        cdef cpp_bool value_found
        cdef cpp_bool exists
        cdef options.ReadOptions opts
        cdef Slice c_key
        opts = self.build_read_opts(self.__parse_read_opts(*args, **kwargs))

        c_key = bytes_to_slice(key)
        exists = False

        if fetch:
            value_found = False
            with nogil:
                exists = self.db.KeyMayExist(
                    opts,
                    c_key,
                    cython.address(value),
                    cython.address(value_found))

            if exists:
                if value_found:
                    return (True, string_to_bytes(value))
                else:
                    return (True, None)
            else:
                return (False, None)
        else:
            with nogil:
                exists = self.db.KeyMayExist(
                    opts,
                    c_key,
                    cython.address(value))

            return (exists, None)

    def iterkeys(self, prefix=None, *args, **kwargs):
        cdef options.ReadOptions opts
        cdef KeysIterator it

        opts = self.build_read_opts(self.__parse_read_opts(*args, **kwargs))

        it = KeysIterator(self)
        it.set_prefix(opts, prefix)

        with nogil:
            it.ptr = self.db.NewIterator(opts)
        return it

    def itervalues(self, prefix=None, *args, **kwargs):
        cdef options.ReadOptions opts
        cdef ValuesIterator it

        opts = self.build_read_opts(self.__parse_read_opts(*args, **kwargs))

        it = ValuesIterator(self)
        it.set_prefix(opts, prefix)

        with nogil:
            it.ptr = self.db.NewIterator(opts)
        return it

    def iteritems(self, prefix=None, *args, **kwargs):
        cdef options.ReadOptions opts
        cdef ItemsIterator it

        opts = self.build_read_opts(self.__parse_read_opts(*args, **kwargs))

        it = ItemsIterator(self)
        it.set_prefix(opts, prefix)

        with nogil:
            it.ptr = self.db.NewIterator(opts)
        return it

    def snapshot(self):
        return Snapshot(self)

    def get_property(self, prop):
        cdef string value
        cdef Slice c_prop = bytes_to_slice(prop)
        cdef cpp_bool ret = False

        with nogil:
            ret = self.db.GetProperty(c_prop, cython.address(value))

        if ret:
            return string_to_bytes(value)
        else:
            return None

    def get_live_files_metadata(self):
        cdef vector[db.LiveFileMetaData] metadata

        with nogil:
            self.db.GetLiveFilesMetaData(cython.address(metadata))

        ret = []
        for ob in metadata:
            t = {}
            t['name'] = string_to_path(ob.name)
            t['level'] = ob.level
            t['size'] = ob.size
            t['smallestkey'] = string_to_bytes(ob.smallestkey)
            t['largestkey'] = string_to_bytes(ob.largestkey)
            t['smallest_seqno'] = ob.smallest_seqno
            t['largest_seqno'] = ob.largest_seqno

            ret.append(t)

        return ret

    @staticmethod
    def __parse_read_opts(
        verify_checksums=False,
        fill_cache=True,
        prefix_seek=False,
        snapshot=None,
        read_tier="all"):

        # TODO: Is this really effiencet ?
        return locals()

    cdef options.ReadOptions build_read_opts(self, dict py_opts):
        cdef options.ReadOptions opts
        opts.verify_checksums = py_opts['verify_checksums']
        opts.fill_cache = py_opts['fill_cache']
        opts.prefix_seek = py_opts['prefix_seek']
        if py_opts['snapshot'] is not None:
            opts.snapshot = (<Snapshot?>(py_opts['snapshot'])).ptr

        if py_opts['read_tier'] == "all":
            opts.read_tier = options.kReadAllTier
        elif py_opts['read_tier'] == 'cache':
            opts.read_tier = options.kBlockCacheTier
        else:
            raise ValueError("Invalid read_tier")

        return opts

    property options:
        def __get__(self):
            return self.opts

@cython.no_gc_clear
@cython.internal
cdef class Snapshot(object):
    cdef const snapshot.Snapshot* ptr
    cdef DB db

    def __cinit__(self, DB db):
        self.db = db
        self.ptr = NULL
        with nogil:
            self.ptr = db.db.GetSnapshot()

    def __dealloc__(self):
        if not self.ptr == NULL:
            with nogil:
                self.db.db.ReleaseSnapshot(self.ptr)


@cython.internal
cdef class BaseIterator(object):
    cdef iterator.Iterator* ptr
    cdef DB db
    # To keep a reference to the prefix
    cdef object prefix
    cdef Slice c_prefix

    def __cinit__(self, DB db):
        self.db = db
        self.ptr = NULL

    def __dealloc__(self):
        if not self.ptr == NULL:
            del self.ptr

    def __iter__(self):
        return self

    def __next__(self):
        if not self.ptr.Valid():
            raise StopIteration()

        cdef object ret = self.get_ob()
        with nogil:
            self.ptr.Next()
        check_status(self.ptr.status())
        return ret

    def __reversed__(self):
        return ReversedIterator(self)

    cdef set_prefix(self, options.ReadOptions& opts, object prefix=None):
        if prefix is None:
            return

        self.c_prefix = bytes_to_slice(prefix)
        self.prefix = prefix
        opts.prefix = cython.address(self.c_prefix)

    cpdef seek_to_first(self):
        with nogil:
            self.ptr.SeekToFirst()
        check_status(self.ptr.status())

    cpdef seek_to_last(self):
        with nogil:
            self.ptr.SeekToLast()
        check_status(self.ptr.status())

    cpdef seek(self, key):
        cdef Slice c_key = bytes_to_slice(key)
        with nogil:
            self.ptr.Seek(c_key)
        check_status(self.ptr.status())

    cdef object get_ob(self):
        return None

@cython.internal
cdef class KeysIterator(BaseIterator):
    cdef object get_ob(self):
        cdef Slice c_key
        with nogil:
            c_key = self.ptr.key()
        check_status(self.ptr.status())
        return slice_to_bytes(c_key)

@cython.internal
cdef class ValuesIterator(BaseIterator):
    cdef object get_ob(self):
        cdef Slice c_value
        with nogil:
            c_value = self.ptr.value()
        check_status(self.ptr.status())
        return slice_to_bytes(c_value)

@cython.internal
cdef class ItemsIterator(BaseIterator):
    cdef object get_ob(self):
        cdef Slice c_key
        cdef Slice c_value
        with nogil:
            c_key = self.ptr.key()
            c_value = self.ptr.value()
        check_status(self.ptr.status())
        return (slice_to_bytes(c_key), slice_to_bytes(c_value))

@cython.internal
cdef class ReversedIterator(object):
    cdef BaseIterator it

    def __cinit__(self, BaseIterator it):
        self.it = it

    def seek_to_first(self):
        self.it.seek_to_first()

    def seek_to_last(self):
        self.it.seek_to_last()

    def seek(self, key):
        self.it.seek(key)

    def __iter__(self):
        return self

    def __reversed__(self):
        return self.it

    def __next__(self):
        if not self.it.ptr.Valid():
            raise StopIteration()

        cdef object ret = self.it.get_ob()
        with nogil:
            self.it.ptr.Prev()
        check_status(self.it.ptr.status())
        return ret
