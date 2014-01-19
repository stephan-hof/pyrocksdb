#include <string>
#include "rocksdb/slice_transform.h"

using std::string;
using rocksdb::SliceTransform;
using rocksdb::Slice;

namespace py_rocks {
    class SliceTransformWrapper: public SliceTransform {
        public:
            typedef Slice (*transform_func)(void*, const Slice&);
            typedef bool (*in_domain_func)(void*, const Slice&);
            typedef bool (*in_range_func)(void*, const Slice&);

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

            const char* Name() const {
                return this->name.c_str();
            }

            Slice Transform(const Slice& src) const {
                return this->transfrom_callback(this->ctx, src);
            }

            bool InDomain(const Slice& src) const {
                return this->in_domain_callback(this->ctx, src);
            }

            bool InRange(const Slice& dst) const {
                return this->in_range_callback(this->ctx, dst);
            }

        private:
            string name;
            void* ctx;
            transform_func transfrom_callback;
            in_domain_func in_domain_callback;
            in_range_func in_range_callback;
    };
}
