#pragma once

#include <span>

namespace llvm {
    class BasicBlock;
}

using namespace llvm;

struct PathSpanIterator {
    explicit PathSpanIterator(span<const BasicBlock* const>::iterator it, bool isBackwardsPath)
            : it(it), isBackwardsPath(isBackwardsPath) {}

    PathSpanIterator& operator++() { // Prefix increment
        if (isBackwardsPath)
            --it;
        else
            ++it;
        return *this;
    }

    PathSpanIterator& operator--() { // Prefix decrement
        if (isBackwardsPath)
            ++it;
        else
            --it;
        return *this;
    }

    const BasicBlock* operator*() const {
        return *it;
    }

    const BasicBlock* operator->() const {
        return *it;
    }

    bool operator==(const PathSpanIterator& other) const {
        return it == other.it;
    }

    bool operator!=(const PathSpanIterator& other) const {
        return it != other.it;
    }

private:
    span<const BasicBlock* const>::iterator it;
    bool isBackwardsPath;
};

struct PathSpan {
    explicit PathSpan(span<const BasicBlock* const> blocks, bool isBackwardsPath) : blocks(blocks), isBackwardsPath(isBackwardsPath) {}

    [[nodiscard]] PathSpanIterator begin() const {
        if (isBackwardsPath)
            return PathSpanIterator{blocks.end() - 1, isBackwardsPath};
        else
            return PathSpanIterator{blocks.begin(), isBackwardsPath};
    }

    [[nodiscard]] PathSpanIterator end() const {
        if (isBackwardsPath)
            return PathSpanIterator{blocks.begin() - 1, isBackwardsPath};
        else
            return PathSpanIterator{blocks.end(), isBackwardsPath};
    }

    span<const BasicBlock* const> blocks;
    bool isBackwardsPath;
};
