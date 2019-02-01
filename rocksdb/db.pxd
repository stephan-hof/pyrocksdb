cimport options
from libc.stdint cimport uint64_t, uint32_t
from status cimport Status
from libcpp cimport bool as cpp_bool
from libcpp.string cimport string
from libcpp.vector cimport vector
from slice_ cimport Slice
from snapshot cimport Snapshot
from iterator cimport Iterator

cdef extern from "rocksdb/write_batch.h" namespace "rocksdb":
    cdef cppclass WriteBatch:
        WriteBatch() nogil except+
        WriteBatch(string) nogil except+
        void Put(const Slice&, const Slice&) nogil except+
        void Put(ColumnFamilyHandle*, const Slice&, const Slice&) nogil except+
        void Merge(const Slice&, const Slice&) nogil except+
        void Merge(ColumnFamilyHandle*, const Slice&, const Slice&) nogil except+
        void Delete(const Slice&) nogil except+
        void Delete(ColumnFamilyHandle*, const Slice&) nogil except+
        void PutLogData(const Slice&) nogil except+
        void Clear() nogil except+
        const string& Data() nogil except+
        int Count() nogil except+

cdef extern from "cpp/write_batch_iter_helper.hpp" namespace "py_rocks":
    cdef enum BatchItemOp "RecordItemsHandler::Optype":
        BatchItemOpPut "py_rocks::RecordItemsHandler::Optype::PutRecord"
        BatchItemOpMerge "py_rocks::RecordItemsHandler::Optype::MergeRecord"
        BatchItemOpDelte "py_rocks::RecordItemsHandler::Optype::DeleteRecord"

    cdef cppclass BatchItem "py_rocks::RecordItemsHandler::BatchItem":
        BatchItemOp op
        uint32_t column_family_id
        Slice key
        Slice value

    Status get_batch_items(WriteBatch* batch, vector[BatchItem]* items)


cdef extern from "rocksdb/db.h" namespace "rocksdb":
    ctypedef uint64_t SequenceNumber
    string kDefaultColumnFamilyName

    cdef struct LiveFileMetaData:
        string name
        int level
        uint64_t size
        string smallestkey
        string largestkey
        SequenceNumber smallest_seqno
        SequenceNumber largest_seqno

    cdef cppclass Range:
        Range(const Slice&, const Slice&)

    cdef cppclass DB:
        Status Put(
            const options.WriteOptions&,
            ColumnFamilyHandle*,
            const Slice&,
            const Slice&) nogil except+

        Status Delete(
            const options.WriteOptions&,
            ColumnFamilyHandle*,
            const Slice&) nogil except+

        Status Merge(
            const options.WriteOptions&,
            ColumnFamilyHandle*,
            const Slice&,
            const Slice&) nogil except+

        Status Write(
            const options.WriteOptions&,
            WriteBatch*) nogil except+

        Status Get(
            const options.ReadOptions&,
            ColumnFamilyHandle*,
            const Slice&,
            string*) nogil except+

        vector[Status] MultiGet(
            const options.ReadOptions&,
            const vector[ColumnFamilyHandle*]&,
            const vector[Slice]&,
            vector[string]*) nogil except+

        cpp_bool KeyMayExist(
            const options.ReadOptions&,
            ColumnFamilyHandle*,
            Slice&,
            string*,
            cpp_bool*) nogil except+

        cpp_bool KeyMayExist(
            const options.ReadOptions&,
            ColumnFamilyHandle*,
            Slice&,
            string*) nogil except+

        Iterator* NewIterator(
            const options.ReadOptions&,
            ColumnFamilyHandle*) nogil except+

        void NewIterators(
            const options.ReadOptions&,
            vector[ColumnFamilyHandle*]&,
            vector[Iterator*]*) nogil except+

        const Snapshot* GetSnapshot() nogil except+

        void ReleaseSnapshot(const Snapshot*) nogil except+

        cpp_bool GetProperty(
            ColumnFamilyHandle*,
            const Slice&,
            string*) nogil except+

        void GetApproximateSizes(
            ColumnFamilyHandle*,
            const Range*
            int,
            uint64_t*) nogil except+

        Status CompactRange(
            const options.CompactRangeOptions&,
            ColumnFamilyHandle*,
            const Slice*,
            const Slice*) nogil except+

        Status CreateColumnFamily(
            const options.ColumnFamilyOptions&,
            const string&,
            ColumnFamilyHandle**) nogil except+

        Status DropColumnFamily(
            ColumnFamilyHandle*) nogil except+

        int NumberLevels(ColumnFamilyHandle*) nogil except+
        int MaxMemCompactionLevel(ColumnFamilyHandle*) nogil except+
        int Level0StopWriteTrigger(ColumnFamilyHandle*) nogil except+
        const string& GetName() nogil except+
        const options.Options& GetOptions(ColumnFamilyHandle*) nogil except+
        Status Flush(const options.FlushOptions&, ColumnFamilyHandle*) nogil except+
        Status DisableFileDeletions() nogil except+
        Status EnableFileDeletions() nogil except+

        # TODO: Status GetSortedWalFiles(VectorLogPtr& files)
        # TODO: SequenceNumber GetLatestSequenceNumber()
        # TODO: Status GetUpdatesSince(
                  # SequenceNumber seq_number,
                  # unique_ptr[TransactionLogIterator]*)

        Status DeleteFile(string) nogil except+
        void GetLiveFilesMetaData(vector[LiveFileMetaData]*) nogil except+
        ColumnFamilyHandle* DefaultColumnFamily()


    cdef Status DB_Open "rocksdb::DB::Open"(
        const options.Options&,
        const string&,
        DB**) nogil except+

    cdef Status DB_Open_ColumnFamilies "rocksdb::DB::Open"(
        const options.Options&,
        const string&,
        const vector[ColumnFamilyDescriptor]&,
        vector[ColumnFamilyHandle*]*,
        DB**) nogil except+

    cdef Status DB_OpenForReadOnly "rocksdb::DB::OpenForReadOnly"(
        const options.Options&,
        const string&,
        DB**,
        cpp_bool) nogil except+

    cdef Status DB_OpenForReadOnly_ColumnFamilies "rocksdb::DB::OpenForReadOnly"(
        const options.Options&,
        const string&,
        const vector[ColumnFamilyDescriptor]&,
        vector[ColumnFamilyHandle*]*,
        DB**,
        cpp_bool) nogil except+

    cdef Status RepairDB(const string& dbname, const options.Options&)

    cdef Status ListColumnFamilies "rocksdb::DB::ListColumnFamilies" (
        const options.Options&,
        const string&,
        vector[string]*) nogil except+

    cdef cppclass ColumnFamilyHandle:
        const string& GetName() nogil except+
        int GetID() nogil except+

    cdef cppclass ColumnFamilyDescriptor:
        ColumnFamilyDescriptor() nogil except+
        ColumnFamilyDescriptor(
	    const string&,
            const options.ColumnFamilyOptions&) nogil except+
        string name
        options.ColumnFamilyOptions options
