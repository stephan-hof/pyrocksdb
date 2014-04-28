#include "rocksdb/memtablerep.h"

using rocksdb::MemTableRepFactory;
using rocksdb::VectorRepFactory;
using rocksdb::SkipListFactory;

namespace py_rocks {
    MemTableRepFactory* NewVectorRepFactory(size_t count = 0) {
        return new VectorRepFactory(count);
    }

    MemTableRepFactory* NewSkipListFactory() {
        return new SkipListFactory();
    }
}
