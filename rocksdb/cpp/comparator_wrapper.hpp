#include "rocksdb/comparator.h"

using std::string;
using rocksdb::Comparator;
using rocksdb::Slice;

namespace py_rocks {
    class ComparatorWrapper: public Comparator {
        public:
            typedef int (*compare_func)(void*, const Slice&, const Slice&);

            ComparatorWrapper(
                string name,
                void* compare_context,
                compare_func compare_callback):
                    name(name),
                    compare_context(compare_context),
                    compare_callback(compare_callback)
            {}

            int Compare(const Slice& a, const Slice& b) const {
                return this->compare_callback(this->compare_context, a, b);
            }

            const char* Name() const {
                return this->name.c_str();
            }

            void FindShortestSeparator(string* start, const Slice& limit) const {}
            void FindShortSuccessor(string* key) const {}

        private:
            string name;
            void* compare_context;
            compare_func compare_callback;
    };
}
