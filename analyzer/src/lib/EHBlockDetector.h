#pragma once

#include "Analyzer.h"
#include "Common.h"
#include "PathSpan.h"
#include <shared_mutex>


enum class OperationType : unsigned char {
    Call,
    Return,
    Unreachable,
    CondBr,
    Switch,
    Store,
};

struct Path {
    vector<const BasicBlock*> blocks;
    const AbstractCondition* reason;
};

struct SummarySignature {
    static constexpr uint64_t GUARD_BITS = 0x8080808080808080ULL;
    static constexpr uint64_t MAX_COUNT = 0x7F; // One bit per byte is reserved as a guard bit, see canBeSubsequenceOf

    uint64_t countsPerType {};
    // Can only be a subset if the call targets appear in the larger one, so construct a bloom filter.
    uint64_t callTargetsBloom {};

    inline void add(OperationType type) {
        auto shift = static_cast<unsigned int>(type) * 8;
        // NOTE: saturating is fine: it can only make the check below give up, but never incorrectly reject.
        if (((countsPerType >> shift) & 0xFF) < MAX_COUNT)
            countsPerType += UINT64_C(1) << shift;
    }

    inline void addCallTargets(const FlatFuncSet* canonicalCallTargets) {
        auto mixed = reinterpret_cast<uintptr_t>(canonicalCallTargets) >> 4;
        callTargetsBloom |= UINT64_C(1) << ((mixed * UINT64_C(0x9E3779B97F4A7C15)) >> 58);
    }

    /// Returns false only if this summary certainly isn't a subsequence of the other one.
    [[nodiscard]] inline bool canBeSubsequenceOf(const SummarySignature& other) const {
        if ((callTargetsBloom & ~other.callTargetsBloom) != 0)
            return false;
        // Per byte: (other + 128) - this. Because both counts fit in 7 bits there is no borrow into the next byte.
        return (~((other.countsPerType | GUARD_BITS) - countsPerType) & GUARD_BITS) == 0;
    }
};

static_assert(static_cast<unsigned int>(OperationType::Store) < 8, "SummarySignature has room for 8 operation types");

struct Operation {
    OperationType type;
    union {
        ICmpInst::Predicate predicate; // Here for struct packing
    };
    union {
        const FlatFuncSet *callTargets;
        const Value *value;
        struct {
            const Value* resolvedValue, *unresolvedValue;
        } returnData;
        struct {
            const Value* value;
            const Instruction* instruction;
            const FlatFuncSet *callTargets;
        } condBrData;
        struct {
            const Value* value;
            const Instruction* instruction;
            AAResults *aa;
        } storeData;
    };

    void resolvePathSensitiveValues(const vector<const BasicBlock*>& blocks);

    bool operator==(const Operation& other) const;
};

struct Summary {
    vector<Operation> ops;
    const BasicBlock* originalBlockIndex1;
    // Only valid after computeSignature(), which must be called once the operations are final.
    SummarySignature signature;

    void resolvePathSensitiveValues(const vector<const BasicBlock*>& blocks);

    void computeSignature();

    void merge(const Summary& summary) {
        ops.reserve(ops.size() + summary.ops.size());
        ops.insert(ops.end(), summary.ops.begin(), summary.ops.end());
    }

    [[nodiscard]] unsigned int numberOfCondBrs() const;

    void dump() const;
};

struct SafetyCheckData {
    unsigned short lcs {};
    unsigned short pathLength {numeric_limits<unsigned short>::max()};
    unsigned short sumOfCondBrCount {numeric_limits<unsigned short>::max()};
    const BasicBlock* errorHandlingBlock {};
};

class EHBlockDetectorPass : public IterativeModulePass {

public:

    explicit EHBlockDetectorPass(GlobalContext *Ctx_)
            : IterativeModulePass(Ctx_, "EHBlockDetector") {
    }
    bool doInitialization(llvm::Module *) override;
    bool doFinalization(llvm::Module *) override;
    void doModulePass(llvm::Module *) override;
    void associationAnalysisForErrorHandlers();
    void storeData();
    inline void nextStage() { stage++; }
    void propagateCheckedErrors();
    void learnErrorsFromErrorBlocksForSelf();

    static void collectPaths(const BasicBlock* currentBlock, vector<Path*>& allPaths, Path* myCurrentPath, set<const BasicBlock*>& basicBlocksOfNonInterest);
    static optional<bool> determineErrorBranchOfCallWithCompare(ICmpInst::Predicate predicate, unsigned int returnValueIndex, int rhs, const CallInst* checkedCall);

private:
    void stage0(llvm::Module *);
    void stage1(llvm::Module *);
    void processSafetyCheckMapping(const map<const AbstractComparison*, SafetyCheckData>& mapping);

    Summary summarizeBlock(const BasicBlock* currentBlock) const;
    void identifyPotentialSanityChecks(const Function& function);
    static void collectPathsAux(const BasicBlock* currentBlock, vector<Path*>& allPaths, Path* myCurrentPath, set<const BasicBlock*>& visited, set<const BasicBlock*>& basicBlocksOfNonInterest, const BasicBlock* lastBr);
    const BasicBlock* determineSuccessorOfAbstractComparisonWhichHandlesErrors(const AbstractComparison* abstractComparison) const;
    const BasicBlock* determineSuccessorOfAbstractComparisonWhichHandlesErrors(const BasicBlock* abstractComparisonBlock) const;
    optional<Interval> addForSpanAndReturnInstruction(PathSpan pathSpan, const ReturnInst* returnInstruction);

    map<const Function*, InErrorNotInErrorPair> functionToInErrorNotInErrorPair;
    FunctionToIntervalCounts functionToIntervalCounts;
    map<const Module*, map<const AbstractComparison*, SafetyCheckData>> moduleToSafetyChecks;
    shared_mutex conditionalToActionLock;
    map<const AbstractComparison*, pair<const Value*, unsigned int>> conditionalToAction;
    set<const Function*> associatedErrorHandlerFunctions;
    int stage = 0;
};
