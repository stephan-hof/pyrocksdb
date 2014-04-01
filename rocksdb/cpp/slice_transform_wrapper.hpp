#include <string>
#include "rocksdb/slice_transform.h"
#include "rocksdb/env.h"
#include <stdexcept>

using std::string;
using rocksdb::SliceTransform;
using rocksdb::Slice;
using rocksdb::Logger;

namespace py_rocks {
    class SliceTransformWrapper: public SliceTransform {
        public:
            typedef Slice (*transform_func)(
                void*,
                Logger*,
                string&,
                const Slice&);

            typedef bool (*in_domain_func)(
                void*,
                Logger*,
                string&,
                const Slice&);

            typedef bool (*in_range_func)(
                void*,
                Logger*,
                string&,
                const Slice&);

            SliceTransformWrapper(
                string name,
                void* ctx,
                transform_func transfrom_callback,
                in_domain_func in_domain_callback,
                in_range_func in_range_callback):
                    name(name),
                    ctx(ctx),
                    transfrom_callback(transfrom_callback),
                    in_domain_callback(in_domain_callback),
                    in_range_callback(in_range_callback)
            {}

            virtual const char* Name() const {
                return this->name.c_str();
            }

            virtual Slice Transform(const Slice& src) const {
                string error_msg;
                Slice val;

                val = this->transfrom_callback(
                    this->ctx,
                    this->info_log.get(),
                    error_msg,
                    src);

                if (error_msg.size()) {
                    throw std::runtime_error(error_msg.c_str());
                }
                return val;
            }

            virtual bool InDomain(const Slice& src) const {
                string error_msg;
                bool val;

                val = this->in_domain_callback(
                    this->ctx,
                    this->info_log.get(),
                    error_msg,
                    src);

                if (error_msg.size()) {
                    throw std::runtime_error(error_msg.c_str());
                }
                return val;
            }

            virtual bool InRange(const Slice& dst) const {
                string error_msg;
                bool val;

                val = this->in_range_callback(
                    this->ctx,
                    this->info_log.get(),
                    error_msg,
                    dst);

                if (error_msg.size()) {
                    throw std::runtime_error(error_msg.c_str());
                }
                return val;
            }

            void set_info_log(std::shared_ptr<Logger> info_log) {
                this->info_log = info_log;
            }

        private:
            string name;
            void* ctx;
            transform_func transfrom_callback;
            in_domain_func in_domain_callback;
            in_range_func in_range_callback;
            std::shared_ptr<Logger> info_log;
    };
}
