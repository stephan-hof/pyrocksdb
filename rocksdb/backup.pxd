from libcpp cimport bool as cpp_bool
from libcpp.string cimport string
from libcpp.vector cimport vector
from libc.stdint cimport uint32_t
from libc.stdint cimport int64_t
from libc.stdint cimport uint64_t

from status cimport Status
from db cimport DB
from env cimport Env

cdef extern from "rocksdb/utilities/backupable_db.h" namespace "rocksdb":
    ctypedef uint32_t BackupID

    cdef cppclass BackupableDBOptions:
        BackupableDBOptions(const string& backup_dir)

    cdef struct BackupInfo:
        BackupID backup_id
        int64_t timestamp
        uint64_t size

    cdef cppclass BackupEngine:
        Status CreateNewBackup(DB*, cpp_bool) nogil except+
        Status PurgeOldBackups(uint32_t) nogil except+
        Status DeleteBackup(BackupID) nogil except+
        void StopBackup() nogil except+
        void GetBackupInfo(vector[BackupInfo]*) nogil except+
        Status RestoreDBFromBackup(BackupID, string&, string&) nogil except+
        Status RestoreDBFromLatestBackup(string&, string&) nogil except+

    cdef Status BackupEngine_Open "rocksdb::BackupEngine::Open"(
            Env*,
            BackupableDBOptions&,
            BackupEngine**)
