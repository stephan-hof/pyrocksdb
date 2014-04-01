#include "rocksdb/merge_operator.h"

using std::string;
using std::deque;
using rocksdb::Slice;
using rocksdb::Logger;
using rocksdb::MergeOperator;
using rocksdb::AssociativeMergeOperator;

namespace py_rocks {
    class AssociativeMergeOperatorWrapper: public AssociativeMergeOperator {
        public:
            typedef bool (*merge_func)(
                    void*, 
                    const Slice& key,
                    const Slice* existing_value,
                    const Slice& value,
                    std::string* new_value,
                    Logger* logger);


            AssociativeMergeOperatorWrapper(
                string name,
                void* merge_context,
                merge_func merge_callback):
                    name(name),
                    merge_context(merge_context),
                    merge_callback(merge_callback)
            {}

            virtual bool Merge(
                const Slice& key,
                const Slice* existing_value,
                const Slice& value,
                std::string* new_value,
                Logger* logger) const 
            {
                return this->merge_callback(
                    this->merge_context,
                    key,
                    existing_value,
                    value,
                    new_value,
                    logger);
            }

            virtual const char* Name() const {
                return this->name.c_str();
            }

        private:
            string name;
            void* merge_context;
            merge_func merge_callback;
    };

    class MergeOperatorWrapper: public MergeOperator {
        public:
            typedef bool (*full_merge_func)(
                void* ctx,
                const Slice& key,
                const Slice* existing_value,
                const deque<string>& operand_list,
                string* new_value,
                Logger* logger);

            typedef bool (*partial_merge_func)(
                void* ctx,
                const Slice& key,
                const Slice& left_op,
                const Slice& right_op,
                string* new_value,
                Logger* logger);

            MergeOperatorWrapper(
                string name,
                void* full_merge_context,
                void* partial_merge_context,
                full_merge_func full_merge_callback,
                partial_merge_func partial_merge_callback):
                    name(name),
                    full_merge_context(full_merge_context),
                    partial_merge_context(partial_merge_context),
                    full_merge_callback(full_merge_callback),
                    partial_merge_callback(partial_merge_callback)
            {}

            virtual bool FullMerge(
                const Slice& key,
                const Slice* existing_value,
                const deque<string>& operand_list,
                string* new_value,
                Logger* logger) const 
            {
                return this->full_merge_callback(
                    this->full_merge_context,
                    key,
                    existing_value,
                    operand_list,
                    new_value,
                    logger);
            }

            virtual bool PartialMerge (
                const Slice& key,
                const Slice& left_operand,
                const Slice& right_operand,
                string* new_value,
                Logger* logger) const
            {
                return this->partial_merge_callback(
                    this->partial_merge_context,
                    key,
                    left_operand,
                    right_operand,
                    new_value,
                    logger);
            }
            
            virtual const char* Name() const {
                return this->name.c_str();
            }

        private:
            string name;
            void* full_merge_context;
            void* partial_merge_context;
            full_merge_func full_merge_callback;
            partial_merge_func partial_merge_callback;

        };
}
