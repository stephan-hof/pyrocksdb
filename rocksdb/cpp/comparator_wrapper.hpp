#include "rocksdb/comparator.h"
#include "rocksdb/env.h"
#include <stdexcept>

using std::string;
using rocksdb::Comparator;
using rocksdb::Slice;
using rocksdb::Logger;

namespace py_rocks {
    class ComparatorWrapper: public Comparator {
        public:
            typedef int (*compare_func)(
                void*,
                Logger*,
                string&,
                const Slice&,
                const Slice&);

            ComparatorWrapper(
                string name,
                void* compare_context,
                compare_func compare_callback):
                    name(name),
                    compare_context(compare_context),
                    compare_callback(compare_callback)
            {}

            virtual int Compare(const Slice& a, const Slice& b) const {
                string error_msg;
                int val;

                val = this->compare_callback(
                    this->compare_context,
                    this->info_log.get(),
                    error_msg,
                    a,
                    b);

                if (error_msg.size()) {
                    throw std::runtime_error(error_msg.c_str());
                }
                return val;
            }

            virtual const char* Name() const {
                return this->name.c_str();
            }

            virtual void FindShortestSeparator(string*, const Slice&) const {}
            virtual void FindShortSuccessor(string*) const {}

            void set_info_log(std::shared_ptr<Logger> info_log) {
                this->info_log = info_log;
            }

        private:
            string name;
            void* compare_context;
            compare_func compare_callback;
            std::shared_ptr<Logger> info_log;
    };
}
