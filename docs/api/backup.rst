Backup and Restore
******************

BackupEngine
============

.. py:class:: rocksdb.BackupEngine

    .. py:method:: __init__(backup_dir)

        Creates a object to manage backup of a single database.

        :param unicode backup_dir: Where to keep the backup files.
                                   Has to be different than db.db_name.
                                   For example db.db_name + '/backups'.

    .. py:method:: create_backup(db, flush_before_backup=False)

        Triggers the creation of a backup.

        :param db: Database object to backup.
        :type db: :py:class:`rocksdb.DB`

        :param bool flush_before_backup: If ``True`` the current memtable is flushed.

    .. py:method:: restore_backup(backup_id, db_dir, wal_dir)

        Restores the backup from the given id.

        :param int backup_id: id of the backup to restore.
        :param unicode db_dir: Target directory to restore backup.
        :param unicode wal_dir: Target directory to restore backuped WAL files.

    .. py:method:: restore_latest_backup(db_dir, wal_dir)

        Restores the latest backup.

        :param unicode db_dir: see :py:meth:`restore_backup`
        :param unicode wal_dir: see :py:meth:`restore_backup`

    .. py:method:: stop_backup()

        Can be called from another thread to stop the current backup process.

    .. py:method:: purge_old_backups(num_backups_to_keep)

        Deletes all backups (oldest first) until "num_backups_to_keep" are left.

        :param int num_backups_to_keep: Number of backupfiles to keep.

    .. py:method:: delete_backup(backup_id)

        :param int backup_id: Delete the backup with the given id.

    .. py:method:: get_backup_info()

        Returns information about all backups.

        It returns a list of dict's where each dict as the following keys.

        ``backup_id``
            (int): id of this backup.

        ``timestamp``
            (int): Seconds since epoch, when the backup was created.

        ``size``
            (int): Size in bytes of the backup.
