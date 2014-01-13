cimport options
from libc.stdint cimport uint64_t
from status cimport Status
from libcpp cimport bool as cpp_bool
from libcpp.string cimport string
from libcpp.vector cimport vector
from slice_ cimport Slice
from snapshot cimport Snapshot
from iterator cimport Iterator

# TODO: Move this to a separate .pxd file
cdef extern from "rocksdb/write_batch.h" namespace "rocksdb":
    cdef cppclass WriteBatch:
        WriteBatch() except +
        WriteBatch(string) except +
        void Put(const Slice&, const Slice&)
        void Merge(const Slice&, const Slice&)
        void Delete(const Slice&)
        void PutLogData(const Slice&)
        void Clear()
        string Data()
        int Count() const

cdef extern from "rocksdb/db.h" namespace "rocksdb":
    ctypedef uint64_t SequenceNumber

    cdef struct LiveFileMetaData:
        string name
        int level
        size_t size
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
            const Slice&)

        Status Delete(
            const options.WriteOptions&,
            const Slice&)

        Status Merge(
            const options.WriteOptions&,
            const Slice&,
            const Slice&)

        Status Write(
            const options.WriteOptions&,
            WriteBatch*)

        Status Get(
            const options.ReadOptions&,
            const Slice&,
            string*)

        vector[Status] MultiGet(
            const options.ReadOptions&,
            const vector[Slice]&,
            vector[string]*)

        cpp_bool KeyMayExist(
            const options.ReadOptions&,
            Slice&,
            string*,
            cpp_bool*)

        cpp_bool KeyMayExist(
            const options.ReadOptions&,
            Slice&,
            string*)

        Iterator* NewIterator(
            const options.ReadOptions&)

        const Snapshot* GetSnapshot()

        void ReleaseSnapshot(const Snapshot*)

        cpp_bool GetProperty(
            const Slice&,
            string*)

        void GetApproximateSizes(
            const Range*
            int,
            uint64_t*)

        void CompactRange(
            const Slice*,
            const Slice*,
            bool,
            int)

        int NumberLevels()
        int MaxMemCompactionLevel()
        int Level0StopWriteTrigger()
        const string& GetName() const
        Status Flush(const options.FlushOptions&)
        Status DisableFileDeletions()
        Status EnableFileDeletions()

        # TODO: Status GetSortedWalFiles(VectorLogPtr& files)
        # TODO: SequenceNumber GetLatestSequenceNumber()
        # TODO: Status GetUpdatesSince(
                  # SequenceNumber seq_number,
                  # unique_ptr[TransactionLogIterator]*)

        Status DeleteFile(string)
        void GetLiveFilesMetaData(vector[LiveFileMetaData]*)


    cdef Status DB_Open "rocksdb::DB::Open"(
        const options.Options&,
        const string&,
        DB**)

    cdef Status DB_OpenForReadOnly "rocksdb::DB::OpenForReadOnly"(
        const options.Options&,
        const string&,
        DB**,
        cpp_bool)
