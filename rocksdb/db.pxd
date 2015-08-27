cimport options
from libc.stdint cimport uint64_t
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
        void Merge(const Slice&, const Slice&) nogil except+
        void Delete(const Slice&) nogil except+
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
        Slice key
        Slice value

    Status get_batch_items(WriteBatch* batch, vector[BatchItem]* items)


cdef extern from "rocksdb/db.h" namespace "rocksdb":
    ctypedef uint64_t SequenceNumber

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
            const Slice&,
            const Slice&) nogil except+

        Status Delete(
            const options.WriteOptions&,
            const Slice&) nogil except+

        Status Merge(
            const options.WriteOptions&,
            const Slice&,
            const Slice&) nogil except+

        Status Write(
            const options.WriteOptions&,
            WriteBatch*) nogil except+

        Status Get(
            const options.ReadOptions&,
            const Slice&,
            string*) nogil except+

        vector[Status] MultiGet(
            const options.ReadOptions&,
            const vector[Slice]&,
            vector[string]*) nogil except+

        cpp_bool KeyMayExist(
            const options.ReadOptions&,
            Slice&,
            string*,
            cpp_bool*) nogil except+

        cpp_bool KeyMayExist(
            const options.ReadOptions&,
            Slice&,
            string*) nogil except+

        Iterator* NewIterator(
            const options.ReadOptions&) nogil except+

        const Snapshot* GetSnapshot() nogil except+

        void ReleaseSnapshot(const Snapshot*) nogil except+

        cpp_bool GetProperty(
            const Slice&,
            string*) nogil except+

        void GetApproximateSizes(
            const Range*
            int,
            uint64_t*) nogil except+

        Status CompactRange(
            const options.CompactRangeOptions&,
            const Slice*,
            const Slice*) nogil except+

        int NumberLevels() nogil except+
        int MaxMemCompactionLevel() nogil except+
        int Level0StopWriteTrigger() nogil except+
        const string& GetName() nogil except+
        const options.Options& GetOptions() nogil except+
        Status Flush(const options.FlushOptions&) nogil except+
        Status DisableFileDeletions() nogil except+
        Status EnableFileDeletions() nogil except+

        # TODO: Status GetSortedWalFiles(VectorLogPtr& files)
        # TODO: SequenceNumber GetLatestSequenceNumber()
        # TODO: Status GetUpdatesSince(
                  # SequenceNumber seq_number,
                  # unique_ptr[TransactionLogIterator]*)

        Status DeleteFile(string) nogil except+
        void GetLiveFilesMetaData(vector[LiveFileMetaData]*) nogil except+


    cdef Status DB_Open "rocksdb::DB::Open"(
        const options.Options&,
        const string&,
        DB**) nogil except+

    cdef Status DB_OpenForReadOnly "rocksdb::DB::OpenForReadOnly"(
        const options.Options&,
        const string&,
        DB**,
        cpp_bool) nogil except+

    cdef Status RepairDB(const string& dbname, const options.Options&)
