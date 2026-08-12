#include <llvm/Demangle/Demangle.h>
#include "FunctionErrorReturnIntervals.h"


void FunctionErrorReturnIntervals::mergeDestructivelyForOther(FunctionErrorReturnIntervals& other) {
    for (auto& [function, interval] : other.intervals) {
        if (auto it = intervals.find(function); it != intervals.end()) {
            it->second.unionInPlace(interval);
        } else {
            intervals.emplace(function, std::move(interval));
        }
    }
}

void FunctionErrorReturnIntervals::dump() const {
    std::vector<std::pair<decltype(intervals)::key_type, std::reference_wrapper<const decltype(intervals)::mapped_type>>> sorted;
    sorted.reserve(intervals.size());

    auto intervalCount = intervals.size();
    for (const auto& [pair, interval] : intervals) {
        auto function = pair.first;
        if (function->getParent()->getName().contains("/libc.so.bc"))
            --intervalCount;
        sorted.emplace_back(pair, std::cref(interval));
    }

    std::sort(sorted.begin(), sorted.end(), [](const auto& a, const auto& b) {
        return a.first.first->getName().str() < b.first.first->getName().str();
    });

    LOG(LOG_INFO, "Function error return intervals (" << intervalCount << ", pre-libc-pruning " << intervals.size() << "):\n");
    for (const auto& [pair, intervalRef] : sorted) {
        auto function = pair.first;
        const auto& interval = intervalRef.get();
#if 1
        if (function->getParent()->getName().contains("/libc.so.bc"))
            continue;
#endif
        LOG(LOG_INFO, "Function: " << (function ? demangle(function->getName().str()) : "?") << " {return index " << pair.second << "}\n  ");
        interval.dump();
    }
}
