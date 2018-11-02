#pragma once

#include <vector>
#include "rocksdb/write_batch.h"

namespace py_rocks {

class RecordItemsHandler: public rocksdb::WriteBatch::Handler {
    public:
        enum Optype {PutRecord, MergeRecord, DeleteRecord};

        class BatchItem {
            public:
                BatchItem(
                    const Optype& op,
                    uint32_t column_family_id,
                    const rocksdb::Slice& key,
                    const rocksdb::Slice& value):
                        op(op),
                        column_family_id(column_family_id),
                        key(key),
                        value(value)
                {}

            const Optype op;
            uint32_t column_family_id;
            const rocksdb::Slice key;
            const rocksdb::Slice value;
        };

        typedef std::vector<BatchItem> BatchItems;

    public:
        /* Items is filled during iteration. */
        RecordItemsHandler(BatchItems* items): items(items) {}

        virtual rocksdb::Status PutCF(
          uint32_t column_family_id, const Slice& key, const Slice& value) {
            this->items->emplace_back(PutRecord, column_family_id, key, value);
            return rocksdb::Status::OK();
        }

        virtual rocksdb::Status MergeCF(
          uint32_t column_family_id, const Slice& key, const Slice& value) {
            this->items->emplace_back(MergeRecord, column_family_id, key, value);
            return rocksdb::Status::OK();
        }

        virtual rocksdb::Status DeleteCF(
          uint32_t column_family_id, const Slice& key) {
            this->items->emplace_back(DeleteRecord, column_family_id, key, rocksdb::Slice());
            return rocksdb::Status::OK();
        }

    private:
        BatchItems* items;
};

rocksdb::Status
get_batch_items(const rocksdb::WriteBatch* batch, RecordItemsHandler::BatchItems* items) {
    RecordItemsHandler handler(items);
    return batch->Iterate(&handler);
}

}
