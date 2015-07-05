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
                    const rocksdb::Slice& key,
                    const rocksdb::Slice& value):
                        op(op),
                        key(key),
                        value(value)
                {}

            const Optype op;
            const rocksdb::Slice key;
            const rocksdb::Slice value;
        };

        typedef std::vector<BatchItem> BatchItems;

    public:
        /* Items is filled during iteration. */
        RecordItemsHandler(BatchItems* items): items(items) {}

        void Put(const Slice& key, const Slice& value) {
            this->items->emplace_back(PutRecord, key, value);
        }

        void Merge(const Slice& key, const Slice& value) {
            this->items->emplace_back(MergeRecord, key, value);
        }

        virtual void Delete(const Slice& key) {
            this->items->emplace_back(DeleteRecord, key, rocksdb::Slice());
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
