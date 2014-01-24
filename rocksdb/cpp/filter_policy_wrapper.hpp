#include "rocksdb/filter_policy.h"

using std::string;
using rocksdb::FilterPolicy;
using rocksdb::Slice;

namespace py_rocks {
    class FilterPolicyWrapper: public FilterPolicy {
        public:
            typedef void (*create_filter_func)(
                void* ctx,
                const Slice* keys,
                int n,
                string* dst);

            typedef bool (*key_may_match_func)(
                void* ctx,
                const Slice& key,
                const Slice& filter);

            FilterPolicyWrapper(
                string name,
                void* ctx,
                create_filter_func create_filter_callback,
                key_may_match_func key_may_match_callback):
                    name(name),
                    ctx(ctx),
                    create_filter_callback(create_filter_callback),
                    key_may_match_callback(key_may_match_callback)
            {}

            void
            CreateFilter(const Slice* keys, int n, std::string* dst) const {
                this->create_filter_callback(
                    this->ctx,
                    keys,
                    n,
                    dst);
            }

            bool
            KeyMayMatch(const Slice& key, const Slice& filter) const {
                return this->key_may_match_callback(
                    this->ctx,
                    key,
                    filter);
            }

            const char* Name() const {
                return this->name.c_str();
            }

        private:
            string name;
            void* ctx;
            create_filter_func create_filter_callback;
            key_may_match_func key_may_match_callback;
    };
}
