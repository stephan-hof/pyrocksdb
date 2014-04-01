#include "rocksdb/filter_policy.h"
#include "rocksdb/env.h"
#include <stdexcept>

using std::string;
using rocksdb::FilterPolicy;
using rocksdb::Slice;
using rocksdb::Logger;

namespace py_rocks {
    class FilterPolicyWrapper: public FilterPolicy {
        public:
            typedef void (*create_filter_func)(
                void* ctx,
                Logger*,
                string&,
                const Slice* keys,
                int n,
                string* dst);

            typedef bool (*key_may_match_func)(
                void* ctx,
                Logger*,
                string&,
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

            virtual void
            CreateFilter(const Slice* keys, int n, std::string* dst) const {
                string error_msg;

                this->create_filter_callback(
                    this->ctx,
                    this->info_log.get(),
                    error_msg,
                    keys,
                    n,
                    dst);

                if (error_msg.size()) {
                    throw std::runtime_error(error_msg.c_str());
                }
            }

            virtual bool
            KeyMayMatch(const Slice& key, const Slice& filter) const {
                string error_msg;
                bool val;

                val = this->key_may_match_callback(
                    this->ctx,
                    this->info_log.get(),
                    error_msg,
                    key,
                    filter);

                if (error_msg.size()) {
                    throw std::runtime_error(error_msg.c_str());
                }
                return val;
            }

            virtual const char* Name() const {
                return this->name.c_str();
            }

            void set_info_log(std::shared_ptr<Logger> info_log) {
                this->info_log = info_log;
            }

        private:
            string name;
            void* ctx;
            create_filter_func create_filter_callback;
            key_may_match_func key_may_match_callback;
            std::shared_ptr<Logger> info_log;
    };
}
